import { hash, compare } from 'bcrypt';
import jwt from 'jsonwebtoken';
import adminModel from '../models/adminModel.js';
import userModel from '../models/userModel.js'; // Tận dụng các hàm saveOTP/getValidOTP của bạn
import { generateOTP } from '../utils/otpHelper.js';
import { sendOTPEmail } from '../config/emailConfig.js';
import appointmentModel from '../models/AppointmentModel.js';

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
            
            // 1. Nếu không tìm thấy mã OTP hợp lệ/hết hạn
            if (!otpRecord) {
                return res.status(400).json({ success: false, message: 'Mã OTP không tồn tại hoặc đã hết hạn' });
            }

            // 2. So sánh mã OTP người dùng nhập vào
            const isMatch = await compare(otp, otpRecord.Otp_hash);

            if (!isMatch) {
                // Tăng số lần thử sai trong bảng ma_otp lên 1
                await userModel.incrementOTPTries(otpRecord.Ma_otp);
                
                // Lấy lại dữ liệu mới nhất để kiểm tra số lần thử
                const currentTries = otpRecord.So_lan_thu + 1; 
                
                if (currentTries >= 5) {
                    // Vô hiệu hóa mã OTP này ngay lập tức nếu sai quá 5 lần
                    await userModel.markOTPAsUsed(otpRecord.Ma_otp);
                    return res.status(400).json({ success: false, message: 'Mã OTP đã bị vô hiệu hóa do nhập sai quá 5 lần. Vui lòng đăng nhập lại để lấy mã mới.' });
                }

                return res.status(400).json({ success: false, message: `Mã OTP không hợp lệ. Bạn còn ${5 - currentTries} lần thử.` });
            }

            // 3. Nếu đúng OTP -> Tiến hành xử lý đăng nhập thành công
            await userModel.markOTPAsUsed(otpRecord.Ma_otp);
            await adminModel.resetFailedAttempts(email);

            const admin = await adminModel.findByEmail(email);
            const token = jwt.sign(
                { id: admin.id, role: 'admin' }, 
                process.env.ADMIN_JWT_SECRET || "AdminSecretKey123", 
                { expiresIn: '8h' }
            );

            return res.status(200).json({ success: true, token, message: 'Đăng nhập thành công' });
        } catch (e) {
            return res.status(500).json({ success: false, message: e.message });
        }
    }
    
    static async getDashboard(req, res) {
        try {
            const stats = await adminModel.getDashboardStats();
            return res.status(200).json({
                success: true,
                message: 'Lấy dữ liệu tổng quan thành công',
                data: stats
            });
        } catch (error) {
            return res.status(500).json({ 
                success: false, 
                message: error.message 
            });
        }
    }

    static async lockAccount(req,res){
        try{
            const adminId = req.adminId;
            const {action, target_type, target_id, reason} = req.body;

            if(!action || !target_id || !target_type || !reason) return res.status(400).json({
                success: false,
                message: 'Không được bỏ trống các thông tin cần thiết.'
            });

            const adminLogs = {
                action,
                target_type,
                reason
            };

            const resultId = await adminModel.lockAccount(target_id, adminId, adminLogs);
            
            return res.status(200).json({
                success: true,
            });
        }catch(error){
            return res.status(500).json({
                success: false,
                message: error.message
            });
        }
    }

    static async unLockAccount(req,res){
        try{
            const adminId = req.adminId;
            const {action, target_type, target_id, reason} = req.body;

            if(!action || !target_id || !target_type || !reason) return res.status(400).json({
                success: false,
                message: 'Không được bỏ trống các thông tin cần thiết.'
            });

            const adminLogs = {
                action,
                target_type,
                reason
            };

            const resultId = await adminModel.unLockAccount(target_id, adminId, adminLogs);
            
            return res.status(200).json({
                success: true,
            });
        }catch(error){
            return res.status(500).json({
                success: false,
                message: error.message
            });
        }
    }

    static async getAllUser(req,res){
        try{
            const users = await adminModel.getAllUser();

            if(users.length > 0){
                return res.status(200).json({
                    success: true,
                    users: users
                });
            }else{
                return res.status(204).json({
                    success: false,
                    message: "Không tìm thấy bất kì người dùng nào"
                });
            }
        }catch(error){
            return res.status(500).json({
                success: false,
                message: error.message
            });
        }
    }

    static async getDetails(req, res) {
        try {
            const appointmentID = req.params.id;

            if (!appointmentID) return res.status(400).json({ succeeded: false, message: "Thiếu mã lịch hẹn." });

            const detail = await appointmentModel.getAppointmentDetails(appointmentID);

            if (!detail) return res.status(404).json({ succeeded: false, message: "Không tìm thấy lịch hẹn này." });

            console.log(detail);

            return res.status(200).json({
                succeeded: true,
                message: "Lấy chi tiết lịch hẹn thành công",
                data: detail
            });

        } catch (error) {
            return res.status(500).json({ succeeded: false, message: "Lỗi server: " + error.message });
        }
    }

    static async getAppointmentListByUserId(req, res) {
        try {
            const userID = req.params.id; 

            if (!userID) {
                return res.status(400).json({ succeeded: false, message: "Không tìm thấy thông tin người dùng." });
            }

            const appointments = await appointmentModel.getAllPatienAppointment(userID);

            return res.status(200).json({
                succeeded: true,
                message: "Lấy danh sách lịch hẹn thành công",
                data: appointments
            });

        } catch (error) {
            return res.status(500).json({ succeeded: false, message: "Lỗi server: " + error.message });
        }
    }
}