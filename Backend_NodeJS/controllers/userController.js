import { hash, compare } from 'bcrypt';
import jwt from 'jsonwebtoken';
import userModel from '../models/userModel.js';
import crypto from 'crypto';
// Import thêm công cụ Reset Password
import { otpStorage, generateOTP, resetStorage, generateResetToken } from '../utils/otpHelper.js';
import { sendOTPEmail, sendResetPasswordEmail } from '../config/emailConfig.js';

const JWT_SECRET = process.env.JWT_SECRET || "BiMatCuaNhom1";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "1d";
const PASSWORD_HASH_ROUNDS = parseInt(process.env.PASSWORD_HASH_ROUNDS) || 10;

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
            minlength: 8,
            maxLength: 100,
            requireUppercase: true,
            requireLowercase: true,
            requireNumber: true,
            requireSpecial: true
        };
        if (password.length < passwordRules.minlength || password.length > passwordRules.maxLength) return false;
        if (passwordRules.requireUppercase && !/[A-Z]/.test(password)) return false;
        if (passwordRules.requireLowercase && !/[a-z]/.test(password)) return false;
        if (passwordRules.requireNumber && !/[0-9]/.test(password)) return false;
        if (passwordRules.requireSpecial && !/[!@#$%^&*(),.?":{}|<>]/.test(password)) return false;
        return true;
    }

    // API Đăng ký - Gửi OTP qua Email
    static async register(req, res) {
        try {
            // Đã xóa phoneNumber khỏi yêu cầu
            const { email, password, fullName } = req.body;

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
                return res.status(409).json({ succeeded: false, message: 'Email đã tồn tại trong hệ thống' });
            }

            const otpCode = generateOTP();
            const hashedPassword = await hash(password, PASSWORD_HASH_ROUNDS);
            
            otpStorage.set(email, {
                otp: otpCode,
                userData: { email, hashedPassword, fullName }, // Không lưu phoneNumber nữa
                expiresAt: Date.now() + 5 * 60 * 1000
            });

            await sendOTPEmail(email, otpCode);

            return res.status(200).json({
                succeeded: true, 
                message: 'Đã gửi mã OTP đến Email của bạn. Vui lòng kiểm tra!',
                target: email 
            });

        } catch (error) {
            console.error("Lỗi gửi email:", error);
            return res.status(500).json({ succeeded: false, message: "Lỗi hệ thống khi gửi Email xác thực." });
        }
    }

    // API Xác thực OTP và hoàn tất đăng ký
    static async verifyOTPAndRegister(req, res) {
        try {
            const { email, otp } = req.body;

            if (!email || !otp) {
                return res.status(400).json({ succeeded: false, message: "Thiếu thông tin xác thực" });
            }

            const storedData = otpStorage.get(email);

            if (!storedData) {
                return res.status(400).json({ succeeded: false, message: "Mã OTP không tồn tại hoặc đã hết hạn" });
            }

            if (Date.now() > storedData.expiresAt) {
                otpStorage.delete(email);
                return res.status(400).json({ succeeded: false, message: "Mã OTP đã hết hạn. Vui lòng đăng ký lại" });
            }

            if (storedData.otp !== otp) {
                return res.status(400).json({ succeeded: false, message: "Mã OTP không chính xác" });
            }

            const { hashedPassword, fullName } = storedData.userData; // Không lấy phoneNumber nữa

            const newId = await userModel.create({ 
                email, 
                hashedPassword,
                fullName
            });

            if (!newId) return res.status(500).json({ succeeded: false, message: "Lưu cơ sở dữ liệu thất bại" });

            otpStorage.delete(email);
            
            return res.status(201).json({
                succeeded: true, 
                message: 'Đăng ký tài khoản thành công!',
                user: { id: newId, email, fullName }
            });

        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // API Đăng nhập
    static async login(req, res) {
        try {
            const { email, password } = req.body;
            
            if (!email || !password) {
                return res.status(400).json({ succeeded: false, message: "Thiếu Email hoặc Mật khẩu" });
            }

            const user = await userModel.findByEmail(email);
            if (!user) {
                return res.status(401).json({ succeeded: false, message: 'Email hoặc mật khẩu không đúng' });
            }

            // 🛑 CHẶN TÀI KHOẢN ĐÃ BỊ XÓA (Trang_thai = 0)
            if (user.Trang_thai === 0) {
                return res.status(403).json({ 
                    succeeded: false, 
                    message: "Tài khoản này đã bị vô hiệu hóa hoặc bị xóa. Vui lòng liên hệ phòng khám." 
                });
            }

            const isMatch = await compare(password, user.Mat_khau);
            if (!isMatch) {
                return res.status(401).json({ succeeded: false, message: "Email hoặc mật khẩu không đúng" });
            }

            const token = await userController.generateToken(user);
            
            return res.status(200).json({ 
                succeeded: true, 
                token: token, 
                role: user.Phan_quyen,
                id: user.Ma_nguoi_dung 
            });
            
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // 1. API: Yêu cầu Quên mật khẩu (Gửi email)
    static async forgotPassword(req, res) {
        try {
            const { email } = req.body;
            if (!email) return res.status(400).json({ succeeded: false, message: 'Vui lòng nhập email' });

            const user = await userModel.findByEmail(email);
            if (!user) {
                return res.status(404).json({ succeeded: false, message: 'Email không tồn tại trong hệ thống' });
            }

            const token = generateResetToken();
            resetStorage.set(email, {
                token: token,
                expiresAt: Date.now() + 15 * 60 * 1000 // Hạn 15 phút
            });

            const PORT = process.env.PORT || 3001;
            const resetLink = `http://localhost:${PORT}/api/auth/reset-password-page?email=${email}&token=${token}`;

            await sendResetPasswordEmail(email, resetLink);

            return res.status(200).json({ succeeded: true, message: 'Vui lòng kiểm tra email để đặt lại mật khẩu' });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // 2. API: Vẽ giao diện HTML cho người dùng nhập mật khẩu mới
    static async renderResetPasswordPage(req, res) {
        const { email, token } = req.query;

        const storedData = resetStorage.get(email);
        
        // Kiểm tra Token: Không có, sai mã, hoặc quá 15 phút
        if (!storedData || storedData.token !== token || Date.now() > storedData.expiresAt) {
            return res.send(`
                <div style="text-align: center; font-family: Arial; margin-top: 50px;">
                    <h2 style="color: red;">Đường dẫn không hợp lệ hoặc đã hết hạn!</h2>
                    <p>Vui lòng quay lại ứng dụng và thực hiện lại yêu cầu quên mật khẩu.</p>
                </div>
            `);
        }

        // Nếu hợp lệ, vẽ Form HTML trả về thẳng cho trình duyệt
        const html = `
        <!DOCTYPE html>
        <html lang="vi">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Đặt Lại Mật Khẩu</title>
            <style>
                body { font-family: Arial, sans-serif; background-color: #EAF8FB; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
                .container { background-color: white; padding: 30px; border-radius: 15px; box-shadow: 0 4px 10px rgba(0,0,0,0.1); width: 100%; max-width: 400px; }
                h2 { color: #4BCBEB; text-align: center; }
                input { width: 100%; padding: 12px; margin: 10px 0; border: 1px solid #ccc; border-radius: 8px; box-sizing: border-box; }
                button { width: 100%; padding: 12px; margin-top: 15px; background-color: #4BCBEB; color: white; border: none; border-radius: 8px; font-size: 16px; font-weight: bold; cursor: pointer; }
                button:hover { background-color: #3baecb; }
                .error { color: red; font-size: 14px; display: none; text-align: center; }
            </style>
        </head>
        <body>
            <div class="container">
                <h2>Tạo Mật Khẩu Mới</h2>
                <form action="/api/auth/update-password" method="POST" onsubmit="return validate()">
                    <input type="hidden" name="email" value="${email}">
                    <input type="hidden" name="token" value="${token}">
                    
                    <div class="error" id="error-msg">Mật khẩu xác nhận không khớp!</div>
                    
                    <input type="password" name="newPassword" id="pw1" placeholder="Nhập mật khẩu mới" required minlength="8">
                    <input type="password" id="pw2" placeholder="Xác nhận mật khẩu mới" required>
                    
                    <button type="submit">Cập Nhật Mật Khẩu</button>
                </form>
            </div>
            <script>
                function validate() {
                    const pw1 = document.getElementById('pw1').value;
                    const pw2 = document.getElementById('pw2').value;
                    if (pw1 !== pw2) {
                        document.getElementById('error-msg').style.display = 'block';
                        return false;
                    }
                    return true;
                }
            </script>
        </body>
        </html>
        `;
        res.send(html);
    }

    // 3. API: Nhận mật khẩu mới từ HTML và Lưu vào Database
    static async updatePassword(req, res) {
        try {
            const { email, token, newPassword } = req.body;

            const storedData = resetStorage.get(email);
            if (!storedData || storedData.token !== token || Date.now() > storedData.expiresAt) {
                return res.send(`<h2 style="color:red; text-align:center;">Giao dịch đã hết hạn!</h2>`);
            }

            if (!userController.validatePassword(newPassword)) {
                return res.send(`<h2 style="color:red; text-align:center;">Mật khẩu quá yếu. Vui lòng quay lại email và thử lại với mật khẩu có đủ chữ hoa, chữ thường, số và ký tự đặc biệt.</h2>`);
            }

            const hashedPassword = await hash(newPassword, parseInt(process.env.PASSWORD_HASH_ROUNDS) || 10);
            
            const isUpdated = await userModel.updatePassword(email, hashedPassword);
            
            if (isUpdated) {
                resetStorage.delete(email); 
                return res.send(`
                    <div style="text-align: center; font-family: Arial; margin-top: 50px;">
                        <h2 style="color: #4BCBEB;">Đổi mật khẩu thành công! 🎉</h2>
                        <p>Bạn có thể đóng trang này và quay lại ứng dụng để đăng nhập.</p>
                    </div>
                `);
            } else {
                return res.send(`<h2 style="color:red; text-align:center;">Lỗi hệ thống. Vui lòng thử lại sau.</h2>`);
            }

        } catch (error) {
            return res.send(`<h2>Lỗi: ${error.message}</h2>`);
        }
    }

    static async changePassword(req,res){
        try{
            const {userID, newPassword, currentPassword} = req.body;

            console.log('=== DEBUG(change_password) ===');
            console.log('=== userID: ' + userID);
            console.log('=== newPassword: ' + newPassword);
            console.log('=== currentPassword: ' + currentPassword);

            if(!userID) return res.status(400).json({succeeded: false, message: 'Thiếu userID'});
            if(!newPassword) return res.status(400).json({succeeded: false, message: 'Thiếu mật khẩu mới'});
            if(!currentPassword) return res.status(400).json({succeeded: false, message: 'Thiếu mật khẩu hiện tại'});

            const newHashedPassword = await hash(newPassword, parseInt(process.env.PASSWORD_HASH_ROUNDS) || 10);

            const result = await userModel.changePassword(userID, newHashedPassword, currentPassword);

            return result
            ? res.status(200).json({succeeded: true})
            : res.status(400).json({succeeded: false, message: result});
        }
        catch(error)
        {
            return res.status(500).json({succeeded: false, message: "Lỗi thay đổi mật khẩu: " + error.message});
        }
    }

    // API Đăng nhập bằng Google/Facebook OAuth
    static async oauthLogin(req, res) {
        try {
            // Flutter sẽ gửi những thông tin này lên
            const { email, fullName, avatar, provider, providerId } = req.body;

            if (!email || !provider || !providerId) {
                return res.status(400).json({ succeeded: false, message: "Thiếu thông tin xác thực từ Google/Facebook" });
            }

            // Kiểm tra xem email này đã từng đăng nhập/đăng ký vào hệ thống chưa
            let user = await userModel.findByEmail(email);

            // 🛑 CHẶN TÀI KHOẢN ĐÃ BỊ XÓA MỀM (Nếu tài khoản đã tồn tại nhưng bị vô hiệu hóa)
            // Đặt ở đây để chặn ngay lập tức, không cho phép cấp Token
            if (user && user.Trang_thai === 0) {
                return res.status(403).json({ 
                    succeeded: false, 
                    message: "Tài khoản này đã bị vô hiệu hóa hoặc bị xóa." 
                });
            }

            if (!user) {
                // KỊCH BẢN 1: TÀI KHOẢN HOÀN TOÀN MỚI
                // Tự động sinh ra một mật khẩu dài 32 ký tự vô nghĩa để "lách luật" Database
                const randomPassword = crypto.randomBytes(32).toString('hex');
                // Băm mật khẩu này ra
                const hashedPassword = await hash(randomPassword, parseInt(process.env.PASSWORD_HASH_ROUNDS) || 10);

                // Lưu vào Database
                const newId = await userModel.createOAuthUser({
                    email: email,
                    randomHashedPassword: hashedPassword,
                    fullName: fullName || 'Người dùng ẩn danh',
                    provider: provider, // 'Google' hoặc 'Facebook'
                    providerId: providerId,
                    avatar: avatar
                });

                if (!newId) return res.status(500).json({ succeeded: false, message: "Tạo tài khoản thất bại" });

                // Lấy lại thông tin user vừa tạo để cấp Token
                user = await userModel.findById(newId);
            } 
            // KỊCH BẢN 2: TÀI KHOẢN ĐÃ TỒN TẠI
            // Cấp Token để vào App
            const token = await userController.generateToken(user);
            
            return res.status(200).json({ 
                succeeded: true, 
                token: token, 
                role: user.Phan_quyen,
                id: user.Ma_nguoi_dung 
            });

        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // API Xóa tài khoản
    static async deleteAccount(req, res) {
        try {
            // Lấy ID người dùng do Flutter gửi lên
            const { userId } = req.body;

            if (!userId) {
                return res.status(400).json({ succeeded: false, message: "Không tìm thấy thông tin người dùng" });
            }

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
}