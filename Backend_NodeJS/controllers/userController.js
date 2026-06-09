import { hash, compare } from 'bcrypt';
import jwt from 'jsonwebtoken';
import userModel from '../models/userModel.js';

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

    // API Đăng ký
    static async register(req, res) {
        try {
            // Thêm fullName vào đây
            const { email, phoneNumber, password, confirmPassword, fullName } = req.body;

            // Kiểm tra thiếu trường
            if (!email || !phoneNumber || !password || !confirmPassword || !fullName) {
                return res.status(400).json({ succeeded: false, message: 'Vui lòng điền đầy đủ thông tin' });
            }

            if (password !== confirmPassword) {
                return res.status(400).json({ succeeded: false, message: 'Mật khẩu xác nhận không khớp' });
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

            const hashedPassword = await hash(password, PASSWORD_HASH_ROUNDS);
            
            // Truyền thêm fullName xuống Model
            const newId = await userModel.create({ 
                email, 
                phoneNumber, 
                hashedPassword,
                fullName
            });

            if (!newId) return res.status(500).json({ succeeded: false, message: "Tạo tài khoản thất bại" });
            
            return res.status(201).json({
                succeeded: true, 
                message: 'Đăng ký thành công',
                user: { id: newId, email, phoneNumber, fullName }
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

            const isMatch = await compare(password, user.Mat_khau);
            if (!isMatch) {
                return res.status(401).json({ succeeded: false, message: "Email hoặc mật khẩu không đúng" });
            }

            const token = await userController.generateToken(user);
            // Đổi user.Vai_tro thành user.Phan_quyen
            return res.status(200).json({ succeeded: true, token: token, role: user.Phan_quyen });
            
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }
}