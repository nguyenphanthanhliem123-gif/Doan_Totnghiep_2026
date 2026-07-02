import profileModel from "../models/ProfileModel.js";
import path from 'path';
import { fileURLToPath } from 'url';
import { execute } from "../config/db.js";
import ReportModel from "../models/reportModel.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export default class profileController{
    static async getAll(req,res){
        try{
            const users = await profileModel.getAll();

            return res.status(200).json({
                succeeded: true,
                users: users
            });
        }
        catch(error){
            return res.status(500).json({
                message: 'Lỗi server ' + error.message,
                succeeded: false,
            });
        }
    }
    static async getProfileByMaNguoiDung(req,res){
        try{
            const {Ma_nguoi_dung} = req.params;
            if(Ma_nguoi_dung < 1) return res.status(400).json({message: 'Mã người dùng không hợp lệ', succeeded: false});
            const result = await profileModel.getProfileByMaNguoiDung(Ma_nguoi_dung);
            if(!result) return res.status(404).json({message: 'Không tìm thấy người dùng này', succeeded: false});
            return res.status(200).json({user: result, succeeded: true});
        }
        catch(error){
            return res.status(500).json({
                succeeded: false,
                message: 'Lỗi server(profileController.getProfileByMaNguoiDung): ' +error.message
            });
        }
    }

    static async updateProfile(req,res){
        try{
            const {fullName, birthDay, gender, address, phone} = req.body;
            const userId = req.Ma_nguoi_dung;


            const result = await profileModel.updateProfile(fullName, birthDay, gender, address, phone, userId);

            if(result) return res.status(200).json({
                succeeded: true,
            });
        }
        catch(error){
            return res.status(500).json({
                succeeded: false,
                message: "Lỗi cập nhật hồ sơ người dùng(profileController.updateProfile): "+error.message
            });
        }
    }

    static async uploadAvatar(req, res) {
        try {
            const userID = req.Ma_nguoi_dung; // Lấy ID người dùng từ Token (Middleware auth)

            // 1. Kiểm tra xem người dùng có gửi file lên không
            if (!req.files || !req.files.avatar) {
                return res.status(400).json({ 
                    succeeded: false, 
                    message: "Không tìm thấy file. Hãy đảm bảo gửi file với key là 'avatar'." 
                });
            }

            const avatarFile = req.files.avatar;

            // 2. Kiểm tra định dạng (Chỉ cho phép ảnh)
            if (!avatarFile.mimetype.startsWith('image/')) {
                return res.status(400).json({ succeeded: false, message: "Vui lòng chỉ tải lên tệp hình ảnh!" });
            }

            // 3. Đổi tên file để tránh bị trùng lặp (Ví dụ: avatar_15_16892348.jpg)
            const ext = path.extname(avatarFile.name); 
            const uniqueFilename = `avatar_${userID}_${Date.now()}${ext}`;

            // 4. Lấy đường dẫn tuyệt đối tới thư mục 'uploads' ở gốc dự án
            // Lưu ý: Nếu file controller nằm ở /controllers, bạn dùng '../uploads' hoặc '../../uploads' để trỏ ra thư mục gốc.
            const uploadPath = path.join(__dirname, '../uploads', uniqueFilename); 

            // 5. Lưu file vào ổ cứng server bằng hàm .mv() có sẵn của express-fileupload
            await avatarFile.mv(uploadPath);

            // 6. Tạo đường link truy cập (URL) để lưu vào DB
            const host = req.get('host');
            const protocol = req.protocol;
            const imageUrl = `${protocol}://${host}/uploads/${uniqueFilename}`;

            console.log('=== userID'+ userID);
            console.log('=== FILE UPLOADS: ' + imageUrl);

            // 7. Cập nhật link ảnh vào Database
            const query = `UPDATE nguoi_dung SET Anh_dai_dien = ? WHERE Ma_nguoi_dung = ?`;
            await execute(query, [imageUrl, userID]);

            // Trả về kết quả thành công cho Flutter
            return res.status(200).json({
                succeeded: true,
                message: "Cập nhật ảnh đại diện thành công!",
                data: { Anh_dai_dien: imageUrl }
            });

        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    static async createReport(req,res) {
        try {
            const userId = req.Ma_nguoi_dung;
            const { reportedId, reportedType, reason } = req.body;

            if (!reportedId || !reason) {
                return res.status(400).json({ success: false, message: 'Vui lòng cung cấp đủ thông tin.' });
            }

            await ReportModel.createReport(userId, reportedId, reportedType, reason);

            return res.status(200).json({ success: true, message: 'Đã gửi báo cáo thành công' });
        }catch(error)
        {
            console.error('Lỗi khi gửi report:', error);
            return res.status(500).json({ success: false, message: 'Lỗi server', error: error.message });
        }
    }
}