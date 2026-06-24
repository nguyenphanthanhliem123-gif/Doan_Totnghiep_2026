// Backend_NodeJS/controllers/scheduleController.js
import ScheduleModel from "../models/scheduleModel.js";
import doctorModel from "../models/doctorModel.js";

export default class ScheduleController {
    static async updateScheduleConfig(req, res) {
        try {
            const userId = req.Ma_nguoi_dung;
            const { slotTime, breakTime, maxPatients, weeklySchedule } = req.body;

            const doctor = await doctorModel.getDoctorDetailByUserID(userId);
            if (!doctor) return res.status(404).json({ succeeded: false, message: "Không tìm thấy thông tin bác sĩ" });

            // 1. Lưu cấu hình chung
            await ScheduleModel.saveConfig(doctor.Ma_bac_si, slotTime, breakTime, maxPatients);

            // 2. Lưu lịch các buổi tuần (Thứ 2 -> Thứ 7)
            if (weeklySchedule && weeklySchedule.length > 0) {
                await ScheduleModel.saveWeeklySchedule(doctor.Ma_bac_si, weeklySchedule);
            }

            return res.status(200).json({ succeeded: true, message: "Cập nhật cấu hình lịch làm việc thành công" });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    static async getScheduleConfig(req, res) {
        try {
            const userId = req.Ma_nguoi_dung;
            const doctor = await doctorModel.getDoctorDetailByUserID(userId);
            if (!doctor) return res.status(404).json({ succeeded: false, message: "Không tìm thấy bác sĩ" });

            const data = await ScheduleModel.getDoctorScheduleConfig(doctor.Ma_bac_si);
            return res.status(200).json({ succeeded: true, data });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    static async generateDoctorSlots(req, res) {
        try {
            const userId = req.Ma_nguoi_dung;
            // Nhận khoảng ngày muốn phát sinh từ Client (Ví dụ: 2026-07-01 đến 2026-07-07)
            const { startDate, endDate } = req.body;

            if (!startDate || !endDate) {
                return res.status(400).json({ succeeded: false, message: "Vui lòng cung cấp startDate và endDate (định dạng YYYY-MM-DD)" });
            }

            const doctor = await doctorModel.getDoctorDetailByUserID(userId);
            if (!doctor) return res.status(404).json({ succeeded: false, message: "Không tìm thấy thông tin bác sĩ" });

            // Gọi xuống tầng Model xử lý sinh lịch
            const result = await ScheduleModel.generateSlotsForDateRange(doctor.Ma_bac_si, startDate, endDate);

            return res.status(200).json({ 
                succeeded: true, 
                message: `Phát sinh khung giờ khám thành công. Đã thêm mới ${result.slotsCreated || 0} slot tự do.`,
                data: result
            });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    static async reportSuddenLeave(req, res) {
        try {
            const userId = req.Ma_nguoi_dung;
            const { date, buoi, reason } = req.body; // date: "YYYY-MM-DD"

            if (!date || !buoi) {
                return res.status(400).json({ succeeded: false, message: "Vui lòng chọn ngày và buổi cần nghỉ" });
            }

            const doctor = await doctorModel.getDoctorDetailByUserID(userId);
            if (!doctor) return res.status(404).json({ succeeded: false, message: "Không tìm thấy thông tin bác sĩ" });

            // Gọi model cập nhật trạng thái dữ liệu
            const result = await ScheduleModel.registerSuddenLeaveWithoutDBChange(doctor.Ma_bac_si, date, buoi, reason);

            return res.status(200).json({
                succeeded: true,
                message: `Đã khóa ${result.slotsLocked} ca khám trống. ${result.appointmentsCancelled > 0 ? `Tự động hủy lịch và thông báo tới ${result.appointmentsCancelled} bệnh nhân.` : 'Không có lịch hẹn nào bị ảnh hưởng.'}`
            });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }
}