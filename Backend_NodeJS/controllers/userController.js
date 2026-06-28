import { hash, compare } from 'bcrypt';
import jwt from 'jsonwebtoken';
import userModel from '../models/userModel.js';
import crypto from 'crypto';
import { generateOTP } from '../utils/otpHelper.js';
import { sendOTPEmail, sendResetPasswordEmail, sendDoctorOTPEmail } from '../config/emailConfig.js';
import path from 'path';
import { fileURLToPath } from 'url';
import { execute } from '../config/db.js';

const JWT_SECRET = process.env.JWT_SECRET || "BiMatCuaNhom1";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "1d";
const PASSWORD_HASH_ROUNDS = parseInt(process.env.PASSWORD_HASH_ROUNDS) || 10;

// Biến RAM TẠM THỜI CHỈ DÙNG ĐỂ CHỨA THÔNG TIN ĐĂNG KÝ (Vì chưa có account trong DB)
const pendingRegistrations = new Map();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export default class userController {
    // Hàm sinh Token
    static async generateToken(user) {
        return jwt.sign(
            { id: user.Ma_nguoi_dung, role: user.Phan_quyen },
            JWT_SECRET,
            { expiresIn: JWT_EXPIRES_IN }
        );
    }

    // Kiểm tra độ mạnh của mật khẩu
    static validatePassword(password) {
        const passwordRules = {
            minlength: 8, maxLength: 100,
            requireUppercase: true, requireLowercase: true,
            requireNumber: true, requireSpecial: true
        };
        if (password.length < passwordRules.minlength || password.length > passwordRules.maxLength) return false;
        if (passwordRules.requireUppercase && !/[A-Z]/.test(password)) return false;
        if (passwordRules.requireLowercase && !/[a-z]/.test(password)) return false;
        if (passwordRules.requireNumber && !/[0-9]/.test(password)) return false;
        if (passwordRules.requireSpecial && !/[!@#$%^&*(),.?":{}|<>]/.test(password)) return false;
        return true;
    }

    // API đăng ký (gửi OTP vào email)
    static async register(req, res) {
        try {
            const { email, password, fullName, role } = req.body;

            if (!email || !password || !fullName) {
                return res.status(400).json({ succeeded: false, message: 'Vui lòng điền đầy đủ thông tin' });
            }

            if (!userController.validatePassword(password)) {
                return res.status(400).json({
                    succeeded: false, 
                    message: 'Mật khẩu yếu: 8-100 ký tự, phải bao gồm A-Z, a-z, 0-9, ký tự đặc biệt'
                });
            }

            const existingUser = await userModel.findByEmail(email);
            if (existingUser) {
                return res.status(409).json({ succeeded: false, message: 'Email đã tồn tại' });
            }

            // Sinh mã OTP 6 số
            const otpCode = generateOTP();
            
            // Lưu mã băm OTP xuống Database (Bảng ma_otp) thay vì lưu chay
            const hashedOtp = await hash(otpCode, 5); 
            await userModel.saveOTP(email, hashedOtp, 'REGISTER');

            // Lưu TẠM thông tin đăng ký vào RAM (vì chưa thể INSERT vào bảng nguoi_dung lúc này)
            const hashedPassword = await hash(password, PASSWORD_HASH_ROUNDS);
            pendingRegistrations.set(email, { email, hashedPassword, fullName, role: role || 'Benh_nhan' });

            // Gửi Email
            await sendOTPEmail(email, otpCode);

            return res.status(200).json({
                succeeded: true, 
                message: 'Đã gửi mã OTP đến Email của bạn. Vui lòng kiểm tra!',
                target: email 
            });

        } catch (error) {
            console.error("Lỗi gửi email đăng ký:", error);
            return res.status(500).json({ succeeded: false, message: "Lỗi hệ thống khi gửi Email xác thực." });
        }
    }

    // API xác thực OTP và hoàn tất đăng ký (Insert vào DB)
    static async verifyOTPAndRegister(req, res) {
        try {
            const { email, otp } = req.body;

            if (!email || !otp) return res.status(400).json({ succeeded: false, message: "Thiếu thông tin xác thực" });

            // Lấy mã OTP trong CSDL lên kiểm tra
            const otpRecord = await userModel.getValidOTP(email, 'REGISTER');
            if (!otpRecord) return res.status(400).json({ succeeded: false, message: "Mã OTP không tồn tại hoặc đã hết hạn." });

            // Nếu nhập sai quá 5 lần -> Hủy luôn mã
            if (otpRecord.So_lan_thu >= 5) {
                await userModel.markOTPAsUsed(otpRecord.Ma_otp);
                return res.status(400).json({ succeeded: false, message: "Bạn đã nhập sai quá nhiều lần. Vui lòng gửi lại mã mới!" });
            }

            const isMatch = await compare(otp, otpRecord.Otp_hash);
            if (!isMatch) {
                await userModel.incrementOTPTries(otpRecord.Ma_otp);
                return res.status(400).json({ succeeded: false, message: "Mã OTP không chính xác!" });
            }

            // Mã đúng -> Đánh dấu đã dùng
            await userModel.markOTPAsUsed(otpRecord.Ma_otp);

            // Lấy thông tin user đã lưu tạm để Insert vào CSDL chính
            const userData = pendingRegistrations.get(email);
            if (!userData) {
                return res.status(400).json({ succeeded: false, message: "Phiên đăng ký đã hết hạn. Vui lòng thực hiện lại từ đầu." });
            }

            const newId = await userModel.create(userData);
            if (!newId) return res.status(500).json({ succeeded: false, message: "Lưu cơ sở dữ liệu thất bại" });

            pendingRegistrations.delete(email); // Xóa rác trên RAM
            
            return res.status(201).json({
                succeeded: true, 
                message: 'Đăng ký tài khoản thành công!',
                user: { id: newId, email, fullName: userData.fullName }
            });

        } catch (error) {
            console.error("LỖI XÁC THỰC OTP ĐĂNG KÝ:", error);
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // API đăng nhập
    static async login(req, res) {
        try {
            const { email, password } = req.body;
            if (!email || !password) return res.status(400).json({ succeeded: false, message: "Thiếu Email hoặc Mật khẩu" });

            const user = await userModel.findByEmail(email);
            if (!user) return res.status(401).json({ succeeded: false, message: 'Email hoặc mật khẩu không đúng' });

            if (user.Trang_thai === 0) {
                return res.status(403).json({ succeeded: false, message: "Tài khoản đã bị vô hiệu hóa." });
            }

            const isMatch = await compare(password, user.Mat_khau);
            if (!isMatch) return res.status(401).json({ succeeded: false, message: "Email hoặc mật khẩu không đúng" });

            const token = await userController.generateToken(user);
            
            return res.status(200).json({ 
                succeeded: true, token: token, role: user.Phan_quyen, id: user.Ma_nguoi_dung , doctorId: user.Ma_bac_si
            });
            
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }


    // API Gửi OTP Khôi phục mật khẩu
    static async forgotPassword(req, res) {
        try {
            const { email } = req.body;
            if (!email) return res.status(400).json({ succeeded: false, message: 'Vui lòng nhập email' });

            const user = await userModel.findByEmail(email);
            if (!user) return res.status(404).json({ succeeded: false, message: 'Email không tồn tại trong hệ thống' });

            // Sinh mã OTP 6 số
            const otpCode = generateOTP();
            
            // Lưu vào DB với loại 'FORGOT_PASSWORD'
            const hashedOtp = await hash(otpCode, 5); 
            await userModel.saveOTP(email, hashedOtp, 'FORGOT_PASSWORD');

            // Gửi email chứa OTP
            await sendResetPasswordEmail(email, otpCode);

            return res.status(200).json({ 
                succeeded: true, 
                message: 'Mã OTP khôi phục đã được gửi. Vui lòng kiểm tra email!' 
            });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // API Kiểm tra OTP hợp lệ trước khi cho phép nhập mật khẩu mới
    static async verifyResetOTP(req, res) {
        try {
            const { email, otp } = req.body;
            if (!email || !otp) return res.status(400).json({ succeeded: false, message: "Thiếu thông tin xác thực" });

            const otpRecord = await userModel.getValidOTP(email, 'FORGOT_PASSWORD');
            if (!otpRecord) return res.status(400).json({ succeeded: false, message: "Mã OTP không tồn tại hoặc đã hết hạn." });

            if (otpRecord.So_lan_thu >= 5) {
                await userModel.markOTPAsUsed(otpRecord.Ma_otp);
                return res.status(400).json({ succeeded: false, message: "Bạn đã nhập sai quá nhiều lần. Vui lòng xin mã mới!" });
            }

            const isMatch = await compare(otp, otpRecord.Otp_hash);
            if (!isMatch) {
                await userModel.incrementOTPTries(otpRecord.Ma_otp);
                return res.status(400).json({ succeeded: false, message: "Mã OTP không chính xác!" });
            }

            // Mấu chốt: KHÔNG gọi hàm markOTPAsUsed ở đây, để dành cho bước Cập nhật mật khẩu
            return res.status(200).json({ succeeded: true, message: "Mã OTP hợp lệ." });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // API Nhận OTP + Mật khẩu mới để cập nhật thẳng
    static async updatePassword(req, res) {
        try {
            const { email, otp, newPassword } = req.body;

            if (!email || !otp || !newPassword) {
                return res.status(400).json({ succeeded: false, message: "Vui lòng điền đủ thông tin!" });
            }

            if (!userController.validatePassword(newPassword)) {
                return res.status(400).json({ succeeded: false, message: 'Mật khẩu mới quá yếu!' });
            }

            // Lấy OTP từ CSDL lên kiểm tra
            const otpRecord = await userModel.getValidOTP(email, 'FORGOT_PASSWORD');
            if (!otpRecord) return res.status(400).json({ succeeded: false, message: "Mã OTP không tồn tại hoặc đã hết hạn." });

            if (otpRecord.So_lan_thu >= 5) {
                await userModel.markOTPAsUsed(otpRecord.Ma_otp);
                return res.status(400).json({ succeeded: false, message: "Bạn đã nhập sai quá nhiều lần. Vui lòng xin mã mới!" });
            }

            const isMatch = await compare(otp, otpRecord.Otp_hash);
            if (!isMatch) {
                await userModel.incrementOTPTries(otpRecord.Ma_otp);
                return res.status(400).json({ succeeded: false, message: "Mã OTP không chính xác!" });
            }

            // Nếu OTP đúng -> Cập nhật mật khẩu mới
            await userModel.markOTPAsUsed(otpRecord.Ma_otp);
            const hashedPassword = await hash(newPassword, PASSWORD_HASH_ROUNDS);
            const isUpdated = await userModel.updatePassword(email, hashedPassword);
            
            if (isUpdated) {
                return res.status(200).json({ succeeded: true, message: "Đổi mật khẩu thành công! Bạn có thể đăng nhập ngay." });
            } else {
                return res.status(500).json({ succeeded: false, message: "Lỗi hệ thống khi cập nhật mật khẩu." });
            }

        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // API Đổi mật khẩu (khi đã đăng nhập)
    static async changePassword(req,res){
        try{
            const {userID, newPassword, currentPassword} = req.body;
            if(!userID) return res.status(400).json({succeeded: false, message: 'Thiếu userID'});
            if(!newPassword) return res.status(400).json({succeeded: false, message: 'Thiếu mật khẩu mới'});
            if(!currentPassword) return res.status(400).json({succeeded: false, message: 'Thiếu mật khẩu hiện tại'});

            const newHashedPassword = await hash(newPassword, parseInt(process.env.PASSWORD_HASH_ROUNDS) || 10);
            const result = await userModel.changePassword(userID, newHashedPassword, currentPassword);

            return result ? res.status(200).json({succeeded: true}) : res.status(400).json({succeeded: false, message: result});
        } catch(error) {
            return res.status(500).json({succeeded: false, message: "Lỗi thay đổi mật khẩu: " + error.message});
        }
    }

    // API Đăng nhập bằng Google
    static async oauthLogin(req, res) {
        try {
            const { email, fullName, avatar, provider, providerId } = req.body;
            if (!email || !provider || !providerId) return res.status(400).json({ succeeded: false, message: "Thiếu thông tin xác thực từ Google/Facebook" });

            let user = await userModel.findByEmail(email);

            if (user && user.Trang_thai === 0) {
                return res.status(403).json({ succeeded: false, message: "Tài khoản này đã bị vô hiệu hóa." });
            }

            if (!user) {
                const randomPassword = crypto.randomBytes(32).toString('hex');
                const hashedPassword = await hash(randomPassword, parseInt(process.env.PASSWORD_HASH_ROUNDS) || 10);

                const newId = await userModel.createOAuthUser({
                    email: email, randomHashedPassword: hashedPassword,
                    fullName: fullName || 'Người dùng ẩn danh',
                    provider: provider, providerId: providerId, avatar: avatar
                });

                if (!newId) return res.status(500).json({ succeeded: false, message: "Tạo tài khoản thất bại" });
                user = await userModel.findById(newId);
            } 
            
            const token = await userController.generateToken(user);
            return res.status(200).json({ succeeded: true, token: token, role: user.Phan_quyen, id: user.Ma_nguoi_dung });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // API Xóa tài khoản (soft delete)
    static async deleteAccount(req, res) {
        try {
            const { userId } = req.body;
            if (!userId) return res.status(400).json({ succeeded: false, message: "Không tìm thấy thông tin người dùng" });

            const isDeleted = await userModel.softDeleteUser(userId);
            if (isDeleted) {
                return res.status(200).json({ succeeded: true, message: "Đã vô hiệu hóa tài khoản thành công" });
            } else {
                return res.status(400).json({ succeeded: false, message: "Lỗi hệ thống: Không thể xóa tài khoản" });
            }
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // =====================================================================
    // CÁC HÀM DÀNH CHO BÁC SĨ (DOCTOR PORTAL)
    // =====================================================================

    // Hàm đăng kí bác sĩ
    static async registerDoctor(req, res) {
        try {
            const { email, password, fullName, dienThoai, maChuyenKhoa, hocVi, namKinhNghiem, moTa } = req.body;

            if (!email || !password || !fullName || !dienThoai || !maChuyenKhoa || !hocVi || !namKinhNghiem) {
                return res.status(400).json({ succeeded: false, message: 'Vui lòng điền đầy đủ thông tin chuyên môn và liên hệ' });
            }

            if (!userController.validatePassword(password)) {
                return res.status(400).json({ succeeded: false, message: 'Mật khẩu yếu: 8-100 ký tự, phải bao gồm A-Z, a-z, 0-9, ký tự đặc biệt' });
            }

            const existingUser = await userModel.findByEmail(email);
            if (existingUser) return res.status(409).json({ succeeded: false, message: 'Email đã tồn tại' });

            const uploadDir = path.join(process.cwd(), 'uploads');

            // Xử lý lưu Ảnh đại diện
            const avatarFile = req.files.avatar;
            const avatarName = `avatar_${Date.now()}_${avatarFile.name.replace(/\s+/g, '')}`;
            const avatarPath = path.join(uploadDir, avatarName);
            await avatarFile.mv(avatarPath);
            console.log("✅ Đã lưu Avatar thành công tại:", avatarPath);

            // Xử lý lưu Ảnh chứng chỉ
            const certFile = req.files.certificate;
            const certName = `cert_${Date.now()}_${certFile.name.replace(/\s+/g, '')}`;
            const certPath = path.join(uploadDir, certName);
            await certFile.mv(certPath);
            console.log("✅ Đã lưu Chứng chỉ thành công tại:", certPath);

            // Sinh OTP
            const otpCode = generateOTP();
            const hashedOtp = await hash(otpCode, 5);
            await userModel.saveOTP(email, hashedOtp, 'REGISTER_DOCTOR');

            // Lưu RAM
            const hashedPassword = await hash(password, PASSWORD_HASH_ROUNDS);
            pendingRegistrations.set(email, {
                email, hashedPassword, fullName, dienThoai, role: 'Bac_si',
                maChuyenKhoa, hocVi, namKinhNghiem, moTa,
                anhDaiDien: `/uploads/${avatarName}`,
                anhChungChi: `/uploads/${certName}` 
            });

            await sendDoctorOTPEmail(email, otpCode);
            return res.status(200).json({
                succeeded: true, 
                message: 'Đã gửi mã OTP đến Email của bạn. Vui lòng kiểm tra!',
                target: email 
            });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // Hàm check mã OTP
    static async verifyDoctorOTP(req, res) {
        try {
            const { email, otp } = req.body;
            if (!email || !otp) return res.status(400).json({ succeeded: false, message: "Thiếu thông tin xác thực" });

            const otpRecord = await userModel.getValidOTP(email, 'REGISTER_DOCTOR');
            if (!otpRecord) return res.status(400).json({ succeeded: false, message: "Mã OTP không hợp lệ hoặc hết hạn." });

            if (otpRecord.So_lan_thu >= 5) {
                await userModel.markOTPAsUsed(otpRecord.Ma_otp);
                return res.status(400).json({ succeeded: false, message: "Nhập sai quá nhiều lần. Vui lòng gửi lại mã mới!" });
            }

            const isMatch = await compare(otp, otpRecord.Otp_hash);
            if (!isMatch) {
                await userModel.incrementOTPTries(otpRecord.Ma_otp);
                return res.status(400).json({ succeeded: false, message: "Mã OTP không chính xác!" });
            }

            await userModel.markOTPAsUsed(otpRecord.Ma_otp);
            const userData = pendingRegistrations.get(email);
            if (!userData) return res.status(400).json({ succeeded: false, message: "Phiên đăng ký hết hạn." });

            // 1. Lưu vào bảng nguoi_dung KÈM THEO CỘT Anh_dai_dien
            const [userResult] = await execute(
                'INSERT INTO nguoi_dung (Ten_nguoi_dung, Email, Dien_thoai, Mat_khau, Phan_quyen, Anh_dai_dien, Trang_thai) VALUES (?, ?, ?, ?, ?, 1)',
                [userData.fullName, userData.email, userData.dienThoai, userData.hashedPassword, 'Bac_si', userData.anhDaiDien]
            );
            const newUserId = userResult.insertId;

            // 2. Lưu vào bảng bac_si kèm cột Anh_chung_chi
            await execute(
                'INSERT INTO bac_si (Ma_nguoi_dung, Ma_chuyen_khoa, Mo_ta_ban_than, Hoc_vi, Nam_kinh_nghiem, Anh_chung_chi, Trang_thai_hoat_dong) VALUES (?, ?, ?, ?, ?, ?, "pending")',
                [newUserId, userData.maChuyenKhoa, userData.moTa || '', userData.hocVi, userData.namKinhNghiem, userData.anhChungChi]
            );

            pendingRegistrations.delete(email);

            // Bắn tín hiệu socket real-time cho Admin Dashboard
            const io = req.app.get('io');
            if (io) io.to('admin_room').emit('admin_dashboard_update');

            return res.status(201).json({ succeeded: true, message: 'Đăng ký hồ sơ thành công! Vui lòng chờ Admin phê duyệt.' });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }
}