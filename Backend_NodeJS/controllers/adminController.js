import { hash, compare } from 'bcrypt';
import jwt from 'jsonwebtoken';
import path from 'path'; // CẦN THIẾT ĐỂ XỬ LÝ LƯU ẢNH ICON
import adminModel from '../models/adminModel.js';
import userModel from '../models/userModel.js'; // Tận dụng các hàm saveOTP/getValidOTP của bạn
import { generateOTP } from '../utils/otpHelper.js';
import { sendOTPEmail } from '../config/emailConfig.js';
import appointmentModel from '../models/AppointmentModel.js';
import EmailService from "../services/emailService.js";
import ReportModel from '../models/reportModel.js';
import ServiceModel from '../models/serviceModel.js';

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
    // Lấy danh sách hồ sơ đang đợi duyệt
    static async getPendingDoctorsList(req, res) {
        try {
            const doctors = await adminModel.getPendingDoctors();
            return res.status(200).json({
                success: true,
                doctors: doctors
            });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    }

    // Chấp thuận duyệt kích hoạt tài khoản bác sĩ
    static async approveDoctor(req, res) {
        try {
            const { maBacSi } = req.body;
            const adminId = req.adminId;

            if (!maBacSi) {
                return res.status(400).json({ success: false, message: "Thiếu mã bác sĩ" });
            }

            // Truyền trạng thái chuỗi 'active' khớp với ENUM trong database
            const doctorInfo = await adminModel.updateDoctorStatus(maBacSi, 'active', adminId, "Hồ sơ hợp lệ");

            if (doctorInfo) {
                // Gửi thư chúc mừng bác sĩ
                EmailService.sendDoctorApprovalEmail(doctorInfo.Email, doctorInfo.Ten_nguoi_dung);
            }

            return res.status(200).json({
                success: true,
                message: `Đã duyệt thành công bác sĩ ${doctorInfo?.Ten_nguoi_dung || ''}`
            });
        } catch (error) {
            console.error("❌ LỖI:", error.message); // In đậm lỗi ra terminal Node
            return res.status(500).json({ success: false, message: error.message });
        }
    }

    // Từ chối hồ sơ kèm lý do cụ thể
    static async rejectDoctor(req, res) {
        try {
            const { maBacSi, reason } = req.body;
            const adminId = req.adminId;

            if (!maBacSi || !reason) {
                return res.status(400).json({ success: false, message: "Vui lòng cung cấp mã bác sĩ và lý do từ chối" });
            }

            // Truyền trạng thái chuỗi 'suspended' khi từ chối kích hoạt hồ sơ
            const doctorInfo = await adminModel.updateDoctorStatus(maBacSi, 'suspended', adminId, reason);

            if (doctorInfo) {
                // Gửi thư thông báo kèm lý do bác sĩ bị loại
                EmailService.sendDoctorRejectionEmail(doctorInfo.Email, doctorInfo.Ten_nguoi_dung, reason);
            }

            return res.status(200).json({
                success: true,
                message: `Đã từ chối hồ sơ của bác sĩ ${doctorInfo?.Ten_nguoi_dung || ''}`
            });
        } catch (error) {
            console.error("❌ LỖI:", error.message); // In đậm lỗi ra terminal Node
            return res.status(500).json({ success: false, message: error.message });
        }
    }

    // ==========================================
    // QUẢN LÝ CHUYÊN KHOA
    // ==========================================

    // API: Lấy toàn bộ chuyên khoa
    static async getAllSpecialties(req, res) {
        try {
            const specialties = await adminModel.getAllSpecialtiesAdmin();
            return res.status(200).json({ success: true, data: specialties });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    }

    // API: Tạo chuyên khoa mới
    static async createSpecialty(req, res) {
        try {
            const { tenChuyenKhoa, moTa } = req.body;

            if (!tenChuyenKhoa) {
                return res.status(400).json({ success: false, message: 'Vui lòng nhập tên chuyên khoa' });
            }

            let iconPath = null;
            // Xử lý lưu ảnh nếu có file gửi lên
            if (req.files && req.files.icon) {
                const uploadDir = path.join(process.cwd(), 'uploads');
                const iconFile = req.files.icon;
                const iconName = `ck_${Date.now()}_${iconFile.name.replace(/\s+/g, '')}`;
                const savePath = path.join(uploadDir, iconName);
                
                await iconFile.mv(savePath);
                iconPath = `/uploads/${iconName}`;
            }

            await adminModel.createSpecialty(tenChuyenKhoa, moTa || '', iconPath);
            return res.status(201).json({ success: true, message: 'Thêm chuyên khoa thành công!' });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    }

    // API: Cập nhật thông tin chuyên khoa
    static async updateSpecialty(req, res) {
        try {
            const { id } = req.params;
            const { tenChuyenKhoa, moTa } = req.body;

            if (!tenChuyenKhoa) {
                return res.status(400).json({ success: false, message: 'Vui lòng nhập tên chuyên khoa' });
            }

            let iconPath = null;
            // Xử lý lưu ảnh mới nếu có ghi đè
            if (req.files && req.files.icon) {
                const uploadDir = path.join(process.cwd(), 'uploads');
                const iconFile = req.files.icon;
                const iconName = `ck_${Date.now()}_${iconFile.name.replace(/\s+/g, '')}`;
                const savePath = path.join(uploadDir, iconName);
                
                await iconFile.mv(savePath);
                iconPath = `/uploads/${iconName}`;
            }

            await adminModel.updateSpecialty(id, tenChuyenKhoa, moTa || '', iconPath);
            return res.status(200).json({ success: true, message: 'Cập nhật chuyên khoa thành công!' });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    }

    // API: Ẩn/Hiện chuyên khoa
    static async toggleSpecialtyStatus(req, res) {
        try {
            const { id } = req.params;
            const { status } = req.body; // Truyền 1 (Hiện) hoặc 0 (Ẩn)

            if (status === undefined) {
                return res.status(400).json({ success: false, message: 'Thiếu thông tin trạng thái cập nhật' });
            }

            await adminModel.toggleSpecialtyStatus(id, status);
            return res.status(200).json({ success: true, message: 'Cập nhật trạng thái thành công!' });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    }

    static async getReports(req, res) {
        try {
            const reports = await ReportModel.getAllReports();
            return res.status(200).json({ success: true, reports });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    }

    // Xử lý khiếu nại
    static async handleReport(req, res) {
        try {
            const adminId = req.adminId;
            const { reportId } = req.params;
            const { action, adminNote, targetUserId } = req.body; 
            // action: 'canh_cao', 'khoa', 'bo_qua'

            if (!action || !targetUserId) {
                return res.status(400).json({ success: false, message: 'Thiếu thông tin xử lý' });
            }
            const io = req.app.get('io');
            await ReportModel.resolveReport(reportId, action, adminNote, targetUserId, adminId, io);

            return res.status(200).json({ success: true, message: 'Đã đóng Case khiếu nại thành công' });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    }

    static async adminCreate(req, res) {
        try {
            const { name, specId, defaultPrice } = req.body;
            if (!name || !specId || !defaultPrice) {
                return res.status(400).json({ success: false, message: "Thiếu thông tin" });
            }
            await ServiceModel.createMasterService(name, specId, defaultPrice);
            return res.status(200).json({ success: true, message: "Thêm thành công!" });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    }

    static async adminGetServices(req, res) {
        try {
            const { search, specId } = req.query;
            const services = await ServiceModel.getMasterServices(search, specId);
            return res.status(200).json({ success: true, data: services });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    }

    static async adminUpdateService(req, res) {
        try {
            const { id } = req.params;
            const { name, specId, defaultPrice } = req.body;
            
            if (!name || !specId || defaultPrice === undefined) {
                return res.status(400).json({ success: false, message: "Vui lòng điền đủ thông tin" });
            }

            await ServiceModel.updateMasterService(id, name, specId, defaultPrice);
            return res.status(200).json({ success: true, message: "Cập nhật dịch vụ thành công!" });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    }

    static async adminDeleteService(req, res) {
        try {
            const { id } = req.params;
            await ServiceModel.deleteMasterService(id);
            return res.status(200).json({ success: true, message: "Đã xóa dịch vụ!" });
        } catch (error) {
            if(error.message.includes('foreign key constraint')) {
                return res.status(400).json({ success: false, message: "Không thể xóa vì đã có bác sĩ đăng ký dịch vụ này."});
            }
            return res.status(500).json({ success: false, message: error.message });
        }
    }

    static async getTodayAppointmentsList(req, res) {
        try {
            const appointments = await adminModel.getTodayAppointments();
            return res.status(200).json({
                success: true,
                data: appointments
            });
        } catch (error) {
            return res.status(500).json({ success: false, message: error.message });
        }
    }
}