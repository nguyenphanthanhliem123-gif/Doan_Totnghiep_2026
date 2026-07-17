import app from "../index.js";
import appointmentModel from "../models/AppointmentModel.js";
import AppointmentModel from "../models/AppointmentModel.js";
import paymentModel from "../models/paymentModel.js";
import EmailService from "../services/emailService.js";
import VNPayServices from "../services/vnpayService.js";
import sendNotification from "../utils/notificationHelper.js";

export default class AppointmentController {

    // Lấy danh sách lịch hẹn của bệnh nhân
    static async getMyList(req, res) {
        try {
            const userID = req.Ma_nguoi_dung; 
            const { status, date, search } = req.query; // 🌟 Hứng query params

            if (!userID) {
                return res.status(400).json({ succeeded: false, message: "Không tìm thấy thông tin người dùng." });
            }

            // Truyền params xuống Model
            const appointments = await AppointmentModel.getPatientAppointments(userID, status, date, search);

            return res.status(200).json({
                succeeded: true,
                message: "Lấy danh sách lịch hẹn thành công",
                data: appointments
            });

        } catch (error) {
            return res.status(500).json({ succeeded: false, message: "Lỗi server: " + error.message });
        }
    }

    // Lấy chi tiết lịch hẹn dựa trên Ma_lich_hen
    static async getDetails(req, res) {
        try {
            const appointmentID = req.params.id;

            if (!appointmentID) return res.status(400).json({ succeeded: false, message: "Thiếu mã lịch hẹn." });

            const detail = await AppointmentModel.getAppointmentDetails(appointmentID);

            if (!detail) return res.status(404).json({ succeeded: false, message: "Không tìm thấy lịch hẹn này." });

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

            const appointmentDetail = await AppointmentModel.getAppointmentDetails(appointmentID);
            const io = req.app.get('io');
            if (appointmentDetail && appointmentDetail.Ma_nguoi_dung_bac_si) {
                await sendNotification(
                    appointmentDetail.Ma_nguoi_dung_bac_si,
                    'Hủy lịch hẹn',
                    'Lịch hẹn mã ' + appointmentDetail.Ma_booking + ' của bạn với bệnh nhân ' + appointmentDetail.Ten_nguoi_kham + ' đã bị hủy.',
                    io
                );
            }

            return res.status(200).json({ succeeded: true, message: "Hủy lịch thành công. Lưu ý: Tiền thanh toán online sẽ không được hoàn lại theo chính sách." });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: "Lỗi hệ thống: " + error.message });
        }
    }

    // Đổi lịch hẹn với điều kiện chặn đổi trước 2 giờ
    static async reschedule(req, res) {
        try {
            const appointmentID = req.params.id;
            const { newSlotId } = req.body; 

            if (!newSlotId) return res.status(400).json({ succeeded: false, message: "Thiếu mã khung giờ mới." });

            const bookingId = await appointmentModel.getAppointmentDetails(appointmentID);
            const result = await appointmentModel.rescheduleAppointment(appointmentID, newSlotId);

            if (!result.success) {
                return res.status(400).json({ succeeded: false, message: result.message });
            }
            
            const io = req.app.get('io');
            await sendNotification(
                bookingId.Ma_nguoi_dung_bac_si,
                'Đổi lịch',
                'Lịch hẹn ' + bookingId.Ma_booking + ' đã được dời sang thời gian khác.',
                io
            );

            return res.status(200).json({ succeeded: true, message: result.message });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: "Lỗi hệ thống: " + error.message });
        }
    }

    // API xem đơn thuốc của bệnh nhân dựa trên Ma_lich_hen
    static async getPatientPrescription(req, res) {
        try {
            const appointmentID = req.params.id; 
            const userID = req.Ma_nguoi_dung; 

            if (!appointmentID) return res.status(400).json({ succeeded: false, message: "Thiếu mã lịch hẹn." });

            const checkDetail = await appointmentModel.getAppointmentDetails(appointmentID);
            if (!checkDetail || checkDetail.Ma_nguoi_dung !== userID) {
                return res.status(403).json({ succeeded: false, message: "Truy cập bị từ chối. Bạn không có quyền xem đơn thuốc này." });
            }

            const data = await appointmentModel.getPrescriptionByAppointmentId(appointmentID);
            
            if (!data) return res.status(404).json({ succeeded: false, message: "Chưa có đơn thuốc cho ca khám này." });

            return res.status(200).json({ succeeded: true, data: data });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: "Lỗi hệ thống: " + error.message });
        }
    }

    // =====================================================================
    // CÁC HÀM DÀNH CHO BÁC SĨ (DOCTOR PORTAL)
    // =====================================================================

    // Lấy dữ liệu trang chủ Bác sĩ
    static async getDoctorDashboard(req, res) {
        try {
            const userID = req.Ma_nguoi_dung;
            
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

    // Cập nhật trạng thái lịch hẹn của bác sĩ (confirm hoặc reject)
    static async updateStatus(req, res) {
        try {
            const appointmentID = req.params.id;
            const { action } = req.body;
            const userID = req.Ma_nguoi_dung;

            if (!action || !['confirm', 'reject'].includes(action)) {
                return res.status(400).json({ succeeded: false, message: "Hành động không hợp lệ." });
            }

            // LOGIC CHUYỂN TRẠNG THÁI: Bảo vệ tiền thanh toán Online
            let status = 'confirmed';
            if (action === 'reject') {
                const info = await AppointmentModel.getAppointmentForReschedule(appointmentID);
                // Ép sang reschedule_pending nếu đã thanh toán (paid) hoặc phương thức là VNPay
                if (info && (info.Trang_thai_thanh_toan === 'paid' || (info.Tong_tien > 0 && info.Phuong_thuc_thanh_toan !== 'cash'))) {
                    status = 'reschedule_pending';
                } else {
                    status = 'cancelled';
                }
            }

            const result = await AppointmentModel.updateAppointmentStatus(appointmentID, status, userID);
            if (!result.success) return res.status(400).json({ succeeded: false, message: result.message });

            const appointmentDetail = await AppointmentModel.getAppointmentDetails(appointmentID);
            if (appointmentDetail && appointmentDetail.Ma_nguoi_dung) {
                const io = req.app.get('io');
                let title = '', body = '';

                if (status === 'confirmed') {
                    title = 'Xác nhận lịch hẹn';
                    body = 'Lịch hẹn mã ' + appointmentDetail.Ma_booking + ' của bạn với ' + appointmentDetail.Ten_bac_si + ' đã được xác nhận.';
                } else if (status === 'reschedule_pending') {
                    title = 'Bác sĩ bận đột xuất';
                    body = 'Lịch hẹn mã ' + appointmentDetail.Ma_booking + ' đã được bảo lưu. Bạn vui lòng vào ứng dụng để Xếp lại thời gian khám khác với bác sĩ nhé.';
                } else {
                    title = 'Từ chối lịch hẹn';
                    body = 'Lịch hẹn mã ' + appointmentDetail.Ma_booking + ' của bạn với ' + appointmentDetail.Ten_bac_si + ' đã bị từ chối.';
                }

                await sendNotification(appointmentDetail.Ma_nguoi_dung, title, body, io);
            }

            let msg = status === 'confirmed' ? "Đã xác nhận lịch hẹn." : 
                     (status === 'reschedule_pending' ? "Đã báo bận. Lịch của bệnh nhân đã được chuyển sang trạng thái Chờ dời lịch." : "Đã hủy lịch hẹn.");
            return res.status(200).json({ succeeded: true, message: msg });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // Bác sĩ báo hoàn thành ca khám
    static async updateStatusDone(req,res){
        try{
            const appointmentID = req.params.id;
            const userID = req.Ma_nguoi_dung;

            if(!appointmentID) return res.status(400).json({ succeeded: false, message: 'Thiếu ID lịch hẹn' });

            await AppointmentModel.updateAppointmentStatusDone(appointmentID, userID);

            const appointmentDetail = await AppointmentModel.getAppointmentDetails(appointmentID);
            
            if (appointmentDetail && appointmentDetail.Ma_nguoi_dung) {
                const io = req.app.get('io');
                await sendNotification(
                    appointmentDetail.Ma_nguoi_dung,
                    'Đánh giá', 
                    '[Mã lịch hẹn ' + appointmentDetail.Ma_booking + '][ID ' + appointmentID + '] Vui lòng cho biết đánh giá của bạn về bác sĩ ' + appointmentDetail.Ten_bac_si,
                    io
                );
            }

            return res.status(200).json({ succeeded: true, message: "Đã hoàn thành ca khám." });
        } catch(error){
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // Bác sĩ báo bệnh nhân vắng mặt
    static async updateStatusAbsent(req, res) {
        try {
            const appointmentID = req.params.id;
            const userID = req.Ma_nguoi_dung;

            if (req.Phan_quyen !== 'Bac_si' && req.Phan_quyen !== 'Admin') {
                return res.status(403).json({ succeeded: false, message: "Truy cập bị từ chối. Chỉ dành cho bác sĩ." });
            }

            if (!appointmentID) {
                return res.status(400).json({ succeeded: false, message: 'Thiếu ID lịch hẹn.' });
            }

            await AppointmentModel.updateAppointmentStatusAbsent(appointmentID, userID);

            return res.status(200).json({
                succeeded: true,
                message: "Đã ghi nhận bệnh nhân vắng mặt và giải phóng khung giờ thành công."
            });
        } catch (error) {
            return res.status(500).json({
                succeeded: false,
                message: error.message
            });
        }
    }

    // Lấy tất cả lịch hẹn của bác sĩ
    static async getAllDoctorList(req, res) {
        try {
            const userID = req.Ma_nguoi_dung;
            const { status, date, search } = req.query; // 🌟 Hứng query params

            if (req.Phan_quyen !== 'Bac_si' && req.Phan_quyen !== 'Admin') {
                return res.status(403).json({ succeeded: false, message: "Truy cập bị từ chối." });
            }

            // Truyền params xuống Model
            const data = await AppointmentModel.getAllDoctorAppointments(userID, status, date, search);

            return res.status(200).json({ succeeded: true, message: "Lấy danh sách thành công", data: data });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // Lấy chi tiết 1 ca khám cho Bác sĩ
    static async getDoctorAppointmentDetail(req, res) {
        try {
            const { id } = req.params;

            if (req.Phan_quyen !== 'Bac_si' && req.Phan_quyen !== 'Admin') {
                return res.status(403).json({ succeeded: false, message: "Truy cập bị từ chối." });
            }

            if (!id) return res.status(400).json({ succeeded: false, message: "Thiếu mã lịch hẹn." });

            const data = await AppointmentModel.getDoctorAppointmentDetail(id);

            if (!data) return res.status(404).json({ succeeded: false, message: "Không tìm thấy thông tin ca khám." });

            return res.status(200).json({ succeeded: true, message: "Lấy chi tiết ca khám thành công", data: data });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: "Lỗi hệ thống: " + error.message });
        }
    }

    // Lấy lịch sử bệnh án (Dùng ID ca khám hiện tại để truy vết người bệnh)
    static async getMedicalHistory(req, res) {
        try {
            const { id } = req.params; 

            const currentAppt = await AppointmentModel.getDoctorAppointmentDetail(id);
            if (!currentAppt) {
                return res.status(404).json({ succeeded: false, message: "Không tìm thấy ca khám." });
            }

            const history = await AppointmentModel.getMedicalHistory(
                currentAppt.Ma_benh_nhan, 
                currentAppt.Ma_nguoi_than
            );

            return res.status(200).json({
                succeeded: true,
                data: history
            });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // Kê đơn thuốc
    static async completeWithPrescription(req, res) {
        try {
            const appointmentID = req.params.id;
            const userID = req.Ma_nguoi_dung;
            const { chuanDoan, ngayTaiKham, danhSachThuoc } = req.body;

            if (!appointmentID) return res.status(400).json({ succeeded: false, message: 'Thiếu ID lịch hẹn' });
            if (!chuanDoan) return res.status(400).json({ succeeded: false, message: 'Vui lòng nhập chẩn đoán bệnh lý.' });

            await AppointmentModel.completeAndPrescribe(appointmentID, userID, { chuanDoan, ngayTaiKham, danhSachThuoc });

            const appointmentDetail = await AppointmentModel.getAppointmentDetails(appointmentID);
            if (appointmentDetail && appointmentDetail.Ma_nguoi_dung) {
                const io = req.app.get('io');
                await sendNotification(
                    appointmentDetail.Ma_nguoi_dung,
                    'Đánh giá ca khám', 
                    '[Mã lịch hẹn ' + appointmentDetail.Ma_booking + '] Vui lòng cho biết đánh giá của bạn về bác sĩ ' + appointmentDetail.Ten_bac_si,
                    io
                );
            }

            return res.status(200).json({ succeeded: true, message: "Hoàn thành ca khám và kê đơn thành công." });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // Xem đơn thuốc
    static async getPrescription(req, res) {
        try {
            const { id } = req.params; 
            if (!id) return res.status(400).json({ succeeded: false, message: "Thiếu mã lịch hẹn." });

            const data = await AppointmentModel.getPrescriptionByAppointmentId(id);
            
            if (!data) return res.status(404).json({ succeeded: false, message: "Chưa có đơn thuốc cho ca khám này." });

            return res.status(200).json({ succeeded: true, data: data });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }
}