import jsonwebtoken from 'jsonwebtoken';
import { execute } from "../config/db.js";

const { verify } = jsonwebtoken;
const JWT_SECRET = process.env.JWT_SECRET;

export default async function auth(req, res, next) {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ message: 'Không tìm thấy Token xác thực' });
        }
        
        const token = authHeader.split(' ')[1];

        // Dùng try-catch ẩn để bắt lỗi Token hết hạn/sai chữ ký
        let decoded;
        try {
            decoded = verify(token, JWT_SECRET);
        } catch (err) {
            return res.status(401).json({ message: 'Token không hợp lệ hoặc đã hết hạn' });
        }

        const { id } = decoded;
        if (!id) return res.status(401).json({ message: 'Dữ liệu Token không hợp lệ' });

        // 🌟 BỎ USERMODEL, DÙNG EXECUTE TRỰC TIẾP ĐỂ TRÁNH NGHẼN KẾT NỐI
        const sql = `SELECT Ten_nguoi_dung, Phan_quyen, Trang_thai FROM nguoi_dung WHERE Ma_nguoi_dung = ?`;
        const [rows] = await execute(sql, [id]);
        
        if (rows.length === 0) {
            return res.status(401).json({ message: 'Người dùng không tồn tại' });
        }

        const user = rows[0];

        // Kiểm tra tài khoản có bị khóa không
        if (user.Trang_thai === 0) {
            return res.status(403).json({ message: 'Tài khoản này đã bị vô hiệu hóa' });
        }

        // Gán dữ liệu vào Request để các Controller xài
        req.Ma_nguoi_dung = id;
        req.username = user.Ten_nguoi_dung;
        req.Phan_quyen = user.Phan_quyen; 
        req.token = token;
        
        next();
        
    } catch (error) {
        // In lỗi màu đỏ ra Terminal Node.js để bạn dễ debug nếu có lỗi thật
        console.error("LỖI AUTH.JS:", error); 
        return res.status(500).json({ message: 'Lỗi hệ thống xác thực: ' + error.message });
    }
}