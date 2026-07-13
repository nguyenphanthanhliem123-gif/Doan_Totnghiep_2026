import cron from 'node-cron';
import { execute, beginTransaction, commitTransaction, rollbackTransaction } from '../config/db.js';

export const initBookingCleanJob = () => {
    // Cấu hình chạy định kỳ mỗi 1 phút một lần
    cron.schedule('* * * * *', async () => {
        console.log('>>> [CRON JOB]: Đang quét dọn lịch hẹn quá hạn thanh toán...');
        
        try {
            // 1. Tìm các lịch hẹn trực tuyến quá hạn 15 phút chưa thanh toán
            // LƯU Ý: Đảm bảo bảng 'lich_hen' của bạn có cột thời gian tạo (ví dụ: created_at)
            const findExpiredQuery = `
                SELECT lh.Ma_lich_hen, lh.Ma_khung_gio, lh.Ma_booking
                FROM lich_hen lh
                JOIN thanh_toan tt ON lh.Ma_lich_hen = tt.Ma_lich_hen
                WHERE lh.Trang_thai_lich_hen = 'pending'
                  AND tt.Phuong_thuc IN ('vnpay', 'momo')
                  AND tt.Trang_thai_thanh_toan = 'pending'
                  AND lh.Ngay_tao < NOW() - INTERVAL 15 MINUTE
            `;
            
            const [expiredBookings] = await execute(findExpiredQuery);
            
            if (expiredBookings.length === 0) return;

            console.log(`>>> Phát hiện ${expiredBookings.length} lịch hẹn hết hạn. Tiến hành hủy...`);

            // 2. Duyệt qua từng lịch hẹn hết hạn để hủy an toàn bằng Transaction
            for (const booking of expiredBookings) {
                let conn = await beginTransaction();
                try {
                    // Cập nhật trạng thái lịch hẹn sang cancelled
                    await conn.execute(
                        `UPDATE lich_hen SET Trang_thai_lich_hen = 'cancelled' WHERE Ma_lich_hen = ?`, 
                        [booking.Ma_lich_hen]
                    );

                    // Ghi nhận lịch sử hệ thống tự động hủy
                    await conn.execute(
                        `INSERT INTO lich_su_trang_thai_lich_hen (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Ly_do_thay_doi, Nguoi_thay_doi) 
                         VALUES (?, 'pending', 'cancelled', 'Hệ thống tự động hủy do quá hạn 15 phút chưa thanh toán', 'system')`,
                        [booking.Ma_lich_hen]
                    );

                    // Nhả slot khung giờ về trạng thái available để người khác chọn
                    await conn.execute(
                        `UPDATE khung_gio_kham SET Trang_thai = 'available' WHERE Ma_khung_gio = ?`, 
                        [booking.Ma_khung_gio]
                    );

                    // Đánh dấu hóa đơn thanh toán thất bại
                    await conn.execute(
                        `UPDATE thanh_toan SET Trang_thai_thanh_toan = 'failed' WHERE Ma_lich_hen = ?`, 
                        [booking.Ma_lich_hen]
                    );

                    await commitTransaction(conn);
                    console.log(`Successfully auto-cancelled: ${booking.Ma_booking}`);
                } catch (err) {
                    await rollbackTransaction(conn);
                    console.error(`Lỗi khi tự động hủy mã ${booking.Ma_booking}:`, err.message);
                }
            }
        } catch (error) {
            console.error('Lỗi tiến trình Cron Job:', error.message);
        }
    });
};