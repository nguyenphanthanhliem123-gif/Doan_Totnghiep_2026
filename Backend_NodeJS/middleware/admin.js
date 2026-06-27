import jsonwebtoken from 'jsonwebtoken';
import { execute } from "../config/db.js";

const { verify } = jsonwebtoken;
// Sử dụng khóa bảo mật của Admin (khớp với file adminController)
const ADMIN_JWT_SECRET = process.env.ADMIN_JWT_SECRET || "AdminSecretKey123";

export default async function adminAuth(req, res, next) {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ success: false, message: 'Không tìm thấy Token xác thực Admin' });
        }
        
        const token = authHeader.split(' ')[1];

        let decoded;
        try {
            // Giải mã bằng SECRET của Admin
            decoded = verify(token, ADMIN_JWT_SECRET);
        } catch (err) {
            return res.status(401).json({ success: false, message: 'Token Admin không hợp lệ hoặc đã hết hạn' });
        }

        const { id, role } = decoded;
        
        // Kiểm tra Role được nhúng trong Token lúc login
        if (role !== 'admin') {
            return res.status(403).json({ success: false, message: 'Không có quyền truy cập khu vực Quản trị' });
        }

        // Truy vấn thẳng vào bảng admins
        const sql = `SELECT id, email, is_locked FROM admins WHERE id = ?`;
        const [rows] = await execute(sql, [id]);
        
        if (rows.length === 0) {
            return res.status(401).json({ success: false, message: 'Tài khoản Admin không tồn tại' });
        }

        const adminUser = rows[0];

        // is_locked = 1 nghĩa là bị khóa
        if (adminUser.is_locked === 1) {
            return res.status(403).json({ success: false, message: 'Tài khoản Admin này đang bị tạm khóa' });
        }

        // Gán dữ liệu vào Request để các Controller (như Dashboard, Duyệt bác sĩ) sử dụng
        req.adminId = adminUser.id;
        req.adminEmail = adminUser.email;
        
        next();
        
    } catch (error) {
        console.error("LỖI ADMIN_AUTH:", error); 
        return res.status(500).json({ success: false, message: 'Lỗi hệ thống xác thực: ' + error.message });
    }
}