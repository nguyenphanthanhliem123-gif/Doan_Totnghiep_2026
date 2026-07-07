import clinicModel from '../models/clinicModel.js';

export default class clinicController {
    // API lấy chi tiết phòng khám theo ID
    static async getClinicById(req, res) {
        try {
            const { id } = req.params;
            if (!id) return res.status(400).json({ succeeded: false, message: "Thiếu mã phòng khám" });

            const clinic = await clinicModel.getClinicById(id);

            if (!clinic) return res.status(404).json({ succeeded: false, message: "Không tìm thấy phòng khám" });

            return res.status(200).json({ succeeded: true, data: clinic });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    static async getAllClinics(req,res){
        try{
            const rows = await clinicModel.getAllClinics();

            return res.status(200).json({
                succeeded: true,
                clinics: rows
            });
        }catch(error){
            return res.status(500).json({
                succeeded: false,
                message: error.message
            });
        }
    }

    static async updateDoctorClinics(req, res) {
        try {
            const userId = req.Ma_nguoi_dung; // Lấy ID bác sĩ từ token (middleware auth)
            
            // Lấy mảng clinics từ body do Flutter gửi lên
            const { clinics } = req.body; 

            // 1. Kiểm tra dữ liệu xem có hợp lệ không
            if (!clinics || !Array.isArray(clinics)) {
                return res.status(400).json({ 
                    succeeded: false, 
                    message: "Dữ liệu phòng khám không hợp lệ" 
                });
            }

            await clinicModel.updateDoctorClinics(userId, clinics);

            return res.status(200).json({ 
                succeeded: true, 
                message: "Cập nhật cơ sở y tế thành công!" 
            });

        } catch (error) {
            console.error("Lỗi cập nhật CSYT:", error);
            return res.status(500).json({ 
                succeeded: false, 
                message: error.message 
            });
        }
    }

    static async createClinic(req, res) {
        try {
            const { Ten_phong_kham, Vi_tri } = req.body;
            if (!Ten_phong_kham || !Vi_tri) {
                return res.status(400).json({ succeeded: false, message: "Tên và vị trí là bắt buộc!" });
            }
            const newId = await clinicModel.addClinic(req.body);
            return res.status(201).json({ succeeded: true, message: "Thêm thành công!", id: newId });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    static async updateClinic(req, res) {
        try {
            const { id } = req.params;
            const success = await clinicModel.updateClinic(id, req.body);
            if (success) return res.status(200).json({ succeeded: true, message: "Cập nhật thành công!" });
            return res.status(404).json({ succeeded: false, message: "Không tìm thấy phòng khám!" });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // Xử lý upload ảnh
    static async uploadClinicImage(req, res) {
        try {
            const { id } = req.params; // Ma_phong_kham
            
            // Kiểm tra xem có file gửi lên không
            if (!req.files || Object.keys(req.files).length === 0) {
                return res.status(400).json({ succeeded: false, message: "Không có file ảnh nào được tải lên." });
            }

            const imageFile = req.files.image; // 'image' là key từ khóa do Frontend gửi lên
            
            // Đặt tên file ngẫu nhiên để không bị trùng lặp
            const fileName = `clinic_${id}_${Date.now()}_${imageFile.name.replace(/\s+/g, '_')}`;
            const uploadPath = `./uploads/${fileName}`;

            // Di chuyển file vào thư mục uploads
            imageFile.mv(uploadPath, async (err) => {
                if (err) {
                    return res.status(500).json({ succeeded: false, message: "Lỗi lưu file: " + err.message });
                }
                
                // Lưu đường dẫn ảnh vào Database
                const imageUrl = `/uploads/${fileName}`;
                await clinicModel.addClinicImage(id, imageUrl);
                
                return res.status(200).json({ 
                    succeeded: true, 
                    message: "Tải ảnh lên thành công!", 
                    imageUrl: imageUrl 
                });
            });

        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }
}