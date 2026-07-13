import { execute } from "../config/db.js";

/**
 * Hàm gửi thông báo chung cho hệ thống
 * @param {number} maNguoiDung - ID người nhận
 * @param {string} loai - Loại thông báo ('Dat_lich', 'Huy_lich'...)
 * @param {string} noiDung - Nội dung chữ hiển thị
 */
async function sendNotification(maNguoiDung, loai, noiDung, io) {
    try {
        // 1. Lưu thông báo vào Database trước
        const sql = `INSERT INTO thong_bao (Ma_nguoi_dung, Loai, Noi_dung, Trang_thai_doc, Ngay_gui) VALUES (?, ?, ?, 0, NOW())`;
        const [result] = await execute(sql, [maNguoiDung, loai, noiDung]);

        // 2. Lấy FCM Token của người dùng từ Database
        const [user] = await execute(`SELECT fcm_token FROM nguoi_dung WHERE Ma_nguoi_dung = ?`, [maNguoiDung]);
        
        if (user.length > 0 && user[0].fcm_token) {
            // 3. Đẩy Push Notification qua Firebase (Hoạt động cả khi app bị tắt)
            const message = {
                notification: {
                    title: loai === 'Dat_lich' ? 'Đặt lịch thành công' : 'Thông báo hệ thống',
                    body: noiDung,
                },
                token: user[0].fcm_token
            };
            
            await admin.messaging().send(message);
            console.log(`Đã gửi FCM Push Notification cho User ${maNguoiDung}`);
        }
        
        const newNotification = {
            Ma_thong_bao: result.insertId,
            Ma_nguoi_dung: maNguoiDung,
            Loai: loai,
            Noi_dung: noiDung,
            Trang_thai_doc: 0,
            Ngay_gui: new Date()
        };

        // 2. Kiểm tra xem người dùng đó có đang online không
        if (global.onlineUsers && global.onlineUsers.has(String(maNguoiDung))) {
            const targetSocketId = global.onlineUsers.get(String(maNguoiDung));
            
            // Bắn tín hiệu realtime qua socket đến riêng người đó
            io.to(targetSocketId).emit('new_notification', newNotification);
            console.log(`Đã đẩy realtime thông báo cho User ${maNguoiDung}`);
        }
        
    } catch (error) {
        console.error("Lỗi khi gửi thông báo: " + error);
    }
}

export default sendNotification;