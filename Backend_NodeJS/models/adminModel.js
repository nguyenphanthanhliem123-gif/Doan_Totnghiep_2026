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

    static async getDashboardStats() {
        try {
            // Quét và hủy các ca 'pending' quá hạn
            // 1. Ghi log lịch sử thay đổi trạng thái bởi hệ thống
            const insertHistorySql = `
                INSERT INTO lich_su_trang_thai_lich_hen (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Nguoi_thay_doi)
                SELECT lh.Ma_lich_hen, 'pending', 'cancelled', 'system'
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                WHERE lh.Trang_thai_lich_hen = 'pending' AND kg.Thoi_gian_Bdau < NOW()
            `;
            await execute(insertHistorySql);

            // 2. Trả khung giờ về trạng thái trống (available) để người khác đặt
            const releaseSlotSql = `
                UPDATE khung_gio_kham kg
                JOIN lich_hen lh ON lh.Ma_khung_gio = kg.Ma_khung_gio
                SET kg.Trang_thai = 'available'
                WHERE lh.Trang_thai_lich_hen = 'pending' AND kg.Thoi_gian_Bdau < NOW()
            `;
            await execute(releaseSlotSql);

            // 3. Chuyển trạng thái lịch hẹn sang hủy
            const cleanupSql = `
                UPDATE lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                SET lh.Trang_thai_lich_hen = 'cancelled'
                WHERE lh.Trang_thai_lich_hen = 'pending' AND kg.Thoi_gian_Bdau < NOW()
            `;
            await execute(cleanupSql);
            
            // Truy vấn số liệu đưa lên dashboard admin
            // 1. Tổng số bác sĩ đang hoạt động (Tài khoản 'active' và người dùng chưa bị khóa Trang_thai = 1)
            const [activeDoctors] = await execute(`
                SELECT COUNT(*) as count 
                FROM bac_si bs 
                JOIN nguoi_dung nd ON bs.Ma_nguoi_dung = nd.Ma_nguoi_dung 
                WHERE bs.Trang_thai_hoat_dong = 'active' AND nd.Trang_thai = 1
            `);

            // 2. Tổng số bệnh nhân đã đăng ký (Người dùng có vai trò Benh_nhan và Trang_thai = 1)
            const [totalPatients] = await execute(`
                SELECT COUNT(*) as count 
                FROM benh_nhan bn 
                JOIN nguoi_dung nd ON bn.Ma_nguoi_dung = nd.Ma_nguoi_dung 
                WHERE nd.Trang_thai = 1
            `);

            // 3. Số hồ sơ bác sĩ mới đăng ký đang chờ duyệt (Trang_thai_hoat_dong = 'pending')
            const [pendingDoctors] = await execute(`
                SELECT COUNT(*) as count 
                FROM bac_si 
                WHERE Trang_thai_hoat_dong = 'pending'
            `);

            // 4. Số khiếu nại của bệnh nhân/bác sĩ chưa xử lý (status = 'open')
            const [openComplaints] = await execute(`
                SELECT COUNT(*) as count 
                FROM complaints 
                WHERE status = 'open'
            `);

            // 5. Số lịch hẹn diễn ra trong hôm nay
            const [todayAppointments] = await execute(`
                SELECT COUNT(*) as count 
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                WHERE DATE(kg.Thoi_gian_Bdau) = CURDATE()
            `);

            return {
                activeDoctors: activeDoctors[0].count,
                totalPatients: totalPatients[0].count,
                pendingDoctors: pendingDoctors[0].count,
                openComplaints: openComplaints[0].count,
                todayAppointments: todayAppointments[0].count
            };
        } catch (error) {
            throw new Error("Lỗi truy vấn dữ liệu Dashboard Admin: " + error.message);
        }
    }

    // Lấy danh sách toàn bộ hồ sơ bác sĩ Đang chờ duyệt (Trang_thai_hoat_dong = 'pending')
    static async getPendingDoctors() {
        try {
            const [rows] = await execute(`
                SELECT 
                    b.Ma_bac_si, 
                    n.Ten_nguoi_dung, 
                    n.Email, 
                    n.Anh_dai_dien, 
                    b.Hoc_vi, 
                    b.Nam_kinh_nghiem, 
                    b.Anh_chung_chi,
                    ck.Ten_chuyen_khoa
                FROM bac_si b
                JOIN nguoi_dung n ON b.Ma_nguoi_dung = n.Ma_nguoi_dung
                JOIN chuyen_khoa ck ON b.Ma_chuyen_khoa = ck.Ma_chuyen_khoa
                WHERE b.Trang_thai_hoat_dong = 'pending'
                ORDER BY n.Ma_nguoi_dung DESC
            `);
            return rows;
        } catch (error) {
            throw new Error("Lỗi lấy danh sách bác sĩ chờ duyệt: " + error.message);
        }
    }

    // Xử lý Duyệt ('active') hoặc Từ chối ('suspended') kèm ghi nhận nhật ký log hệ thống
    static async updateDoctorStatus(maBacSi, status, adminId, reason = null) {
        try {
            // 1. Cập nhật cột Trang_thai_hoat_dong trong bảng bác sĩ
            await execute(
                `UPDATE bac_si SET Trang_thai_hoat_dong = ? WHERE Ma_bac_si = ?`,
                [status, maBacSi]
            );

            // 2. Ghi lịch sử hành động vào bảng admin_logs
            await execute(
                `INSERT INTO admin_logs (Admin_id, Target_type, Target_id, Action, Reason) 
                 VALUES (?, 'BAC_SI', ?, ?, ?)`,
                [adminId, maBacSi, status === 'active' ? 'APPROVE' : 'REJECT', reason]
            );

            // 3. Lấy ra thông tin email và tên bác sĩ phục vụ gửi thư thông báo
            const [info] = await execute(`
                SELECT n.Ten_nguoi_dung, n.Email 
                FROM bac_si b 
                JOIN nguoi_dung n ON b.Ma_nguoi_dung = n.Ma_nguoi_dung 
                WHERE b.Ma_bac_si = ?
            `, [maBacSi]);

            return info[0];
        } catch (error) {
            throw new Error("Lỗi cập nhật trạng thái hồ sơ: " + error.message);
        }
    }

    // ==========================================
    // QUẢN LÝ CHUYÊN KHOA
    // ==========================================

    // Lấy danh sách chuyên khoa (Dành cho Admin: Lấy tất cả)
    static async getAllSpecialtiesAdmin() {
        try {
            const [rows] = await execute(`SELECT * FROM chuyen_khoa ORDER BY Ma_chuyen_khoa DESC`);
            return rows;
        } catch (error) {
            throw new Error("Lỗi lấy danh sách chuyên khoa: " + error.message);
        }
    }

    // Thêm chuyên khoa mới
    static async createSpecialty(ten, moTa, iconPath) {
        try {
            const query = `INSERT INTO chuyen_khoa (Ten_chuyen_khoa, Mo_ta, Icon, Trang_thai) VALUES (?, ?, ?, 1)`;
            const [result] = await execute(query, [ten, moTa, iconPath]);
            return result.insertId;
        } catch (error) {
            throw new Error("Lỗi thêm chuyên khoa: " + error.message);
        }
    }

    // Cập nhật chuyên khoa
    static async updateSpecialty(id, ten, moTa, iconPath) {
        try {
            let query = `UPDATE chuyen_khoa SET Ten_chuyen_khoa = ?, Mo_ta = ?`;
            let params = [ten, moTa];

            if (iconPath) {
                query += `, Icon = ?`;
                params.push(iconPath);
            }

            query += ` WHERE Ma_chuyen_khoa = ?`;
            params.push(id);

            const [result] = await execute(query, params);
            return result.affectedRows;
        } catch (error) {
            throw new Error("Lỗi cập nhật chuyên khoa: " + error.message);
        }
    }

    // Ẩn / Hiện chuyên khoa
    static async toggleSpecialtyStatus(id, status) {
        try {
            const query = `UPDATE chuyen_khoa SET Trang_thai = ? WHERE Ma_chuyen_khoa = ?`;
            const [result] = await execute(query, [status, id]);
            return result.affectedRows;
        } catch (error) {
            throw new Error("Lỗi cập nhật trạng thái chuyên khoa: " + error.message);
        }
    }
}