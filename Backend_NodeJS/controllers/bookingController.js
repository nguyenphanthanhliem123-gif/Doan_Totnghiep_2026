import bookingModel from '../models/bookingModel.js';
import { beginTransaction, commitTransaction, rollbackTransaction } from "../config/db.js";

export default class bookingController {
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

    // ✨ ĐÃ SỬA CHỮA TOÀN DIỆN: Bọc toàn bộ quy trình đặt lịch vào một DB Transaction duy nhất + Khóa hàng chống trùng
    static async createBooking(req, res) {
        // Khởi tạo Transaction ngay lập tức từ đầu quy trình
        let conn = await beginTransaction();
        try {
            const { Ma_bac_si, Ma_benh_nhan, Ma_nguoi_than, Ma_dich_vu, Ma_khung_gio, Hinh_thuc, Trieu_chung } = req.body;

            // 1. Kiểm tra dữ liệu đầu vào cơ bản
            if (!Array.isArray(Ma_dich_vu) || Ma_dich_vu.length === 0) {
                await rollbackTransaction(conn);
                return res.status(400).json({ succeeded: false, message: "Vui lòng chọn ít nhất 1 dịch vụ!" });
            }

            const maBenhNhanThat = await bookingModel.getPatientIdByUserId(Ma_benh_nhan);
            if (!maBenhNhanThat) {
                await rollbackTransaction(conn);
                return res.status(400).json({ succeeded: false, message: "Chưa có hồ sơ bệnh nhân!" });
            }

            // Kiểm tra số điện thoại người dùng từ DB qua connection của Transaction hiện tại
            const [userInfo] = await conn.execute(`SELECT Dien_thoai FROM nguoi_dung WHERE Ma_nguoi_dung = ?`, [Ma_benh_nhan]);
            if (!userInfo || userInfo.length === 0 || !userInfo[0].Dien_thoai || userInfo[0].Dien_thoai.trim() === '') {
                await rollbackTransaction(conn);
                return res.status(400).json({ 
                    succeeded: false, 
                    message: "Vui lòng cập nhật số điện thoại trong phần Hồ sơ trước khi đặt lịch!" 
                });
            }

            // ✨ ĐÃ SỬA: Sử dụng cơ chế khóa hàng 'FOR UPDATE' để chặn đứng Race Condition
            // Bất kỳ luồng request đồng thời nào đến sau đều phải xếp hàng đợi luồng đầu tiên xử lý xong.
            const slot = await bookingModel.getSlotForUpdate(Ma_khung_gio, conn);
            if (!slot || slot.Trang_thai !== 'available') {
                await rollbackTransaction(conn);
                return res.status(400).json({ succeeded: false, message: "Khung giờ này vừa bị người khác đặt hoặc không khả dụng!" });
            }

            // Kiểm tra trùng lặp lịch hẹn thực tế trong bảng lịch hẹn
            const rows = await bookingModel.getSlotReal(Ma_khung_gio, conn);
            if (rows[0].count > 0) {
                await rollbackTransaction(conn);
                return res.status(400).json({ succeeded: false, message: "Khung giờ này đã tồn tại lịch đặt trước!" });
            }

            // 2. Tính toán tổng chi phí một cách an toàn trực tiếp từ bảng dịch vụ trong DB
            let Tong_tien = 0;
            const thongTinDichVu = [];
            for (const idDichVu of Ma_dich_vu) {
                const service = await bookingModel.getServicePrice(idDichVu, conn);
                if (service) {
                    Tong_tien += parseFloat(service.Gia_tien);
                    thongTinDichVu.push({ id: idDichVu, price: service.Gia_tien });
                }
            }

            if (thongTinDichVu.length === 0) {
                await rollbackTransaction(conn);
                return res.status(404).json({ succeeded: false, message: "Dịch vụ không hợp lệ." });
            }

            // 3. Xử lý logic mã hóa & sinh mã Booking
            const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
            const randomNum = Math.floor(1000 + Math.random() * 9000);
            const Ma_booking = `BK${dateStr}_${randomNum}`;
            
            let rawMethod = req.body.Phuong_thuc || req.body.paymentMethod || 'cash';
            let Phuong_thuc = rawMethod.toString().trim().toLowerCase();
            if (!['momo', 'cash', 'transfer', 'vnpay'].includes(Phuong_thuc)) Phuong_thuc = 'vnpay'; 

            let Ma_giao_dich = Phuong_thuc === 'cash' ? `TXN_${Ma_booking}` : null;

            // 4. Lưu dữ liệu vỏ lịch hẹn (Lên lịch cha) - Truyền tham số kết nối 'conn' liên thông
            const bookingData = { Ma_booking, Ma_bac_si, Ma_benh_nhan: maBenhNhanThat, Ma_nguoi_than, Ma_khung_gio, Hinh_thuc, Trieu_chung, Tong_tien };
            const insertId = await bookingModel.createAppointment(bookingData, conn);

            // 5. Lưu chi tiết lịch hẹn vào bảng chi_tiet_lich_hen đầy đủ
            for (const item of thongTinDichVu) {
                await bookingModel.createAppointmentDetail({
                    Ma_lich_hen: insertId,
                    Ma_dich_vu: item.id,
                    Gia_tien: item.price
                }, conn);
            }

            // 6. Lưu bản ghi hóa đơn thanh toán & chuyển trạng thái ô giờ khám sang 'booked'
            const paymentData = { Ma_lich_hen: insertId, Phuong_thuc, Trang_thai_thanh_toan: 'pending', Ma_giao_dich, Tong_tien };
            await bookingModel.createPayment(paymentData, conn);
            await bookingModel.updateSlotStatus(Ma_khung_gio, 'booked', conn);

            // Nếu mọi thao tác đều trơn tru, tiến hành ghi vĩnh viễn vào hệ thống database
            await commitTransaction(conn);

            return res.status(200).json({
                succeeded: true, 
                message: "Đặt lịch khám thành công!",
                data: { Ma_lich_hen: insertId, Ma_booking: Ma_booking, Tong_tien: Tong_tien, Phuong_thuc: Phuong_thuc, Ma_khung_gio: Ma_khung_gio }
            });

        } catch (error) {
            // Trường hợp phát sinh lỗi đột xuất, hoàn trả nguyên vẹn tình trạng ô lịch khám ban đầu
            await rollbackTransaction(conn);
            return res.status(500).json({ succeeded: false, message: "Lỗi hệ thống trong tiến trình đặt lịch: " + error.message });
        }
    }

    static async getDoctorSchedule(req, res) {
        try {
            const date = req.query.q || '';
            const doctorSchedule = await bookingModel.getDoctorSchedule(date);
            return res.status(200).json({ succeeded: true, schedule: doctorSchedule });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // Hàm Hủy lịch tự động
    static async cancelUnpaidBooking(req, res) {
        try {
            const { bookingCode } = req.body;
            const { execute } = await import('../config/db.js');
            
            const [rows] = await execute(`SELECT Ma_lich_hen, Ma_khung_gio FROM lich_hen WHERE Ma_booking = ?`, [bookingCode]);
            if (rows.length > 0) {
                const maLichHen = rows[0].Ma_lich_hen;
                const maKhungGio = rows[0].Ma_khung_gio;

                await execute(`UPDATE lich_hen SET Trang_thai_lich_hen = 'cancelled' WHERE Ma_booking = ?`, [bookingCode]);
                await execute(
                    `INSERT INTO lich_su_trang_thai_lich_hen (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Ly_do_thay_doi, Nguoi_thay_doi) 
                     VALUES (?, 'pending', 'cancelled', 'Khách hàng hủy thanh toán trực tuyến hoặc chủ động hủy tiến trình đợi', 'patient')`,
                    [maLichHen]
                );
                await execute(`UPDATE khung_gio_kham SET Trang_thai = 'available' WHERE Ma_khung_gio = ?`, [maKhungGio]);
                await execute(`UPDATE thanh_toan SET Trang_thai_thanh_toan = 'failed' WHERE Ma_lich_hen = ?`, [maLichHen]);
            }
            return res.status(200).json({ succeeded: true, message: "Đã hủy lịch chưa thanh toán và nhả slot." });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }
}