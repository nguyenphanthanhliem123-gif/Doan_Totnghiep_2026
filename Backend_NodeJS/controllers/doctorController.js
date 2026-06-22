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

    static async getDoctors(req, res) {
        try {
            // Lấy toàn bộ query params người dùng gửi lên
            const filters = {
                specialtyId: req.query.specialtyId,
                location: req.query.location,
                minPrice: req.query.minPrice,
                maxPrice: req.query.maxPrice,
                minRating: req.query.minRating,
                availableDate: req.query.availableDate,
                sortBy: req.query.sortBy,
                userLat: req.query.userLat,
                userLng: req.query.userLng
            };
            
            const doctors = await doctorModel.getDoctorsFilter(filters); 
            
            return res.status(200).json({ 
                succeeded: true, 
                doctors: doctors 
            });
        } catch (error) {
            return res.status(500).json({ 
                succeeded: false, 
                message: error.message 
            });
        }
    }

    static async updateProfile(req, res) {
        try {
            const userId = req.Ma_nguoi_dung; // Lấy từ token
            
            // Cứ ném toàn bộ req.body vào Model, Model sẽ tự chọn lọc
            const updateData = {
                Ma_chuyen_khoa: req.body.ma_chuyen_khoa,
                Mo_ta_ban_than: req.body.mo_ta,
                Hoc_vi: req.body.hoc_vi,
                So_nam_kinh_nghiem: req.body.so_nam_kinh_nghiem
            };

            // Lọc bỏ những object key có giá trị là undefined (phòng hờ) trước khi truyền
            Object.keys(updateData).forEach(key => updateData[key] === undefined && delete updateData[key]);

            await DoctorModel.updateProfileDoctor(userId, updateData);

            return res.status(200).json({ succeeded: true, message: "Cập nhật thành công!" });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }
}