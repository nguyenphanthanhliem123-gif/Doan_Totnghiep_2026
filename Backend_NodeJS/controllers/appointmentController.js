import AppointmentModel from "../models/AppointmentModel.js";

export default class AppointmentController {
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
}