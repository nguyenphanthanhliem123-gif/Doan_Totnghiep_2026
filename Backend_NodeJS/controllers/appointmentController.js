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

    // API Hủy lịch hẹn với điều kiện chặn hủy trước 2 giờ
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
}