import { execute } from "../config/db.js";
import { hash, compare } from 'bcrypt';

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

    // Hàm tạo người dùng mới
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

    // Hàm tạo người dùng mới từ OAuth
    static async createOAuthUser({ email, randomHashedPassword, fullName, provider, providerId, avatar }) {
        try {
            const [result] = await execute(
                'INSERT INTO `nguoi_dung`(`Ten_nguoi_dung`, `Email`, `Mat_khau`, `Phan_quyen`, `Dang_nhap_Oauth`, `Ma_DN_Oauth`, `Anh_dai_dien`) VALUES (?, ?, ?, ?, ?, ?, ?)',
                [fullName, email, randomHashedPassword, 'Benh_nhan', provider, providerId, avatar]
            );
            return result.affectedRows > 0 ? result.insertId : null;
        } catch(error) {
            throw new Error(error.message);
        }
    }

    // Hàm cập nhật mật khẩu mới
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

    static async changePassword(userID, newHashedPassword, currentPassword){
        try{
            const [currentPasswordInDB] = await execute(`
                    SELECT
                        nguoi_dung.Mat_khau
                    FROM
                        nguoi_dung
                    WHERE
                        nguoi_dung.Ma_nguoi_dung = ?
                `,[userID]);

            if(currentPasswordInDB.length < 1) throw new Error("Không tìm thấy người dùng này");
            
            const isMatch = await compare(currentPassword, currentPasswordInDB[0].Mat_khau);

            if(!isMatch) throw new Error("Mật khẩu xác nhận không đúng");
            
            const [result] = await execute(`
                    UPDATE nguoi_dung 
                    SET Mat_khau = ? 
                    WHERE Ma_nguoi_dung = ?
                `,[newHashedPassword, userID])

            return result.affectedRows > 0 ? true: false;
        }
        catch(error){
            throw new Error("Lỗi UserModel.changePassword: " + error.message);
        }
    }
}