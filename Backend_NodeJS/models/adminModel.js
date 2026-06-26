import { execute } from "../config/db.js";

export default class adminModel {
    static async findByEmail(email) {
        // Lấy đúng tên bảng 'admins'
        const [rows] = await execute('SELECT * FROM admins WHERE email = ? LIMIT 1', [email]);
        return rows[0] ?? null;
    }

    static async incrementFailedAttempts(email) {
        // Cập nhật tăng biến đếm, nếu >= 5 thì khóa tài khoản
        await execute('UPDATE admins SET failed_attempts = failed_attempts + 1 WHERE email = ?', [email]);
        await execute('UPDATE admins SET is_locked = 1 WHERE email = ? AND failed_attempts >= 5', [email]);
    }

    static async resetFailedAttempts(email) {
        await execute('UPDATE admins SET failed_attempts = 0 WHERE email = ?', [email]);
    }
}