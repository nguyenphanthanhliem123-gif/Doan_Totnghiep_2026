import { execute } from "../config/db.js";

export default class userModel {
    static async findByEmail(email) {
        try {
            const [rows] = await execute("SELECT * FROM nguoi_dung WHERE Email = ? LIMIT 1", [email]);
            return rows[0] ?? null;
        } catch (error) {
            throw new Error("Lỗi Database: " + error.message);
        }
    }

    static async findById(ma_nguoi_dung){
        try {
            const [rows] = await execute("SELECT * FROM nguoi_dung WHERE Ma_nguoi_dung = ? LIMIT 1", [ma_nguoi_dung]);
            return rows[0] ?? null;
        } catch (error) {
            throw new Error("Lỗi Database: " + error.message);
        }
    }

    static async create({ email, phoneNumber, hashedPassword, fullName }) {
        try {
            const [result] = await execute(
                'INSERT INTO `nguoi_dung`(`Ten_nguoi_dung`, `Email`, `Dien_thoai`, `Mat_khau`, `Phan_quyen`) VALUES (?, ?, ?, ?, ?)',
                [fullName, email, phoneNumber, hashedPassword, 'Benh_nhan']
            );
            return result.affectedRows > 0 ? result.insertId : null;
        } catch(error) {
            throw new Error(error.message);
        }
    }

    // ĐÃ THÊM: Hàm cập nhật mật khẩu mới
    static async updatePassword(email, newHashedPassword) {
        try {
            const [result] = await execute(
                'UPDATE nguoi_dung SET Mat_khau = ? WHERE Email = ?',
                [newHashedPassword, email]
            );
            return result.affectedRows > 0;
        } catch (error) {
            throw new Error("Lỗi Database: " + error.message);
        }
    }
}