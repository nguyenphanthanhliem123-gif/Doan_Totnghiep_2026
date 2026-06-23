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
}