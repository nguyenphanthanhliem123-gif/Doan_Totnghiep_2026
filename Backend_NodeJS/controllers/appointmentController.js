import app from "../index.js";
import appointmentModel from "../models/AppointmentModel.js";
import AppointmentModel from "../models/AppointmentModel.js";
import paymentModel from "../models/paymentModel.js";
import EmailService from "../services/emailService.js";
import VNPayServices from "../services/vnpayService.js";
import sendNotification from "../utils/notificationHelper.js";

export default class AppointmentController {

    // Lấy danh sách lịch hẹn của bệnh nhân dựa trên userID
    static async getMyList(req, res) {
        try {
            const userID = req.Ma_nguoi_dung; 
            console.log('=== MY LIST USERID: ' + userID);

            if (!userID) {
                return res.status(400).json({ succeeded: false, message: "Không tìm thấy thông tin người dùng." });
            }

            const appointments = await AppointmentModel.getPatientAppointments(userID);

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

    // Hủy lịch hẹn (Bệnh nhân chủ động)
    static async cancel(req, res) {
        try {
            const appointmentID = req.params.id;
            const result = await AppointmentModel.cancelAppointment(appointmentID);

            if (!result.success) {
                return res.status(400).json({ succeeded: false, message: result.message });
            }

            // Gửi thông báo báo cho BÁC SĨ 
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

    // Đổi lịch hẹn với điều kiện chặn đổi trước 2 giờ và kiểm tra slot mới
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

    // Hàm Bệnh nhân lấy chi tiết đơn thuốc (Có bảo mật chống xem trộm)
    static async getPatientPrescription(req, res) {
        try {
            const appointmentID = req.params.id; // Ma_lich_hen
            const userID = req.Ma_nguoi_dung; // Ma_nguoi_dung từ token bệnh nhân

            if (!appointmentID) return res.status(400).json({ succeeded: false, message: "Thiếu mã lịch hẹn." });

            // 1. Kiểm tra xác thực ngầm: Lịch hẹn này có phải của bệnh nhân này không
            const checkDetail = await appointmentModel.getAppointmentDetails(appointmentID);
            if (!checkDetail || checkDetail.Ma_nguoi_dung !== userID) {
                return res.status(403).json({ succeeded: false, message: "Truy cập bị từ chối. Bạn không có quyền xem đơn thuốc này." });
            }

            // 2. Nếu đúng là chủ sở hữu, tiến hành lấy đơn thuốc
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

    // API đổ dữ liệu ra Trang chủ Bác sĩ
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

    // Bác sĩ Cập nhật trạng thái lịch hẹn (Xác nhận hoặc Báo bận)
    static async updateStatus(req, res) {
        try {
            const appointmentID = req.params.id;
            const { action } = req.body;
            const userID = req.Ma_nguoi_dung;

            if (!action || !['confirm', 'reject'].includes(action)) {
                return res.status(400).json({ succeeded: false, message: "Hành động không hợp lệ." });
            }

            // LOGIC KIỂM TRA DÒNG TIỀN ĐỂ CHUYỂN TRẠNG THÁI
            let status = 'confirmed';
            if (action === 'reject') {
                const info = await AppointmentModel.getAppointmentForRefund(appointmentID);
                // NẾU ĐÃ TRẢ TIỀN ONLINE -> BẢO LƯU (Chờ dời lịch)
                if (info && (info.Trang_thai_thanh_toan === 'paid' || info.Tong_tien > 0 && info.Phuong_thuc_thanh_toan !== 'cash')) {
                    status = 'reschedule_pending';
                } else {
                    // NẾU LÀ TIỀN MẶT -> HỦY LUÔN KHÔNG THƯƠNG TIẾC
                    status = 'cancelled';
                }
            }

            const result = await AppointmentModel.updateAppointmentStatus(appointmentID, status, userID);
            if (!result.success) return res.status(400).json({ succeeded: false, message: result.message });

            // Xử lý Gửi Thông báo cho bệnh nhân
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

    // Api Bác sĩ báo hoàn thành ca khám
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

    // API Bác sĩ báo bệnh nhân vắng mặt
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

    // API Lấy toàn bộ danh sách lịch hẹn của Bác sĩ (Có nhận query lọc)
    static async getAllDoctorList(req, res) {
        try {
            const userID = req.Ma_nguoi_dung;
            const { status, date } = req.query; // 🌟 Lấy điều kiện lọc từ URL

            if (req.Phan_quyen !== 'Bac_si' && req.Phan_quyen !== 'Admin') {
                return res.status(403).json({ succeeded: false, message: "Truy cập bị từ chối." });
            }

            // Truyền status và date xuống Model
            const data = await AppointmentModel.getAllDoctorAppointments(userID, status, date);

            return res.status(200).json({ succeeded: true, message: "Lấy danh sách thành công", data: data });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // Lấy chi tiết ca khám hiển thị lên màn hình Chi tiết Bác sĩ
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

    // API lấy lịch sử bệnh án của bệnh nhân trong ca khám hiện tại
    static async getMedicalHistory(req, res) {
        try {
            const { id } = req.params; // ID của ca khám hiện tại bác sĩ đang xem

            // 1. Lấy thông tin ca khám hiện tại để biết đang khám cho ai (Bản thân hay Người thân)
            const currentAppt = await AppointmentModel.getDoctorAppointmentDetail(id);
            if (!currentAppt) {
                return res.status(404).json({ succeeded: false, message: "Không tìm thấy ca khám." });
            }

            // 2. Lấy danh sách lịch sử dựa trên ID bệnh nhân và ID người thân
            // Cần lấy Ma_benh_nhan từ DB.
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

    // Api Bác sĩ báo khám xong và kê đơn
    static async completeWithPrescription(req, res) {
        try {
            const appointmentID = req.params.id;
            const userID = req.Ma_nguoi_dung;
            const { chuanDoan, ngayTaiKham, danhSachThuoc } = req.body;

            if (!appointmentID) return res.status(400).json({ succeeded: false, message: 'Thiếu ID lịch hẹn' });
            if (!chuanDoan) return res.status(400).json({ succeeded: false, message: 'Vui lòng nhập chẩn đoán bệnh lý.' });

            // Gọi hàm Model xử lý tất cả
            await AppointmentModel.completeAndPrescribe(appointmentID, userID, { chuanDoan, ngayTaiKham, danhSachThuoc });

            // Gửi thông báo xin đánh giá cho bệnh nhân
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

    // API Lấy chi tiết đơn thuốc để xem lại
    static async getPrescription(req, res) {
        try {
            const { id } = req.params; // Ma_lich_hen
            if (!id) return res.status(400).json({ succeeded: false, message: "Thiếu mã lịch hẹn." });

            const data = await AppointmentModel.getPrescriptionByAppointmentId(id);
            
            if (!data) return res.status(404).json({ succeeded: false, message: "Chưa có đơn thuốc cho ca khám này." });

            return res.status(200).json({ succeeded: true, data: data });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // API Lấy trạng thái hoạt động hiện tại của bác sĩ
    static async getDoctorStatus(req, res) {
        try {
            const userID = req.Ma_nguoi_dung;
            if (req.Phan_quyen !== 'Bac_si' && req.Phan_quyen !== 'Admin') {
                return res.status(403).json({ succeeded: false, message: "Truy cập bị từ chối." });
            }
            const status = await AppointmentModel.getDoctorStatus(userID);
            return res.status(200).json({ succeeded: true, data: { status } });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // API Cập nhật trạng thái rảnh/bận của bác sĩ
    static async toggleDoctorStatus(req, res) {
        try {
            const userID = req.Ma_nguoi_dung;
            const { status } = req.body; // Cần gửi 'active' hoặc 'suspended'

            if (req.Phan_quyen !== 'Bac_si' && req.Phan_quyen !== 'Admin') {
                return res.status(403).json({ succeeded: false, message: "Truy cập bị từ chối." });
            }
            if (!['active', 'suspended'].includes(status)) {
                return res.status(400).json({ succeeded: false, message: "Trạng thái không hợp lệ." });
            }

            await AppointmentModel.updateDoctorStatus(userID, status);
            return res.status(200).json({ 
                succeeded: true, 
                message: status === 'active' ? "Đã chuyển sang chế độ Sẵn sàng khám." : "Đã chuyển sang chế độ Bận." 
            });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }
}