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

    static async createBooking(req, res) {
        let conn = await beginTransaction();
        try {
            const Ma_nguoi_dung = req.Ma_nguoi_dung; // Lấy từ Token bảo mật
            const { Ma_bac_si, Ma_benh_nhan, Ma_nguoi_than, Ma_dich_vu, Ma_khung_gio, Hinh_thuc, Trieu_chung } = req.body;

            // 1. Kiểm tra mảng dịch vụ
            if (!Array.isArray(Ma_dich_vu) || Ma_dich_vu.length === 0) {
                await rollbackTransaction(conn);
                return res.status(400).json({ succeeded: false, message: "Vui lòng chọn ít nhất 1 dịch vụ!" });
            }

            // Kiểm tra xem mã người thân gửi lên có thực sự thuộc về user này không
            const maBenhNhanThat = await bookingModel.checkPatienID(Ma_benh_nhan, Ma_nguoi_than, conn);
            if (!maBenhNhanThat) {
                await rollbackTransaction(conn);
                return res.status(400).json({ 
                    succeeded: false, 
                    message: "Hồ sơ bệnh nhân không hợp lệ hoặc bạn đang cố truy cập trái phép hồ sơ người khác!" 
                });
            }

            // 2. Kiểm tra số điện thoại (Giữ nguyên)
            const [userInfo] = await conn.execute(`SELECT Dien_thoai FROM nguoi_dung WHERE Ma_nguoi_dung = ?`, [Ma_nguoi_dung]);
            if (!userInfo || userInfo.length === 0 || !userInfo[0].Dien_thoai || userInfo[0].Dien_thoai.trim() === '') {
                await rollbackTransaction(conn);
                return res.status(400).json({ succeeded: false, message: "Vui lòng cập nhật số điện thoại trước khi đặt lịch!" });
            }

            // 3. Cơ chế khóa hàng chặn Race Condition
            const slot = await bookingModel.getSlotForUpdate(Ma_khung_gio, conn);
            
            if (!slot) {
                await rollbackTransaction(conn);
                return res.status(404).json({ succeeded: false, message: "Không tìm thấy khung giờ này." });
            }

            if (slot.Trang_thai !== 'available') {
                await rollbackTransaction(conn);
                return res.status(400).json({ succeeded: false, message: "Khung giờ này vừa có người nhanh tay hơn đặt trước mất rồi! Vui lòng chọn lại." });
            }

            // Chặn đặt lịch quá khứ qua API
            const slotTime = new Date(slot.Thoi_gian_Bdau);
            const now = new Date();
            if (slotTime < now) {
                await rollbackTransaction(conn);
                return res.status(400).json({ succeeded: false, message: "Không thể đặt lịch cho khung giờ trong quá khứ." });
            }

            // Chặn đặt lịch nếu Bác sĩ đang bị đình chỉ
            if (slot.Trang_thai_hoat_dong !== 'active') {
                await rollbackTransaction(conn);
                return res.status(400).json({ succeeded: false, message: "Bác sĩ này hiện đang tạm ngưng nhận bệnh nhân. Vui lòng chọn bác sĩ khác." });
            }

            // Kiểm tra trùng lặp lịch hẹn thực tế trong bảng lịch hẹn
            const rows = await bookingModel.getSlotReal(Ma_khung_gio, conn);
            if (rows[0].count > 0) {
                await rollbackTransaction(conn);
                return res.status(400).json({ succeeded: false, message: "Khung giờ này đã tồn tại lịch đặt trước!" });
            }

            // 4. Kiểm tra trùng lịch cá nhân (Chống giao thoa giờ)
            const isConflict = await bookingModel.checkPatientConflict(maBenhNhanThat, Ma_nguoi_than, Ma_khung_gio, conn);
            if (isConflict) {
                await rollbackTransaction(conn); 
                // Đổi câu thông báo cho chính xác và lịch sự hơn
                return res.status(400).json({ succeeded: false, message: "Rất tiếc, người khám này đã có một lịch hẹn khác bị trùng hoặc giao thoa thời gian!" });
            }

            // 5. Chặn Spam lịch (Tối đa 5 lịch/ngày TRÊN TOÀN TÀI KHOẢN)
            const todayStr = new Date().toISOString().slice(0, 10);
            
            // Truy ngược về Ma_nguoi_dung để đếm tổng lịch của cả Tài khoản (bao gồm tất cả người thân)
            const [spamRows] = await conn.execute(
                `SELECT COUNT(*) as total 
                 FROM lich_hen lh
                 JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                 WHERE bn.Ma_nguoi_dung = ? 
                 AND DATE(lh.Ngay_tao) = ? 
                 AND lh.Trang_thai_lich_hen IN ('pending', 'confirmed')`,
                [Ma_nguoi_dung, todayStr]
            );
            
            if (spamRows[0].total >= 5) {
                await rollbackTransaction(conn);
                return res.status(400).json({ succeeded: false, message: "Tài khoản của bạn đã đạt giới hạn đặt tối đa 5 lịch hẹn trong hôm nay!" });
            }

            // 6. Tính toán tổng chi phí dựa trên dịch vụ
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

            // 7. Xử lý chuẩn hóa phương thức thanh toán & sinh mã Booking
            const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
            const randomNum = Math.floor(1000 + Math.random() * 9000);
            const Ma_booking = `BK${dateStr}_${randomNum}`;
            
            let rawMethod = req.body.Phuong_thuc || req.body.paymentMethod || 'cash';
            let Phuong_thuc = rawMethod.toString().trim().toLowerCase();
            if (!['momo', 'cash', 'transfer', 'vnpay'].includes(Phuong_thuc)) Phuong_thuc = 'vnpay'; 

            let Ma_giao_dich = Phuong_thuc === 'cash' ? `TXN_${Ma_booking}` : null;

            // 8. Lưu dữ liệu tuần tự vào các bảng
            const bookingData = { Ma_booking, Ma_bac_si, Ma_benh_nhan: maBenhNhanThat, Ma_nguoi_than, Ma_khung_gio, Hinh_thuc, Trieu_chung, Tong_tien };
            const insertId = await bookingModel.createAppointment(bookingData, conn);

            for (const item of thongTinDichVu) {
                await bookingModel.createAppointmentDetail({
                    Ma_lich_hen: insertId,
                    Ma_dich_vu: item.id,
                    Gia_tien: item.price
                }, conn);
            }

            const paymentData = { Ma_lich_hen: insertId, Phuong_thuc, Trang_thai_thanh_toan: 'pending', Ma_giao_dich, Tong_tien };
            await bookingModel.createPayment(paymentData, conn);
            
            await bookingModel.updateSlotStatus(Ma_khung_gio, 'booked', conn);
        
            await commitTransaction(conn);

            return res.status(200).json({
                succeeded: true, 
                message: "Đặt lịch khám thành công!",
                data: { Ma_lich_hen: insertId, Ma_booking, Tong_tien, Phuong_thuc, Ma_khung_gio }
            });

        } catch (error) {
            await rollbackTransaction(conn);
            return res.status(500).json({ succeeded: false, message: "Lỗi hệ thống trong tiến trình đặt lịch: " + error.message });
        }
    }

    static async getDoctorSchedule(req, res) {
        try {
            // Hứng tham số ngày và ID bác sĩ từ URL
            const date = req.query.date || req.query.q || '';
            const doctorId = req.query.doctorId; 

            // Kiểm tra rỗng
            if (!doctorId || doctorId === 'null') {
                return res.status(400).json({ succeeded: false, message: "Thiếu mã bác sĩ để xem lịch." });
            }

            const doctorSchedule = await bookingModel.getDoctorSchedule(doctorId, date);
            
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