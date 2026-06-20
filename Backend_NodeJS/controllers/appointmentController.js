import AppointmentModel from "../models/AppointmentModel.js";
import paymentModel from "../models/paymentModel.js";
import VNPayServices from "../services/vnpayService.js";

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
                    // Giữ nguyên trạng thái 'paid' trong DB khi đang gọi sang VNPay
                    VNPayServices.xulyHoanTienVNPay(dataHoanTien)
                        .then(async (isSuccess) => {
                            if (isSuccess) {
                                // Hoàn tiền thành công -> Chuyển sang 'refunded'
                                await paymentModel.updateStatus(info.Ma_booking, 'refunded');
                                console.log(`[Job Hoàn Tiền] Thành công -> Chuyển thành 'refunded' cho Booking: ${info.Ma_booking}`);
                            } else {
                                // Hoàn tiền lỗi hệ thống -> Chuyển sang 'failed' để Admin đối soát
                                await paymentModel.updateStatus(info.Ma_booking, 'failed');
                                console.log(`[Job Hoàn Tiền] Thất bại từ VNPay -> Chuyển thành 'failed' cho Booking: ${info.Ma_booking}`);
                            }
                        })
                        .catch(err => console.error("[Job Hoàn Tiền] Lỗi Exception nghiêm trọng:", err));
                } else {
                    // Hủy sát giờ (< 24h) -> Không hoàn tiền -> Giữ nguyên trạng thái 'paid'
                    console.log(`[Chính sách] Booking ${info.Ma_booking} hủy sát giờ, không hoàn tiền.`);
                }
            }

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

            // 🌟 LOGIC XỬ LÝ DÒNG TIỀN KHI HỦY LỊCH (REJECT)
            if (action === 'reject') {
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
                        // Giữ nguyên trạng thái 'paid' trong DB khi đang gọi sang VNPay
                        VNPayServices.xulyHoanTienVNPay(dataHoanTien)
                            .then(async (isSuccess) => {
                                if (isSuccess) {
                                    // Hoàn tiền thành công -> Chuyển sang 'refunded'
                                    await paymentModel.updateStatus(info.Ma_booking, 'refunded');
                                    console.log(`[Job Hoàn Tiền] Thành công -> Chuyển thành 'refunded' cho Booking: ${info.Ma_booking}`);
                                } else {
                                    // Hoàn tiền lỗi hệ thống -> Chuyển sang 'failed' để Admin đối soát
                                    await paymentModel.updateStatus(info.Ma_booking, 'refund_fail');
                                    console.log(`[Job Hoàn Tiền] Thất bại từ VNPay -> Chuyển thành 'failed' cho Booking: ${info.Ma_booking}`);
                                }
                            })
                            .catch(err => console.error("[Job Hoàn Tiền] Lỗi Exception nghiêm trọng:", err));
                    } else {
                        // Hủy sát giờ (< 24h) -> Không hoàn tiền -> Giữ nguyên trạng thái 'paid'
                        console.log(`[Chính sách] Booking ${info.Ma_booking} hủy sát giờ, không hoàn tiền.`);
                    }
                }
            }

            // Tiến hành cập nhật trạng thái "cancelled" hoặc "confirmed" vào bảng lich_hen
            const result = await AppointmentModel.updateAppointmentStatus(appointmentID, status, userID);

            return res.status(200).json({ 
                succeeded: true, 
                message: result.message + (action === 'reject' ? " (Hệ thống đang tự động xử lý hoàn tiền ngầm nếu đủ điều kiện)." : "")
            });
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