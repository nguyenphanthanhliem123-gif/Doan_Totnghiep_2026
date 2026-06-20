import AppointmentModel from "../models/AppointmentModel.js";

export default class AppointmentController {

    // Lấy danh sách lịch hẹn của bệnh nhân dựa trên userID
    static async getMyList(req, res) {
        try {
            // Lấy ID người dùng từ token
            const userID = req.Ma_nguoi_dung; 

            if (!userID) {
                return res.status(400).json({
                    succeeded: false,
                    message: "Không tìm thấy thông tin người dùng."
                });
            }

            const appointments = await AppointmentModel.getPatientAppointments(userID);

            return res.status(200).json({
                succeeded: true,
                message: "Lấy danh sách lịch hẹn thành công",
                data: appointments
            });

        } catch (error) {
            return res.status(500).json({
                succeeded: false,
                message: "Lỗi server: " + error.message
            });
        }
    }

    // Lấy chi tiết lịch hẹn dựa trên Ma_lich_hen
    static async getDetails(req, res) {
        try {
            const appointmentID = req.params.id;

            if (!appointmentID) {
                return res.status(400).json({ succeeded: false, message: "Thiếu mã lịch hẹn." });
            }

            const detail = await AppointmentModel.getAppointmentDetails(appointmentID);

            if (!detail) {
                return res.status(404).json({ succeeded: false, message: "Không tìm thấy lịch hẹn này." });
            }

            return res.status(200).json({
                succeeded: true,
                message: "Lấy chi tiết lịch hẹn thành công",
                data: detail
            });

        } catch (error) {
            return res.status(500).json({ succeeded: false, message: "Lỗi server: " + error.message });
        }
    }

    // Hủy lịch hẹn với điều kiện chặn hủy trước 2 giờ
    static async cancel(req, res) {
        try {
            const appointmentID = req.params.id;
            const result = await AppointmentModel.cancelAppointment(appointmentID);

            if (!result.success) {
                return res.status(400).json({ succeeded: false, message: result.message });
            }

            return res.status(200).json({ succeeded: true, message: result.message });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: "Lỗi hệ thống: " + error.message });
        }
    }

    // Đổi lịch hẹn với điều kiện chặn đổi trước 2 giờ và kiểm tra slot mới
    static async reschedule(req, res) {
        try {
            const appointmentID = req.params.id;
            const { newSlotId } = req.body; // Lấy slot mới từ body

            if (!newSlotId) return res.status(400).json({ succeeded: false, message: "Thiếu mã khung giờ mới." });

            const result = await AppointmentModel.rescheduleAppointment(appointmentID, newSlotId);

            if (!result.success) {
                return res.status(400).json({ succeeded: false, message: result.message });
            }

            return res.status(200).json({ succeeded: true, message: result.message });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: "Lỗi hệ thống: " + error.message });
        }
    }

    // =====================================================================
    // CÁC HÀM DÀNH CHO BÁC SĨ (DOCTOR PORTAL)
    // =====================================================================

    // API đổ dữ liệu ra Trang chủ Bác sĩ
    static async getDoctorDashboard(req, res) {
        try {
            const userID = req.Ma_nguoi_dung;
            
            // Check bảo mật: Đảm bảo người gọi API là bác sĩ
            if (req.Phan_quyen !== 'Bac_si' && req.Phan_quyen !== 'Admin') {
                return res.status(403).json({ succeeded: false, message: "Truy cập bị từ chối. Chỉ dành cho bác sĩ." });
            }

            const data = await AppointmentModel.getDoctorDashboard(userID);

            return res.status(200).json({
                succeeded: true,
                message: "Lấy dữ liệu Dashboard thành công",
                data: data
            });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // API xử lý nút [Xác nhận] / [Từ chối]
    static async updateStatus(req, res) {
        try {
            const userID = req.Ma_nguoi_dung;
            const appointmentID = req.params.id;
            const { action } = req.body; // action sẽ là 'confirm' hoặc 'reject'

            // Check bảo mật: Đảm bảo người gọi API là bác sĩ
            if (req.Phan_quyen !== 'Bac_si' && req.Phan_quyen !== 'Admin') {
                return res.status(403).json({ succeeded: false, message: "Truy cập bị từ chối." });
            }

            if (!action || !['confirm', 'reject'].includes(action)) {
                return res.status(400).json({ succeeded: false, message: "Hành động không hợp lệ." });
            }

            // Chuyển đổi action từ Frontend thành trạng thái Database
            const status = action === 'confirm' ? 'confirmed' : 'cancelled';

            const result = await AppointmentModel.updateAppointmentStatus(appointmentID, status, userID);

            return res.status(200).json({ succeeded: true, message: result.message });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // API: Lấy toàn bộ danh sách lịch hẹn của Bác sĩ
    static async getAllDoctorList(req, res) {
        try {
            const userID = req.Ma_nguoi_dung;

            // Chặn quyền
            if (req.Phan_quyen !== 'Bac_si' && req.Phan_quyen !== 'Admin') {
                return res.status(403).json({ succeeded: false, message: "Truy cập bị từ chối. Chỉ dành cho bác sĩ." });
            }

            const data = await AppointmentModel.getAllDoctorAppointments(userID);

            return res.status(200).json({
                succeeded: true,
                message: "Lấy danh sách lịch hẹn thành công",
                data: data
            });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }
}