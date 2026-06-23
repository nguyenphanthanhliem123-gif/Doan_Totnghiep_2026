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

    // Hủy lịch hẹn với điều kiện chặn hủy trước 2 giờ
    static async cancel(req, res) {
        try {
            const appointmentID = req.params.id;

            const result = await AppointmentModel.cancelAppointment(appointmentID);

            if (!result.success) {
                return res.status(400).json({ succeeded: false, message: result.message });
            }

            const info = await AppointmentModel.getAppointmentForRefund(appointmentID);
                
            // Chuẩn hóa: Chỉ xử lý hoàn tiền nếu trạng thái hiện tại là 'paid'
            if (info && info.Trang_thai_thanh_toan === 'paid' && info.Ma_giao_dich) {
                // Kiểm tra chính sách hủy trước 24 giờ
                const gioKham = new Date(info.Thoi_gian_Bdau);
                const hienTai = new Date();
                const khoangCachGio = (gioKham - hienTai) / (1000 * 60 * 60);

                if (khoangCachGio >= 24) {
                    const dataHoanTien = {
                        maBooking: info.Ma_booking,
                        maGiaoDich: info.Ma_giao_dich,
                        soTien: info.Tong_tien,
                        ngayThanhToan: info.Thoi_diem_thanh_toan 
                    };

                    // 🚀 CHẠY BẤT ĐỒNG BỘ (BACKGROUND TASK)
                    VNPayServices.xulyHoanTienVNPay(dataHoanTien)
                        .then(async (isSuccess) => {
                            if (isSuccess) {
                                await paymentModel.updateStatus(info.Ma_booking, 'refunded');
                                console.log(`[Job Hoàn Tiền] Thành công -> Chuyển thành 'refunded' cho Booking: ${info.Ma_booking}`);
                            } else {
                                await paymentModel.updateStatus(info.Ma_booking, 'failed');
                                console.log(`[Job Hoàn Tiền] Thất bại từ VNPay -> Chuyển thành 'failed' cho Booking: ${info.Ma_booking}`);
                            }
                        })
                        .catch(err => console.error("[Job Hoàn Tiền] Lỗi Exception nghiêm trọng:", err));
                } else {
                    console.log(`[Chính sách] Booking ${info.Ma_booking} hủy sát giờ, không hoàn tiền.`);
                }
            }

            const appointmentDetail = await AppointmentModel.getAppointmentDetails(appointmentID);

            // Gửi thông báo báo cho BÁC SĨ (Kiểm tra xem biến Ma_nguoi_dung_bac_si có lấy từ SQL ra chưa)
            if (appointmentDetail && appointmentDetail.Ma_nguoi_dung_bac_si) {
                await sendNotification(
                    appointmentDetail.Ma_nguoi_dung_bac_si,
                    'Hủy lịch hẹn',
                    'Lịch hẹn mã ' + appointmentDetail.Ma_booking + ' của bạn với bệnh nhân ' + appointmentDetail.Ten_nguoi_kham + ' đã bị hủy.'
                );
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
            const { newSlotId } = req.body; 

            if (!newSlotId) return res.status(400).json({ succeeded: false, message: "Thiếu mã khung giờ mới." });

            const bookingId = await appointmentModel.getAppointmentDetails(appointmentID);

            const result = await appointmentModel.rescheduleAppointment(appointmentID, newSlotId);

            if (!result.success) {
                return res.status(400).json({ succeeded: false, message: result.message });
            }
            
            await sendNotification(
                bookingId.Ma_nguoi_dung_bac_si,
                'Đổi lịch',
                'Lịch hẹn ' + bookingId.Ma_booking + ' đã được dời sang thời gian khác.'
            );

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

    // Cập nhật trạng thái lịch hẹn (Xác nhận hoặc Hủy)
    static async updateStatus(req, res) {
        try {
            const appointmentID = req.params.id;
            const { action } = req.body;
            const userID = req.Ma_nguoi_dung;

            if (!action || !['confirm', 'reject'].includes(action)) {
                return res.status(400).json({ succeeded: false, message: "Hành động không hợp lệ." });
            }

            const status = action === 'confirm' ? 'confirmed' : 'cancelled';

            // 1. Tiến hành cập nhật trạng thái vào bảng lich_hen TRƯỚC
            const result = await AppointmentModel.updateAppointmentStatus(appointmentID, status, userID);

            if (!result.success) {
                return res.status(400).json({ succeeded: false, message: result.message });
            }

            // 2. LOGIC XỬ LÝ DÒNG TIỀN KHI HỦY LỊCH (REJECT)
            if (action === 'reject') {
                const info = await AppointmentModel.getAppointmentForRefund(appointmentID);
                if (info && info.Trang_thai_thanh_toan === 'paid' && info.Ma_giao_dich) {
                    const gioKham = new Date(info.Thoi_gian_Bdau);
                    const hienTai = new Date();
                    if ((gioKham - hienTai) / (1000 * 60 * 60) >= 24) {
                        const dataHoanTien = {
                            maBooking: info.Ma_booking, maGiaoDich: info.Ma_giao_dich,
                            soTien: info.Tong_tien, ngayThanhToan: info.Thoi_diem_thanh_toan 
                        };
                        VNPayServices.xulyHoanTienVNPay(dataHoanTien).then(async (isSuccess) => {
                            if (isSuccess) await paymentModel.updateStatus(info.Ma_booking, 'refunded');
                            else await paymentModel.updateStatus(info.Ma_booking, 'refund_fail');
                        }).catch(err => console.error("[Job Hoàn Tiền] Lỗi Exception:", err));
                    }
                }
            }

            // 3. Xử lý Gửi Thông báo & Email cho bệnh nhân
            const appointmentDetail = await AppointmentModel.getAppointmentDetails(appointmentID);

            if (appointmentDetail && appointmentDetail.Ma_nguoi_dung) {
                if (status === 'confirmed') {
                    await sendNotification(
                        appointmentDetail.Ma_nguoi_dung,
                        'Xác nhận lịch hẹn',
                        'Lịch hẹn mã ' + appointmentDetail.Ma_booking + ' của bạn với ' + appointmentDetail.Ten_bac_si + ' đã được xác nhận.'
                    );

                    // Chỉ gửi mail nếu bệnh nhân có cấu hình Email
                    if (appointmentDetail.Email) {
                        const dateTime = new Date(appointmentDetail.Thoi_gian_Bdau);
                        const thongTinEmail = {
                            maBooking: appointmentDetail.Ma_booking,
                            tenBacSi: appointmentDetail.Ten_bac_si,
                            ngayKham: dateTime.toLocaleDateString('vi-VN'),
                            gioKham: dateTime.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }),
                            diaChi: appointmentDetail.Dia_chi_phong_kham
                        };
                        EmailService.sendBookingConfirmationEmail(appointmentDetail.Email, thongTinEmail).catch(err => console.log("Lỗi gửi mail ngầm"));
                    }
                } else {
                    await sendNotification(
                        appointmentDetail.Ma_nguoi_dung,
                        'Từ chối lịch hẹn',
                        'Lịch hẹn mã ' + appointmentDetail.Ma_booking + ' của bạn với ' + appointmentDetail.Ten_bac_si + ' đã bị từ chối.'
                    );
                }
            }

            return res.status(200).json({ 
                succeeded: true, 
                message: result.message + (action === 'reject' ? " (Hệ thống đang tự động xử lý hoàn tiền ngầm nếu đủ điều kiện)." : "")
            });
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
                await sendNotification(
                    appointmentDetail.Ma_nguoi_dung,
                    'Đánh giá', 
                    '[Mã lịch hẹn ' + appointmentDetail.Ma_booking + '][ID ' + appointmentID + '] Vui lòng cho biết đánh giá của bạn về bác sĩ ' + appointmentDetail.Ten_bac_si
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

    // API Lấy toàn bộ danh sách lịch hẹn của Bác sĩ
    static async getAllDoctorList(req, res) {
        try {
            const userID = req.Ma_nguoi_dung;

            if (req.Phan_quyen !== 'Bac_si' && req.Phan_quyen !== 'Admin') {
                return res.status(403).json({ succeeded: false, message: "Truy cập bị từ chối. Chỉ dành cho bác sĩ." });
            }

            const data = await AppointmentModel.getAllDoctorAppointments(userID);

            return res.status(200).json({ succeeded: true, message: "Lấy danh sách lịch hẹn thành công", data: data });
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
                await sendNotification(
                    appointmentDetail.Ma_nguoi_dung,
                    'Đánh giá ca khám', 
                    '[Mã lịch hẹn ' + appointmentDetail.Ma_booking + '] Vui lòng cho biết đánh giá của bạn về bác sĩ ' + appointmentDetail.Ten_bac_si
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
}