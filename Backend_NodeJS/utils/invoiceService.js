import nodemailer from 'nodemailer';
import PDFDocument from 'pdfkit';

// Cấu hình tài khoản gửi Email (Nên dùng Gmail)
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: 'nguyenphanthanhliem121204@gmail.com', // Điền email của bạn
        pass: 'xqul xlme vtqe gwwn'  // KHÔNG dùng mật khẩu gốc, phải dùng Mật khẩu ứng dụng (App Password)
    }
});

export const taoVaGuiHoaDonPDF = async (data) => {
    return new Promise((resolve, reject) => {
        try {
            // 1. Khởi tạo PDF
            const doc = new PDFDocument({ margin: 50 });
            let buffers = [];
            
            // Hứng dữ liệu file PDF vào buffer (bộ nhớ tạm)
            doc.on('data', buffers.push.bind(buffers));
            
            // 2. Thiết kế giao diện nội dung file PDF
            // Lưu ý: pdfkit mặc định không hỗ trợ font tiếng Việt chuẩn, 
            // nếu bị lỗi font, bạn có thể tải font .ttf (ví dụ Roboto) và dùng lệnh: doc.font('duong_dan_font.ttf')
            doc.fontSize(25).text('HOA DON THANH TOAN', { align: 'center' });
            doc.moveDown();
            doc.fontSize(14).text('----------------------------------------------------');
            doc.moveDown();
            doc.text(`Ma giao dich: ${data.maGiaoDich}`);
            doc.text(`Ma lich hen: ${data.maBooking}`);
            doc.moveDown();
            doc.text(`Benh nhan: ${data.tenBenhNhan}`);
            doc.text(`Bac si phu trach: ${data.tenBacSi}`);
            doc.text(`Dich vu: ${data.tenDichVu}`);
            doc.moveDown();
            doc.text(`So tien thanh toan: ${data.soTien} VNĐ`);
            doc.text(`Thoi gian: ${new Date().toLocaleString('vi-VN')}`);
            doc.moveDown();
            doc.text('----------------------------------------------------');
            doc.text('Cam on ban da su dung dich vu cua chung toi!', { align: 'center' });

            // Kết thúc ghi PDF
            doc.end();

            // 3. Khi PDF tạo xong, tiến hành gửi Email
            doc.on('end', async () => {
                const pdfData = Buffer.concat(buffers); // Ghép các mảnh buffer lại thành 1 file hoàn chỉnh

                const mailOptions = {
                    from: '"Phòng khám ABC" <email.cua.ban@gmail.com>',
                    to: data.emailNguoiDung,
                    subject: `[Phòng Khám ABC] Hóa đơn thanh toán lịch hẹn ${data.maBooking}`,
                    text: `Chào ${data.tenBenhNhan},\n\nGiao dịch thanh toán lịch hẹn của bạn đã thành công. Vui lòng xem hóa đơn chi tiết trong file PDF đính kèm.\n\nTrân trọng!`,
                    attachments: [
                        {
                            filename: `HoaDon_${data.maBooking}.pdf`,
                            content: pdfData // Đính kèm thẳng từ bộ nhớ, không cần lưu file cứng
                        }
                    ]
                };

                // Gửi mail
                await transporter.sendMail(mailOptions);
                console.log(`Đã gửi hóa đơn PDF thành công tới email: ${data.emailNguoiDung}`);
                resolve(true);
            });
        } catch (error) {
            console.error("Lỗi khi tạo và gửi hóa đơn PDF:", error);
            reject(error);
        }
    });
};