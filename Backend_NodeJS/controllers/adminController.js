import { hash, compare } from 'bcrypt';
import jwt from 'jsonwebtoken';
import adminModel from '../models/adminModel.js';
import userModel from '../models/userModel.js'; // Tận dụng các hàm saveOTP/getValidOTP của bạn
import { generateOTP } from '../utils/otpHelper.js';
import { sendOTPEmail } from '../config/emailConfig.js';

const ADMIN_JWT_SECRET = process.env.ADMIN_JWT_SECRET || "AdminSecretKey123";

export default class adminController {
    static async login(req, res) {
        try {
            const { email, password } = req.body;
            const admin = await adminModel.findByEmail(email);
            
            // 1. Kiểm tra tồn tại và mật khẩu
            if (!admin || !(await compare(password, admin.password_hash))) {
                if (admin) await adminModel.incrementFailedAttempts(email);
                return res.status(401).json({ success: false, message: 'Email hoặc mật khẩu không đúng' });
            }

            // 2. Kiểm tra trạng thái khóa (is_locked trong DB của bạn là tinyint, 0 là mở, 1 là khóa)
            if (admin.is_locked === 1) {
                return res.status(403).json({ success: false, message: 'Tài khoản đã bị khóa do nhập sai quá nhiều lần' });
            }

            // 3. Gửi OTP qua email (dùng chung logic với users)
            const otpCode = generateOTP();
            const hashedOtp = await hash(otpCode, 5);
            await userModel.saveOTP(email, hashedOtp, 'ADMIN_LOGIN');
            await sendOTPEmail(email, otpCode);

            return res.status(200).json({ success: true, message: 'Vui lòng kiểm tra email để lấy mã OTP' });
        } catch (e) {
            return res.status(500).json({ success: false, message: e.message });
        }
    }

    static async verifyOtp(req, res) {
        try {
            const { email, otp } = req.body;
            const otpRecord = await userModel.getValidOTP(email, 'ADMIN_LOGIN');
            
            // --- BẮT ĐẦU ĐOẠN CODE DEBUG ---
            console.log("OTP nhận từ Frontend:", otp);
            console.log("OTP hash lấy từ DB:", otpRecord ? otpRecord.Otp_hash : "Không tìm thấy record");
            
            if (otpRecord) {
                const isMatch = await compare(otp, otpRecord.Otp_hash);
                console.log("Kết quả so sánh compare():", isMatch);
            }
            // --- KẾT THÚC ĐOẠN CODE DEBUG ---

            if (!otpRecord || !(await compare(otp, otpRecord.Otp_hash))) {
                return res.status(400).json({ success: false, message: 'Mã OTP không hợp lệ' });
            }

            await userModel.markOTPAsUsed(otpRecord.Ma_otp);
            await adminModel.resetFailedAttempts(email);

            const admin = await adminModel.findByEmail(email);
            const token = jwt.sign({ id: admin.id, role: 'admin' }, process.env.ADMIN_JWT_SECRET || "AdminSecretKey123", { expiresIn: '8h' });

            return res.status(200).json({ success: true, token, message: 'Đăng nhập thành công' });
        } catch (e) {
            return res.status(500).json({ success: false, message: e.message });
        }
    }
}