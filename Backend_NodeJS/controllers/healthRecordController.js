import healthRecordModel from "../models/HealthRecordModel.js";
import { decrypt } from "../utils/cryptoUtil.js";

export default class healthRecordController{
    static async getAllHealthRecordByUserID(req,res){
        try{
            const userID = req.Ma_nguoi_dung;
            const healthRecords = await healthRecordModel.getAllHealthRecordByUserID(userID);

            const decryptedRows = healthRecords.map(row => {
                return{
                    ...row,
                    Nhom_mau: decrypt(row.Nhom_mau),
                    Di_ung: decrypt(row.Di_ung),
                    Benh_nen: decrypt(row.Benh_nen)
                };
            });

            return res.status(200).json({succeeded: true, healthRecords: decryptedRows});
        }catch(error){
            return res.status(500).json({succeeded: false, message: "Lỗi lấy tất cả hồ sơ sức khỏe của tài khoản: " + error.message});
        }
    }

    static async addRelativeProfile(req,res){
        try{
            const userID = req.Ma_nguoi_dung;
            const {tenNguoiThan, moiQuanHe, birthDay, gender, address, nhomMau, diUng, benhNen} = req.body;

            if(!tenNguoiThan || !moiQuanHe || !birthDay || !gender || !address) return res.status(400).json({
                succeeded: false,
                message: "Không được bỏ trống các thông tin họ tên, ngày sinh, địa chỉ"
            });



            const result = await healthRecordModel.addRelativeProfile(userID, tenNguoiThan, moiQuanHe, birthDay, gender, address, nhomMau ?? null, diUng ?? null, benhNen ?? null);

            if(!result) return res.status(500).json({succeeded: false, message: "Thêm hồ sơ sức khỏe thất bại: " + result});

            return res.status(200).json({
                succeeded: true,
            });
        }
        catch(error){
            return res.status(500).json({succeeded: false, message: "Thêm hồ sơ sức khỏe thất bại: " + error.message});
        }
    }

    static async updateHealthRecord(req, res) {
        try {
            // Lấy ID tài khoản từ token (do middleware auth.js bóc tách)
            const userID = req.Ma_nguoi_dung; 
            
            // Lấy dữ liệu từ body của Frontend gửi lên
            const { 
                maBenhNhan, // Bắt buộc phải có ID của hồ sơ cần sửa
                tenHoSo, 
                moiQuanHe, 
                birthDay, 
                gender, 
                address, 
                nhomMau, 
                diUng, 
                benhNen 
            } = req.body;

            // Kiểm tra các trường bắt buộc
            if (!maBenhNhan || !birthDay || gender === undefined || !address) {
                return res.status(400).json({
                    succeeded: false,
                    message: "Mã bệnh nhân, Ngày sinh, Giới tính và Địa chỉ là các trường bắt buộc."
                });
            }

            // Gọi model để thực thi
            await healthRecordModel.updateHealthRecord(
                maBenhNhan, userID, tenHoSo, moiQuanHe, birthDay, gender, address, 
                nhomMau ?? null, 
                diUng ?? null, 
                benhNen ?? null
            );

            // Trả về thành công
            return res.status(200).json({
                succeeded: true,
                message: "Cập nhật hồ sơ sức khỏe thành công!"
            });

        } catch (error) {
            return res.status(500).json({
                succeeded: false, 
                message: "Cập nhật hồ sơ thất bại: " + error.message
            });
        }
    }

    static async getHealthRecordDetail(req, res) {
        try {
            const userID = req.Ma_nguoi_dung; 
            const maBenhNhan = req.params.id; 

            if (!maBenhNhan) {
                return res.status(400).json({
                    succeeded: false,
                    message: "Vui lòng cung cấp mã bệnh nhân."
                });
            }

            // Gọi xuống Model để lấy dữ liệu đã giải mã
            const record = await healthRecordModel.getHealthRecordDetail(maBenhNhan, userID);

            if (!record) {
                return res.status(404).json({
                    succeeded: false,
                    message: "Không tìm thấy hồ sơ sức khỏe hoặc bạn không có quyền xem hồ sơ này."
                });
            }

            // Trả về dữ liệu chuẩn khớp với cấu trúc Model ở Flutter
            return res.status(200).json({
                succeeded: true,
                message: "Lấy chi tiết hồ sơ thành công",
                record: {
                    Ma_benh_nhan: record.Ma_benh_nhan,
                    Ten_ho_so: record.Ten_ho_so || "Chủ tài khoản",
                    Vai_tro: record.Vai_tro || "Bản thân",
                    Ngay_sinh: record.Ngay_sinh,
                    Gioi_tinh: record.Gioi_tinh,
                    Dia_chi: record.Dia_chi,
                    Nhom_mau: record.Nhom_mau,
                    Di_ung: record.Di_ung,
                    Benh_nen: record.Benh_nen
                }
            });

        } catch (error) {
            return res.status(500).json({
                succeeded: false,
                message: "Lỗi xử lý lấy chi tiết hồ sơ: " + error.message
            });
        }
    }
}