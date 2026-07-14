import { beginTransaction, commitTransaction, execute, rollbackTransaction } from "../config/db.js";
import { hash, compare } from 'bcrypt';

export default class userModel {
    // Hàm tìm kiếm người dùng theo email
    static async findByEmail(email) {
        try {
            const query = `
                SELECT nd.*, bs.Ma_bac_si 
                FROM nguoi_dung nd
                LEFT JOIN bac_si bs ON nd.Ma_nguoi_dung = bs.Ma_nguoi_dung
                WHERE nd.Email = ? 
                LIMIT 1
            `;
            
            const [rows] = await execute(query, [email]);
            return rows[0] ?? null;
        } catch (error) {
            throw new Error("Lỗi Database: " + error.message);
        }
    }

    // Hàm tìm kiếm người dùng theo ID
    static async findById(ma_nguoi_dung){
        try {
            const [rows] = await execute("SELECT * FROM nguoi_dung WHERE Ma_nguoi_dung = ? LIMIT 1", [ma_nguoi_dung]);
            return rows[0] ?? null;
        } catch (error) {
            throw new Error("Lỗi Database: " + error.message);
        }
    }

    // Hàm tạo người dùng mới
    static async create({ email, hashedPassword, fullName }) {
        let conn = await beginTransaction();
        try {
            // Tạo tài khoản bên bảng nguoi_dung
            const [result] = await conn.execute(
                'INSERT INTO `nguoi_dung`(`Ten_nguoi_dung`, `Email`, `Mat_khau`, `Phan_quyen`) VALUES (?, ?, ?, ?)',
                [fullName, email, hashedPassword, 'Benh_nhan']
            );
            
            const newUserId = result.insertId;

            console.log('New userID: ' + newUserId);

            // Tạo 1 dòng trống bên bảng benh_nhan
            if (newUserId) {
                const [patienId] = await conn.execute(
                    'INSERT INTO `benh_nhan`(`Ma_nguoi_dung`) VALUES (?)',
                    [newUserId]
                );

                await conn.execute(`
                    INSERT INTO nguoi_than(Ma_benh_nhan, Ten_nguoi_than, Quan_he)
                    VALUES(?, ?, 'Bản thân')  
                `,[patienId.insertId, fullName]);
                await commitTransaction(conn);
                return newUserId;
            }
            await rollbackTransaction(conn);
            return null;
        } catch(error) {
            await rollbackTransaction(conn);
            console.log('Lỗi create account: ' + error.message);
            throw new Error(error.message);
        }
    }

    // Hàm tạo người dùng mới từ OAuth
    static async createOAuthUser({ email, randomHashedPassword, fullName, provider, providerId, avatar }) {
        try {
            // Bước 1: Tạo tài khoản bên bảng nguoi_dung
            const [result] = await execute(
                'INSERT INTO `nguoi_dung`(`Ten_nguoi_dung`, `Email`, `Mat_khau`, `Phan_quyen`, `Dang_nhap_Oauth`, `Ma_DN_Oauth`, `Anh_dai_dien`) VALUES (?, ?, ?, ?, ?, ?, ?)',
                [fullName, email, randomHashedPassword, 'Benh_nhan', provider, providerId, avatar]
            );
            
            const newUserId = result.insertId;

            // Bước 2: Tạo 1 dòng trống bên bảng benh_nhan
            if (newUserId) {
                await execute(
                    'INSERT INTO `benh_nhan`(`Ma_nguoi_dung`) VALUES (?)',
                    [newUserId]
                );
                return newUserId;
            }
            
            return null;
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

    // Hàm đổi mật khẩu (cần xác thực mật khẩu hiện tại)
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

    // Hàm xóa mềm tài khoản (Chuyển Trang_thai về 0)
    static async softDeleteUser(ma_nguoi_dung) {
        try {
            const [result] = await execute(
                'UPDATE nguoi_dung SET Trang_thai = 0 WHERE Ma_nguoi_dung = ?',
                [ma_nguoi_dung]
            );
            return result.affectedRows > 0;
        } catch (error) {
            throw new Error("Lỗi Database: " + error.message);
        }
    }

    // Hàm lưu mã OTP mới vào database
    static async saveOTP(email, otpHash, otpType) {
        try {
            // Trước khi lưu mã mới, vô hiệu hóa tất cả các mã cũ của email và loại này
            await execute(
                'UPDATE ma_otp SET Da_xac_thuc = 1 WHERE Email = ? AND Loai_otp = ?', 
                [email, otpType]
            );

            // Lưu mã mới với hạn 5 phút
            const [result] = await execute(
                `INSERT INTO ma_otp (Email, Otp_hash, Loai_otp, Het_han_luc) 
                 VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL 5 MINUTE))`,
                [email, otpHash, otpType]
            );
            return result.insertId;
        } catch (error) {
            throw new Error("Lỗi lưu OTP: " + error.message);
        }
    }

    // Hàm lấy mã OTP mới nhất chưa xác thực và chưa hết hạn
    static async getValidOTP(email, otpType) {
        try {
            const [rows] = await execute(
                `SELECT * FROM ma_otp 
                 WHERE Email = ? AND Loai_otp = ? AND Da_xac_thuc = 0 AND Het_han_luc > NOW() 
                 ORDER BY Ngay_tao DESC LIMIT 1`,
                [email, otpType]
            );
            return rows[0] ?? null;
        } catch (error) {
            throw new Error("Lỗi kiểm tra OTP: " + error.message);
        }
    }

    // Hàm đánh dấu mã OTP đã được sử dụng
    static async markOTPAsUsed(id) {
        try {
            await execute('UPDATE ma_otp SET Da_xac_thuc = 1 WHERE Ma_otp = ?', [id]);
        } catch (error) {
            throw new Error("Lỗi cập nhật OTP: " + error.message);
        }
    }

    // Hàm tăng số lần thử sai
    static async incrementOTPTries(id) {
        try {
            await execute('UPDATE ma_otp SET So_lan_thu = So_lan_thu + 1 WHERE Ma_otp = ?', [id]);
        } catch (error) {
            throw new Error("Lỗi cập nhật số lần thử: " + error.message);
        }
    }
}