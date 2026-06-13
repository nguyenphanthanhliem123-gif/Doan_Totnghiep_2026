import doctorModel from '../models/doctorModel.js';

export default class doctorController {
    // API lấy chi tiết bác sĩ theo ID
    static async getDoctorById(req, res) {
        try {
            const { id } = req.params;

            if (!id) {
                return res.status(400).json({ succeeded: false, message: "Thiếu mã bác sĩ" });
            }

            const doctor = await doctorModel.getDoctorDetail(id);

            if (!doctor) {
                return res.status(404).json({ succeeded: false, message: "Không tìm thấy thông tin bác sĩ" });
            }

            // Kéo danh sách dịch vụ
            const services = await doctorModel.getDoctorServices(id);
            doctor.dich_vu = services; 

            // Kéo lịch làm việc
            const schedule = await doctorModel.getDoctorSchedule(id);
            doctor.lich_lam_viec = schedule;

            return res.status(200).json({ 
                succeeded: true, 
                data: doctor 
            });

        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    static async getAllDoctor(req,res){
        try {
            const specialtyId = req.query.specialtyId;

            console.log('=== SpecialID: ' + specialtyId);

            const doctors = await doctorModel.getDoctors(specialtyId);

            
            return res.status(200).json({
                succeeded: true,
                doctors: doctors
            });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }
}