import bookingModel from '../models/bookingModel.js';

export default class bookingController {
    // Lấy danh sách các ngày còn slot trống
    static async getAvailableDates(req, res) {
        try {
            const { doctorId } = req.params;
            if (!doctorId) return res.status(400).json({ succeeded: false, message: "Thiếu mã bác sĩ" });

            const dates = await bookingModel.getAvailableDates(doctorId);
            return res.status(200).json({ succeeded: true, data: dates });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // Tạo lịch hẹn mới
    static async createBooking(req, res) {
        try {
            // Nhận data từ app Flutter gửi lên
            const { Ma_bac_si, Ma_benh_nhan, Ma_nguoi_than, Ma_dich_vu, Ma_khung_gio, Hinh_thuc, Trieu_chung } = req.body;

            // Validate dữ liệu đầu vào
            const maBenhNhanThat = await bookingModel.getPatientIdByUserId(Ma_benh_nhan);
            if (!maBenhNhanThat) {
                return res.status(400).json({ succeeded: false, message: "Tài khoản của bạn chưa có hồ sơ bệnh nhân!" });
            }

            const rows = await bookingModel.getSlotReal(Ma_khung_gio);
            if (rows[0].count > 0) {
                return res.status(400).json({ 
                    succeeded: false, 
                    message: "Rất tiếc, khung giờ này vừa có người khác đặt mất rồi!" 
                });
            }

            // 1. Kiểm tra slot khám có còn trống không?
            const slot = await bookingModel.getSlot(Ma_khung_gio);
            if (!slot) return res.status(404).json({ succeeded: false, message: "Không tìm thấy khung giờ này." });
            if (slot.Trang_thai !== 'available') {
                return res.status(400).json({ succeeded: false, message: "Rất tiếc, khung giờ này vừa có người đặt. Vui lòng chọn giờ khác!" });
            }

            // 2. Lấy giá tiền chuẩn từ bảng dich_vu
            const service = await bookingModel.getServicePrice(Ma_dich_vu);
            if (!service) return res.status(404).json({ succeeded: false, message: "Dịch vụ không tồn tại." });
            const Tong_tien = service.Gia_tien;

            // 3. Tự động sinh mã Booking chuyên nghiệp (VD: BK20260614_8524)
            const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
            const randomNum = Math.floor(1000 + Math.random() * 9000);
            const Ma_booking = `BK${dateStr}_${randomNum}`;
            const Phuong_thuc = req.body.Phuong_thuc || 'cash';

            // 4. Ghi vào bảng lich_hen
            const bookingData = {
                Ma_booking, Ma_bac_si, Ma_benh_nhan: maBenhNhanThat, Ma_nguoi_than, Ma_dich_vu, Ma_khung_gio, Hinh_thuc, Trieu_chung, Tong_tien
            };
            const insertId = await bookingModel.createAppointment(bookingData);

            // 5. Ghi vào bảng thanh_toan
            const paymentData = {
                Ma_lich_hen: insertId, // Lấy ID của lịch hẹn vừa tạo
                Phuong_thuc: Phuong_thuc,
                Trang_thai_thanh_toan: 'pending', // Mặc định là pending, nếu quét QR xong mới update thành 'paid'
                Ma_giao_dich: `TXN_${Ma_booking}`, // Sinh mã giao dịch tự động
                Tong_tien: Tong_tien
            };
            await bookingModel.createPayment(paymentData);

            // 6. Cập nhật trạng thái khung giờ thành 'booked' để người sau không đặt trùng được nữa
            await bookingModel.updateSlotStatus(Ma_khung_gio, 'booked');

            // Trả kết quả thành công về cho Flutter
            return res.status(200).json({
                succeeded: true,
                message: "Đặt lịch khám thành công!",
                data: {
                    Ma_lich_hen: insertId,
                    Ma_booking: Ma_booking,
                    Tong_tien: Tong_tien,
                    Phuong_thuc: Phuong_thuc
                }
            });

        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    static async getDoctorSchedule(req,res){
        try{
            const date = req.query.q || '';

            const doctorSchedule = await bookingModel.getDoctorSchedule(date);

            return  res.status(200).json({
                succeeded: true,
                schedule: doctorSchedule
            });
        }
        catch(error){
            return res.status(500).json({
                succeeded: false,
                message: error.message
            });
        }
    }
}