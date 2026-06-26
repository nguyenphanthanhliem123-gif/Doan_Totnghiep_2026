// Backend_NodeJS/controllers/scheduleController.js
import ScheduleModel from "../models/scheduleModel.js";
import doctorModel from "../models/doctorModel.js";
import VNPayServices from "../services/vnpayService.js";
import sendNotification from "../utils/notificationHelper.js";
import paymentModel from "../models/paymentModel.js";
import moment from 'moment';
import EmailService from "../services/emailService.js";

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
            const { date, buoi, reason } = req.body; 

            if (!date || !buoi) {
                return res.status(400).json({ succeeded: false, message: "Vui lòng chọn ngày và buổi cần nghỉ" });
            }

            const doctor = await doctorModel.getDoctorDetailByUserID(userId);
            if (!doctor) return res.status(404).json({ succeeded: false, message: "Không tìm thấy thông tin bác sĩ" });

            // 1. Gọi model cập nhật trạng thái dữ liệu và lấy về mảng cần hoàn tiền
            const result = await ScheduleModel.registerSuddenLeaveWithoutDBChange(doctor.Ma_bac_si, date, buoi, reason);

            // 🌟 2. XỬ LÝ HOÀN TIẾN (REFUND) TỰ ĐỘNG
            let refundSuccessCount = 0;
            if (result.appointmentsToRefund && result.appointmentsToRefund.length > 0) {
                for (const appt of result.appointmentsToRefund) {
                    
                    // Gói dữ liệu theo chuẩn đầu vào của vnpayService.js
                    const thongTinGiaoDich = {
                        maBooking: appt.Ma_booking,
                        soTien: appt.Tong_tien,
                        maGiaoDich: appt.Ma_giao_dich,
                        // Convert định dạng SQL Datetime sang chuẩn YYYYMMDDHHmmss của VNPay
                        ngayGiaoDich: moment(appt.Ngay_thanh_toan).format('YYYYMMDDHHmmss') 
                    };
                    const io = req.app.get('io');
                    await sendNotification(
                        appt.Ma_nguoi_dung,
                        'Hủy lịch hẹn',
                        reason,
                        io
                    );

                    if (appt.Email) {
                        const dateTime = new Date(appt.Ngay_kham);
                        const thongTinEmail = {
                            maBooking: appt.Ma_booking,
                            tenBacSi: appt.Ten_bac_si,
                            ngayKham: appt.Ngay_kham,
                            gioKham: appt.Gio_kham,
                            diaChi: appt.Dia_chi_phong_kham
                        };
                        EmailService.sendBookingConfirmationEmail(appt.Email, thongTinEmail).catch(err => console.log("Lỗi gửi mail ngầm"));
                    }

                    if(appt.Trang_thai_thanh_toan == 'pending'){
                        await paymentModel.updateStatus(appt.Ma_booking, 'fail');
                    }else{
                        // Gọi sang cổng VNPay
                        const isRefunded = await VNPayServices.xulyHoanTienVNPay(thongTinGiaoDich);
                        
                        if (isRefunded) {
                            refundSuccessCount++;
                            await paymentModel.updateStatus(appt.Ma_booking, 'refunded');
                        }else{
                            await paymentModel.updateStatus(appt.Ma_booking, 'refund_fail');
                        }
                    }
                }
            }

            // Tạo chuỗi thông báo trả về Front-end
            let responseMsg = `Đã khóa ${result.slotsLocked} ca trống. Tự động hủy ${result.appointmentsCancelled} lịch hẹn.`;
            if (result.appointmentsToRefund.length > 0) {
                responseMsg += ` Đã hoàn tiền qua VNPay thành công ${refundSuccessCount}/${result.appointmentsToRefund.length} giao dịch.`;
            }

            return res.status(200).json({
                succeeded: true,
                message: responseMsg
            });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }
}