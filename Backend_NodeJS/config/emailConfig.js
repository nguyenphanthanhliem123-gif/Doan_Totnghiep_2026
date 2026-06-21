import nodemailer from 'nodemailer';
import dotenv from 'dotenv';

dotenv.config();

// Tạo cổng kết nối tới Gmail
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
    }
});

// Hàm gửi thư chứa mã OTP để xác thực email khi đăng ký tài khoản
export const sendOTPEmail = async (toEmail, otpCode) => {
    const mailOptions = {
        from: `"Hệ Thống Đặt Lịch Khám" <${process.env.EMAIL_USER}>`,
        to: toEmail,
        subject: 'Mã Xác Thực Đăng Ký Tài Khoản',
        html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #ddd; border-radius: 10px;">
                <h2 style="color: #4BCBEB; text-align: center;">XÁC THỰC EMAIL</h2>
                <p>Chào bạn,</p>
                <p>Bạn đang đăng ký tài khoản trên hệ thống Đặt Lịch Khám. Vui lòng nhập mã OTP gồm 6 chữ số dưới đây để hoàn tất:</p>
                <div style="background-color: #EAF8FB; padding: 15px; text-align: center; font-size: 28px; font-weight: bold; letter-spacing: 5px; color: #2D2D2D; border-radius: 5px; margin: 20px 0;">
                    ${otpCode}
                </div>
                <p style="color: #dc3545; font-size: 13px;">* Mã OTP này chỉ có hiệu lực trong vòng 5 phút.</p>
                <p>Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email.</p>
            </div>
        `
    };

    return transporter.sendMail(mailOptions);
};

// Hàm gửi thư chứa mã OTP để Reset Mật Khẩu
export const sendResetPasswordEmail = async (toEmail, otpCode) => {
    const mailOptions = {
        from: `"Hệ Thống Đặt Lịch Khám" <${process.env.EMAIL_USER}>`,
        to: toEmail,
        subject: 'Mã OTP Khôi Phục Mật Khẩu',
        html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #ddd; border-radius: 10px;">
                <h2 style="color: #4BCBEB; text-align: center;">KHÔI PHỤC MẬT KHẨU</h2>
                <p>Chào bạn,</p>
                <p>Hệ thống vừa nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn. Vui lòng sử dụng mã OTP dưới đây để tạo mật khẩu mới:</p>
                <div style="background-color: #EAF8FB; padding: 15px; text-align: center; font-size: 28px; font-weight: bold; letter-spacing: 5px; color: #2D2D2D; border-radius: 5px; margin: 20px 0;">
                    ${otpCode}
                </div>
                <p style="color: #dc3545; font-size: 13px;">* Mã OTP này chỉ có hiệu lực trong vòng 5 phút.</p>
                <p>Nếu bạn không thực hiện yêu cầu này, tài khoản của bạn vẫn an toàn. Vui lòng bỏ qua email này.</p>
            </div>
        `
    };

    return transporter.sendMail(mailOptions);
};