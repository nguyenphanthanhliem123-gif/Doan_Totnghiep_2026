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

    // Tạo lịch hẹn mới (Hỗ trợ nhiều dịch vụ)
    static async createBooking(req, res) {
        try {
            const { Ma_bac_si, Ma_benh_nhan, Ma_nguoi_than, Ma_dich_vu, Ma_khung_gio, Hinh_thuc, Trieu_chung } = req.body;

            // 1. Kiểm tra đầu vào (Bây giờ Ma_dich_vu phải là 1 mảng [Array])
            if (!Array.isArray(Ma_dich_vu) || Ma_dich_vu.length === 0) {
                return res.status(400).json({ succeeded: false, message: "Vui lòng chọn ít nhất 1 dịch vụ!" });
            }

            const maBenhNhanThat = await bookingModel.getPatientIdByUserId(Ma_benh_nhan);
            if (!maBenhNhanThat) return res.status(400).json({ succeeded: false, message: "Chưa có hồ sơ bệnh nhân!" });

            // Bắt buộc kiểm tra có sđt trong bảng nguoi_dung trước khi đặt lịch
            const { execute } = await import('../config/db.js'); 
            const [userInfo] = await execute(`SELECT Dien_thoai FROM nguoi_dung WHERE Ma_nguoi_dung = ?`, [Ma_benh_nhan]);
            
            if (!userInfo[0].Dien_thoai || userInfo[0].Dien_thoai.trim() === '') {
                return res.status(400).json({ 
                    succeeded: false, 
                    message: "Vui lòng cập nhật số điện thoại trong phần Hồ sơ trước khi đặt lịch!" 
                });
            }

            const rows = await bookingModel.getSlotReal(Ma_khung_gio);
            if (rows[0].count > 0) return res.status(400).json({ succeeded: false, message: "Khung giờ này vừa có người đặt!" });

            const slot = await bookingModel.getSlot(Ma_khung_gio);
            if (!slot || slot.Trang_thai !== 'available') return res.status(400).json({ succeeded: false, message: "Khung giờ không khả dụng." });

            // 2. Tính tổng tiền dựa trên các dịch vụ được chọn
            let Tong_tien = 0;
            const thongTinDichVu = [];
            for (const idDichVu of Ma_dich_vu) {
                const service = await bookingModel.getServicePrice(idDichVu);
                if (service) {
                    Tong_tien += parseFloat(service.Gia_tien);
                    thongTinDichVu.push({ id: idDichVu, price: service.Gia_tien });
                }
            }

            if (thongTinDichVu.length === 0) return res.status(404).json({ succeeded: false, message: "Dịch vụ không hợp lệ." });

            // 3. Xử lý thanh toán & sinh mã Booking
            const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
            const randomNum = Math.floor(1000 + Math.random() * 9000);
            const Ma_booking = `BK${dateStr}_${randomNum}`;
            
            let rawMethod = req.body.Phuong_thuc || req.body.paymentMethod || 'cash';
            let Phuong_thuc = rawMethod.toString().trim().toLowerCase();
            if (!['momo', 'cash', 'transfer', 'vnpay'].includes(Phuong_thuc)) Phuong_thuc = 'vnpay'; 

            let Ma_giao_dich = Phuong_thuc === 'cash' ? `TXN_${Ma_booking}` : null;

            // 4. Lưu vào bảng lich_hen (Vỏ)
            const bookingData = { Ma_booking, Ma_bac_si, Ma_benh_nhan: maBenhNhanThat, Ma_nguoi_than, Ma_khung_gio, Hinh_thuc, Trieu_chung, Tong_tien };
            const insertId = await bookingModel.createAppointment(bookingData);

            // 5. Lưu chi tiết lịch hẹn vào bảng chi_tiet_lich_hen
            for (const item of thongTinDichVu) {
                await bookingModel.createAppointmentDetail({
                    Ma_lich_hen: insertId,
                    Ma_dich_vu: item.id,
                    Gia_tien: item.price
                });
            }

            // 6. Lưu thanh toán & Khóa khung giờ
            const paymentData = { Ma_lich_hen: insertId, Phuong_thuc, Trang_thai_thanh_toan: 'pending', Ma_giao_dich, Tong_tien };
            await bookingModel.createPayment(paymentData);
            await bookingModel.updateSlotStatus(Ma_khung_gio, 'booked');

            return res.status(200).json({
                succeeded: true, message: "Đặt lịch khám thành công!",
                data: { Ma_lich_hen: insertId, Ma_booking: Ma_booking, Tong_tien: Tong_tien, Phuong_thuc: Phuong_thuc, Ma_khung_gio: Ma_khung_gio }
            });

        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // API lấy lịch làm việc của bác sĩ theo ngày
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