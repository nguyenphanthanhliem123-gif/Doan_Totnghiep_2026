import nodeCron from 'node-cron';
import { execute } from '../config/db.js';
import sendNotification from './notificationHelper.js';

const cron = nodeCron;

export const startReminderCron = (io) => {

    // =========================================================================
    // TIẾN TRÌNH 1: Nhắc nhở lịch hẹn khám sắp diễn ra (Chạy mỗi phút)
    // =========================================================================
    cron.schedule('* * * * *', async () => {
        console.log("⏳ [Hệ thống] Các tiến trình tự động nhắc nhở đã được kích hoạt.");
        try {
            const findQuery = `
                SELECT lh.Ma_lich_hen, bn.Ma_nguoi_dung, kg.Thoi_gian_Bdau, lh.Ma_booking
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                WHERE lh.Trang_thai_lich_hen = 'confirmed'
                  AND kg.Thoi_gian_Bdau <= NOW() + INTERVAL 15 MINUTE
                  AND kg.Thoi_gian_Bdau > NOW()
            `;
            
            const [appointments] = await execute(findQuery);

            if (appointments && appointments.length > 0) {
                for (const appointment of appointments) {
                    const { Ma_nguoi_dung, Ma_booking, Thoi_gian_Bdau } = appointment;

                    const checkNotificationQuery = `
                        SELECT * FROM thong_bao 
                        WHERE Ma_nguoi_dung = ? 
                          AND Loai = 'Nhắc nhở lịch hẹn' 
                          AND Noi_dung LIKE ?
                    `;
                    
                    const searchPattern = `%[Mã đặt lịch: ${Ma_booking}]%`;
                    const [existingNotifications] = await execute(checkNotificationQuery, [Ma_nguoi_dung, searchPattern]);

                    if (!existingNotifications || existingNotifications.length === 0) {
                        const formatTime = new Date(Thoi_gian_Bdau).toLocaleTimeString('vi-VN', {
                            hour: '2-digit',
                            minute: '2-digit',
                            timeZone: 'Asia/Ho_Chi_Minh'
                        });

                        const loai = "Nhắc nhở lịch hẹn";
                        const noiDung = `Lịch hẹn khám bệnh [Mã đặt lịch: ${Ma_booking}] của bạn sẽ bắt đầu sau 15 phút nữa (vào lúc ${formatTime}). Vui lòng chuẩn bị sẵn sàng!`;

                        await sendNotification(Ma_nguoi_dung, loai, noiDung, io);
                        console.log(`[Cron Job] Đã bắn thông báo nhắc lịch hẹn: ${Ma_booking}`);
                    }
                }
            }
        } catch (error) {
            console.error("Lỗi tiến trình tự động nhắc nhở 15 phút: " + error.message);
        }
    });

    // =========================================================================
    // TIẾN TRÌNH 2: Tự động nhắc lịch tái khám trước 3 ngày và 1 ngày (Chạy vào 08:00 sáng mỗi ngày)
    // =========================================================================
    cron.schedule('0 8 * * *', async () => {
        try {
            console.log("⏳ [Cron Job] Bắt đầu quét danh sách người dùng sắp đến ngày tái khám...");

            // Dùng DATEDIFF(đến_ngày, từ_ngày) để tính chính xác số ngày còn lại
            const findQuery2 = `
                SELECT
                    dt.Ma_don_thuoc,
                    dt.Ngay_tai_kham, 
                    nd.Ma_nguoi_dung,
                    lh.Ma_booking,
                    DATEDIFF(DATE(dt.Ngay_tai_kham), CURDATE()) AS So_ngay_con_lai
                FROM don_thuoc dt
                JOIN lich_hen lh ON dt.Ma_lich_hen = lh.Ma_lich_hen
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                JOIN nguoi_dung nd ON bn.Ma_nguoi_dung = nd.Ma_nguoi_dung
                WHERE dt.Trang_thai = 1 
                  AND dt.Ngay_tai_kham IS NOT NULL
                  AND (DATEDIFF(DATE(dt.Ngay_tai_kham), CURDATE()) = 3 OR DATEDIFF(DATE(dt.Ngay_tai_kham), CURDATE()) = 1);
            `;

            const [rows] = await execute(findQuery2);

            if (rows && rows.length > 0) {
                for (const row of rows) {
                    // 💡 SỬA LỖI: Lấy dữ liệu từ từng dòng 'row' thay vì mảng 'rows'
                    const { Ngay_tai_kham, Ma_nguoi_dung, Ma_don_thuoc, Ma_booking, So_ngay_con_lai } = row;

                    // Tạo tên loại tương ứng động: "Nhắc tái khám trước 3 ngày" hoặc "Nhắc tái khám trước 1 ngày"
                    const loaiThongBao = `Nhắc tái khám trước ${So_ngay_con_lai} ngày`;

                    // Kiểm tra xem hôm nay hệ thống đã gửi thông báo loại này cho đơn thuốc này chưa
                    const checkNotificationQuery = `
                        SELECT * FROM thong_bao 
                        WHERE Ma_nguoi_dung = ? 
                          AND Loai = ? 
                          AND Noi_dung LIKE ?
                    `;
                    const searchPattern = `%[Mã đơn thuốc: ${Ma_don_thuoc}]%`;
                    const [existingNotifications] = await execute(checkNotificationQuery, [Ma_nguoi_dung, loaiThongBao, searchPattern]);

                    // Nếu chưa từng gửi thì tiến hành bắn Socket realtime và lưu DB
                    if (!existingNotifications || existingNotifications.length === 0) {
                        
                        const formatDate = new Date(Ngay_tai_kham).toLocaleDateString('vi-VN', {
                            day: '2-digit',
                            month: '2-digit',
                            year: 'numeric'
                        });

                        const noiDung = `Bạn có lịch hẹn tái khám [Mã đơn thuốc: ${Ma_don_thuoc}] từ lịch hẹn [Mã đặt lịch: ${Ma_booking}] vào ngày ${formatDate} (còn ${So_ngay_con_lai} ngày nữa). Vui lòng chuẩn bị thời gian!`;

                        // Bắn thông báo qua helper có tích hợp Socket.io
                        await sendNotification(Ma_nguoi_dung, loaiThongBao, noiDung, io);

                        console.log(`[Cron Job Tái Khám] Đã gửi thông báo nhắc trước ${So_ngay_con_lai} ngày thành công cho đơn thuốc: ${Ma_don_thuoc}`);
                    }
                }
            }
        } catch (error) {
            console.error("Lỗi tiến trình tự động nhắc lịch tái khám: " + error.message);
        }
    });
};