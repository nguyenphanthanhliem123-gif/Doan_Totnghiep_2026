import nodeCron from 'node-cron';
import { execute } from '../config/db.js';
import EmailService from '../services/emailService.js';
import sendNotification from './notificationHelper.js';

const cron = nodeCron;

export const startReminderCron24h = (io) =>{
    cron.schedule('0 * * * *', async () => {
        console.log("[Cron Job 24h] Bắt đầu quét lịch hẹn...");
        try {
            // 1. Quét tìm các lịch hẹn đã xác nhận (confirmed) sắp diễn ra trong vòng 24 giờ tới
            const findQuery = `
                SELECT lh.Ma_lich_hen, bn.Ma_nguoi_dung, kg.Thoi_gian_Bdau, lh.Ma_booking, 
                    nd.Email, bs_nd.Ten_nguoi_dung AS TenBacSi, pk.Vi_tri AS DiaChi
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                JOIN phong_kham pk ON kg.Ma_phong_kham = pk.Ma_phong_kham
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                JOIN nguoi_dung nd ON bn.Ma_nguoi_dung = nd.Ma_nguoi_dung
                JOIN bac_si bs ON lh.Ma_bac_si = bs.Ma_bac_si
                JOIN nguoi_dung bs_nd ON bs.Ma_nguoi_dung = bs_nd.Ma_nguoi_dung
                WHERE lh.Trang_thai_lich_hen = 'confirmed'
                AND kg.Thoi_gian_Bdau > NOW() 
                AND kg.Thoi_gian_Bdau <= NOW() + INTERVAL 24 HOUR
            `;
            
            const [appointments] = await execute(findQuery);

            if (appointments && appointments.length > 0) {
                for (const appointment of appointments) {
                    const { Ma_nguoi_dung, Ma_booking, Thoi_gian_Bdau, Email, TenBacSi, DiaChi } = appointment;

                    // 2. Dùng toán tử LIKE kiểm tra xem đã từng tạo thông báo nhắc 24h cho Ma_booking này chưa
                    const checkNotificationQuery = `
                        SELECT * FROM thong_bao 
                        WHERE Ma_nguoi_dung = ? 
                        AND Loai = 'Nhắc nhở lịch hẹn' 
                        AND Noi_dung LIKE ?
                    `;
                    
                    // Mẫu nhận diện duy nhất cho nhắc nhở 24h
                    const searchPattern = `%[Nhắc lịch 24h: ${Ma_booking}]%`;
                    const [existingNotifications] = await execute(checkNotificationQuery, [Ma_nguoi_dung, searchPattern]);

                    // Nếu TRỐNG (chưa từng gửi thông báo & email cho lịch hẹn này), tiến hành gửi
                    if (!existingNotifications || existingNotifications.length === 0) {
                        
                        const dateTime = new Date(Thoi_gian_Bdau);
                        const ngayKham = dateTime.toLocaleDateString('vi-VN');
                        const gioKham = dateTime.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit', timeZone: 'Asia/Ho_Chi_Minh' });

                        // -- GỬI EMAIL --
                        const thongTinEmail = {
                            maBooking: Ma_booking,
                            tenBacSi: TenBacSi,
                            ngayKham: ngayKham,
                            gioKham: gioKham,
                            diaChi: DiaChi
                        };
                        await EmailService.sendReminderEmail24h(Email, thongTinEmail);

                        // -- GHI VÀO DB ĐỂ ĐÁNH DẤU LÀ ĐÃ GỬI (TRÁNH LẶP) VÀ HIỂN THỊ LÊN APP --
                        const loai = "Nhắc nhở lịch hẹn";
                        const noiDung = `[Nhắc lịch 24h: ${Ma_booking}] Bạn có lịch hẹn khám với ${TenBacSi} vào lúc ${gioKham} ngày mai. Đừng quên nhé!`;

                        /*const insertNotificationQuery = `
                            INSERT INTO thong_bao (Ma_nguoi_dung, Loai, Noi_dung, Ngay_gui, Trang_thai_doc)
                            VALUES (?, ?, ?, NOW(), 0)
                        `;
                        await execute(insertNotificationQuery, [Ma_nguoi_dung, loai, noiDung]);*/
                        await sendNotification(Ma_nguoi_dung, loai, noiDung, io);
                    } 

                }
            }
            if(appointments) console.log(`[Tiến trình 24h] Có ${appointments.length} lịch trong 24 giờ sắp tới.`);
            else console.log(`[Tiến trình 24h] Lỗi không tìm thấy lịch hẹn.`);
        } catch (error) {
            console.error("[Cron Job 24h] Lỗi tiến trình tự động: " + error.message);
        }
    });
}