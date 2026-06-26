import nodeCron from 'node-cron';
import { execute } from '../config/db.js';
import sendNotification from './notificationHelper.js';

const cron = nodeCron;

// Thiết lập lịch chạy: Quét định kỳ mỗi phút một lần (* * * * *)
cron.schedule('* * * * *', async () => {
    try {
        // 1. Quét tìm các lịch hẹn đã xác nhận (confirmed) sắp diễn ra trong vòng 15 phút tới
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

                // 2. Dùng toán tử LIKE kiểm tra xem đã từng tạo thông báo nhắc nhở cho Ma_booking này chưa
                const checkNotificationQuery = `
                    SELECT * FROM thong_bao 
                    WHERE Ma_nguoi_dung = ? 
                      AND Loai = 'Nhắc nhở lịch hẹn' 
                      AND Noi_dung LIKE ?
                `;
                
                // Gắn chuỗi định danh duy nhất dựa trên Ma_booking vào mẫu tìm kiếm
                const searchPattern = `%[Mã đặt lịch: ${Ma_booking}]%`;
                const [existingNotifications] = await execute(checkNotificationQuery, [Ma_nguoi_dung, searchPattern]);

                // Nếu TRỐNG (chưa từng gửi thông báo cho lịch hẹn này), tiến hành gửi
                if (!existingNotifications || existingNotifications.length === 0) {
                    
                    // Định dạng thời gian hiển thị Giờ:Phút
                    const formatTime = new Date(Thoi_gian_Bdau).toLocaleTimeString('vi-VN', {
                        hour: '2-digit',
                        minute: '2-digit',
                        timeZone: 'Asia/Ho_Chi_Minh'
                    });

                    const loai = "Nhắc nhở lịch hẹn";
                    // 💡 LƯU Ý: Phải giữ nguyên cấu trúc chữ "[Mã đặt lịch: ...]" trong chuỗi nội dung này
                    const noiDung = `Lịch hẹn khám bệnh [Mã đặt lịch: ${Ma_booking}] của bạn sẽ bắt đầu sau 15 phút nữa (vào lúc ${formatTime}). Vui lòng chuẩn bị sẵn sàng!`;

                    // 3. Thêm thông báo mới vào bảng thong_bao
                    // (Nếu DB thực tế của nhóm bạn có cột Trang_thai_doc thì thêm vào, không thì giữ nguyên như cấu trúc SQL gốc)
                    /*const insertNotificationQuery = `
                        INSERT INTO thong_bao (Ma_nguoi_dung, Loai, Noi_dung, Ngay_gui, Trang_thai_doc)
                        VALUES (?, ?, ?, NOW(), 0)
                    `;
                    await execute(insertNotificationQuery, [Ma_nguoi_dung, loai, noiDung]);*/
                    const io = req.app.get('io');
                    await sendNotification(Ma_nguoi_dung,loai,noiDung, io);

                    console.log(`[Cron Job] Đã tạo nhắc nhở thành công cho lịch hẹn: ${Ma_booking}`);
                }
            }
        }
    } catch (error) {
        console.error("Lỗi tiến trình tự động nhắc nhở 15 phút:", error.message);
    }
});