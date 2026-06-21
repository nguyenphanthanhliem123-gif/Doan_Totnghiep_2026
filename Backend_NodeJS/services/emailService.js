import nodemailer from 'nodemailer';
import QRCode from 'qrcode';
import { configDotenv } from 'dotenv';

/**
 * Hàm tạo mã QR dưới dạng chuỗi Base64
 */
const generateQRCodeBase64 = async (text) => {
    try {
        // Tạo QR chứa mã Booking
        const qrDataURL = await QRCode.toDataURL(text);
        return qrDataURL;
    } catch (err) {
        console.error("Lỗi tạo QR Code:", err);
        return null;
    }
};

/**
 * Hàm gửi email xác nhận đặt lịch
 * @param {string} emailNguoiNhan - Email của bệnh nhân
 * @param {object} thongTin - Object chứa { tenBacSi, ngayKham, gioKham, diaChi, maBooking }
 */
const sendBookingConfirmationEmail = async (emailNguoiNhan, thongTin) => {
    try {
        // 1. Cấu hình Transporter kết nối với Gmail
        const transporter = nodemailer.createTransport({
            service: 'gmail',
            auth: {
                user: process.env.EMAIL_USER,
                pass: process.env.EMAIL_PASS
            }
        });

        // 2. Tạo mã QR từ mã Booking
        const qrCodeDataUrl = await generateQRCodeBase64(thongTin.maBooking);

        // 3. Xây dựng nội dung HTML (Template)
        const htmlContent = `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden;">
                <div style="background-color: #007BFF; color: white; padding: 20px; text-align: center;">
                    <h2 style="margin: 0;">Xác nhận lịch hẹn thành công!</h2>
                </div>
                <div style="padding: 20px;">
                    <p>Chào bạn,</p>
                    <p>Cảm ơn bạn đã sử dụng dịch vụ. Lịch hẹn khám bệnh của bạn đã được xác nhận. Dưới đây là thông tin chi tiết:</p>
                    
                    <div style="background-color: #f9f9f9; padding: 15px; border-radius: 6px; margin: 20px 0;">
                        <p style="margin: 5px 0;"><strong>Mã Booking:</strong> <span style="color: #E53935; font-size: 18px;">${thongTin.maBooking}</span></p>
                        <p style="margin: 5px 0;"><strong>Bác sĩ phụ trách:</strong> ${thongTin.tenBacSi}</p>
                        <p style="margin: 5px 0;"><strong>Ngày khám:</strong> ${thongTin.ngayKham}</p>
                        <p style="margin: 5px 0;"><strong>Giờ khám:</strong> ${thongTin.gioKham}</p>
                        <p style="margin: 5px 0;"><strong>Địa chỉ:</strong> ${thongTin.diaChi}</p>
                    </div>

                    <p style="font-size: 13px; color: #777;">Lưu ý: Bạn vui lòng đến trước 15 phút để làm thủ tục.</p>
                    <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;" />
                    <p style="font-size: 12px; color: #999; text-align: center;">Đây là email tự động, vui lòng không trả lời.</p>
                </div>
            </div>
        `;

        // 4. Thiết lập tùy chọn Email
        const mailOptions = {
            from: `"Hệ thống Đặt lịch khám" <${process.env.EMAIL_USER}>`,
            to: emailNguoiNhan,
            subject: `[Xác nhận] Lịch hẹn khám bệnh - Mã: ${thongTin.maBooking}`,
            html: htmlContent
        };

        // 5. Gửi thư
        const info = await transporter.sendMail(mailOptions);
        console.log('✅ Đã gửi email xác nhận thành công tới:', emailNguoiNhan);
        return info;

    } catch (error) {
        console.error('❌ Lỗi khi gửi email xác nhận:', error);
        throw error;
    }
};

const sendReminderEmail24h = async (emailNguoiNhan, thongTin) => {
    try {
        const transporter = nodemailer.createTransport({
            service: 'gmail',
            auth: {
                user: process.env.EMAIL_USER,
                pass: process.env.EMAIL_PASS
            }
        });

        // Tạo mã QR để bệnh nhân tiện check-in khi đến
        const qrCodeDataUrl = await generateQRCodeBase64(thongTin.maBooking);

        const htmlContent = `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden;">
                <div style="background-color: #FF9800; color: white; padding: 20px; text-align: center;">
                    <h2 style="margin: 0;">Nhắc nhở lịch hẹn sắp tới!</h2>
                </div>
                <div style="padding: 20px;">
                    <p>Chào bạn,</p>
                    <p>Hệ thống xin nhắc nhở bạn có một lịch hẹn khám bệnh sẽ diễn ra trong vòng <strong>24 giờ tới</strong>. Vui lòng xem lại thông tin bên dưới:</p>
                    
                    <div style="background-color: #fff3e0; padding: 15px; border-radius: 6px; margin: 20px 0; border-left: 4px solid #FF9800;">
                        <p style="margin: 5px 0;"><strong>Mã Booking:</strong> <span style="color: #E53935; font-size: 18px;">${thongTin.maBooking}</span></p>
                        <p style="margin: 5px 0;"><strong>Bác sĩ phụ trách:</strong> ${thongTin.tenBacSi}</p>
                        <p style="margin: 5px 0;"><strong>Ngày khám:</strong> ${thongTin.ngayKham}</p>
                        <p style="margin: 5px 0;"><strong>Giờ khám:</strong> ${thongTin.gioKham}</p>
                        <p style="margin: 5px 0;"><strong>Địa chỉ:</strong> ${thongTin.diaChi}</p>
                    </div>

                    <div style="text-align: center; margin: 20px 0;">
                        <p style="font-size: 14px; color: #555;">Vui lòng chuẩn bị sẵn mã QR này khi đến phòng khám:</p>
                        <img src="${qrCodeDataUrl}" alt="Mã QR Booking" style="width: 150px; height: 150px; border: 1px solid #ccc; border-radius: 8px;" />
                    </div>

                    <p style="font-size: 13px; color: #777;">Nếu bạn có việc bận đột xuất, vui lòng truy cập ứng dụng để hủy hoặc đổi lịch trước 2 tiếng.</p>
                </div>
            </div>
        `;

        const mailOptions = {
            from: `"Hệ thống Đặt lịch khám" <${process.env.EMAIL_USER}>`,
            to: emailNguoiNhan,
            subject: `[Nhắc nhở] Lịch hẹn khám bệnh ngày mai - Mã: ${thongTin.maBooking}`,
            html: htmlContent
        };

        await transporter.sendMail(mailOptions);
        console.log('✅ Đã gửi email nhắc 24h thành công tới:', emailNguoiNhan);
    } catch (error) {
        console.error('❌ Lỗi khi gửi email nhắc 24h:', error);
    }
};

const EmailService = {
    generateQRCodeBase64,
    sendBookingConfirmationEmail,
    sendReminderEmail24h
};

export default EmailService;