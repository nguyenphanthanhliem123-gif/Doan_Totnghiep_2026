import { beginTransaction, commitTransaction, execute, rollbackTransaction } from "../config/db.js";
import { decrypt, encrypt } from "../utils/cryptoUtil.js";

export default class healthRecordModel{
    static async getAllHealthRecordByUserID(userID){
        try{
            const sql = `
            SELECT 
                bn.Ma_benh_nhan,
                bn.Ma_nguoi_dung,
                nt.Ma_nguoi_than,
                
                -- Xử lý Tên hiển thị của hồ sơ
                COALESCE(nt.Ten_nguoi_than, nd.Ten_nguoi_dung) AS Ten_ho_so,
                
                -- Xử lý Vai trò / Mối quan hệ để dễ phân biệt trên giao diện
                COALESCE(nt.Quan_he, 'Chủ tài khoản') AS Vai_tro,
                
                bn.Ngay_sinh, 
                bn.Gioi_tinh, 
                bn.Dia_chi, 
                bn.Nhom_mau, 
                bn.Di_ung, 
                bn.Benh_nen,
                CASE WHEN nt.Ma_nguoi_than IS NOT NULL THEN nt.Dien_thoai ELSE nd.Dien_thoai END AS Dien_thoai
                
            FROM benh_nhan bn
            JOIN nguoi_dung nd ON bn.Ma_nguoi_dung = nd.Ma_nguoi_dung
            LEFT JOIN nguoi_than nt ON bn.Ma_benh_nhan = nt.Ma_benh_nhan
            WHERE bn.Ma_nguoi_dung = ?
            ORDER BY bn.Ma_benh_nhan ASC;`;

            const [result] = await execute(sql,[userID]);

            if(!result.length > 0) throw new Error("Không có hồ sơ sức khỏe nào");

            return result;
        }
        catch(error){
            throw new Error("Lỗi lấy hồ sơ sức khỏe người dùng(healthRecordModel.getAllHealthRecordByUserID): " + error.message);
        }
    }

    static async addRelativeProfile(userID, tenNguoiThan, moiQuanHe, birthDay, gender, address, nhomMau, diUng, benhNen, phone){
        let conn;
        try{
            conn = await beginTransaction();
            const encryptedNhomMau = encrypt(nhomMau);
            const encryptedDiUng = encrypt(diUng);
            const encryptedBenhNen = encrypt(benhNen);


            const sqlBenhNhan = `
                INSERT INTO benh_nhan 
                (Ma_nguoi_dung, Ngay_sinh, Gioi_tinh, Dia_chi, Nhom_mau, Di_ung, Benh_nen) 
                VALUES (?, ?, ?, ?, ?, ?, ?)
            `;

            const [resBenhNhan] = await conn.execute(sqlBenhNhan, [userID, birthDay, gender, address, encryptedNhomMau, encryptedDiUng, encryptedBenhNen]);

            const newMaBenhNhan = resBenhNhan.insertId;

            const sqlNguoiThan = `
                INSERT INTO nguoi_than 
                (Ma_benh_nhan, Ten_nguoi_than, Quan_he, Ngay_sinh, Dien_thoai) 
                VALUES (?, ?, ?, ?, ?)
            `;

            await conn.execute(sqlNguoiThan, [
                newMaBenhNhan, 
                tenNguoiThan || null, 
                moiQuanHe || null,
                birthDay,
                phone || null
            ]);

            await commitTransaction(conn);
            return true;
        }
        catch(error){
            await rollbackTransaction(conn);
            throw new Error('Lỗi thêm hồ sơ sức khỏe(healthRecordModel.addRelativeProfile): ' + error.message);
        }
    }

    static async updateHealthRecord(maBenhNhan, userID, tenHoSo, moiQuanHe, birthDay, gender, address, nhomMau, diUng, benhNen, phone) {
        let conn;
        try {
            conn = await beginTransaction();

            // 1. Mã hóa thông tin y tế bằng AES-256 trước khi lưu
            const encryptedNhomMau = encrypt(nhomMau);
            const encryptedDiUng = encrypt(diUng);
            const encryptedBenhNen = encrypt(benhNen);

            // 2. Cập nhật bảng benh_nhan (Kèm điều kiện Ma_nguoi_dung để tránh user này sửa hồ sơ của user khác)
            const sqlBenhNhan = `
                UPDATE benh_nhan 
                SET Ngay_sinh = ?, Gioi_tinh = ?, Dia_chi = ?, Nhom_mau = ?, Di_ung = ?, Benh_nen = ?
                WHERE Ma_benh_nhan = ? AND Ma_nguoi_dung = ?
            `;
            const [resBenhNhan] = await conn.execute(sqlBenhNhan, [
                birthDay, gender, address, encryptedNhomMau, encryptedDiUng, encryptedBenhNen, maBenhNhan, userID
            ]);

            // Nếu không có dòng nào thay đổi, nghĩa là hồ sơ không tồn tại hoặc không thuộc về user này
            if (resBenhNhan.affectedRows === 0) {
                throw new Error("Không tìm thấy hồ sơ hoặc bạn không có quyền chỉnh sửa.");
            }

            // 3. Cập nhật bảng nguoi_than hoặc nguoi_dung tùy theo vai trò của hồ sơ này
            // Kiểm tra xem hồ sơ này là Chủ tài khoản hay Người thân
            const [checkRelative] = await conn.execute(`SELECT Ma_nguoi_than FROM nguoi_than WHERE Ma_benh_nhan = ?`, [maBenhNhan]);

            if (checkRelative.length > 0) {
                // Tình huống 1: Là người thân -> Lưu SĐT vào bảng nguoi_than
                const sqlNguoiThan = `
                    UPDATE nguoi_than 
                    SET Ten_nguoi_than = ?, Quan_he = ?, Dien_thoai = ?
                    WHERE Ma_benh_nhan = ?
                `;
                await conn.execute(sqlNguoiThan, [tenHoSo, moiQuanHe, phone || null, maBenhNhan]);
            } else {
                // Tình huống 2: Là Bản thân (Chủ tài khoản) -> Lưu SĐT vào bảng nguoi_dung
                const sqlNguoiDung = `
                    UPDATE nguoi_dung 
                    SET Dien_thoai = ? 
                    WHERE Ma_nguoi_dung = ?
                `;
                // Dùng userID vì Chủ tài khoản sở hữu Ma_nguoi_dung này
                await conn.execute(sqlNguoiDung, [phone || null, userID]);
            }

            await commitTransaction(conn);
            return true;

        } catch (error) {
            if (conn) {
                await rollbackTransaction(conn);
            }
            throw new Error('Lỗi cập nhật hồ sơ (healthRecordModel.updateHealthRecord): ' + error.message);
        }
    }

    static async getHealthRecordDetail(maBenhNhan, userID) {
        try {
            const sql = `
                SELECT 
                    bn.Ma_benh_nhan, 
                    bn.Ngay_sinh, 
                    bn.Gioi_tinh, 
                    bn.Dia_chi, 
                    bn.Nhom_mau, 
                    bn.Di_ung, 
                    bn.Benh_nen,
                    COALESCE(nt.Ten_nguoi_than, nd.Ten_nguoi_dung) AS Ten_ho_so, 
                    COALESCE(nt.Quan_he, 'Chủ tài khoản') AS Vai_tro,
                    CASE WHEN nt.Ma_nguoi_than IS NOT NULL THEN nt.Dien_thoai ELSE nd.Dien_thoai END AS Dien_thoai
                FROM benh_nhan bn
                JOIN nguoi_dung nd ON bn.Ma_nguoi_dung = nd.Ma_nguoi_dung
                LEFT JOIN nguoi_than nt ON bn.Ma_benh_nhan = nt.Ma_benh_nhan
                WHERE bn.Ma_benh_nhan = ? AND bn.Ma_nguoi_dung = ?
            `;

            const [rows] = await execute(sql, [maBenhNhan, userID]);

            if (rows.length === 0) {
                return null;
            }

            const record = rows[0];

            try {
                record.Nhom_mau = record.Nhom_mau ? decrypt(record.Nhom_mau) : null;
                record.Di_ung = record.Di_ung ? decrypt(record.Di_ung) : null;
                record.Benh_nen = record.Benh_nen ? decrypt(record.Benh_nen) : null;
            } catch (decryptError) {
                console.error("Lỗi giải mã dữ liệu y tế: ", decryptError.message);
            }

            return record;
        } catch (error) {
            throw new Error('Lỗi model getHealthRecordDetail: ' + error.message);
        }
    }

    static async deleteHealthRecord(maBenhNhan, userID) {
        let conn;
        try {
            conn = await beginTransaction();

            // 1. Kiểm tra xem hồ sơ này có tồn tại và thuộc về user đang đăng nhập không
            const [checkRows] = await conn.execute(
                'SELECT Ma_benh_nhan FROM benh_nhan WHERE Ma_benh_nhan = ? AND Ma_nguoi_dung = ?',
                [maBenhNhan, userID]
            );

            if (checkRows.length === 0) {
                throw new Error("Không tìm thấy hồ sơ hoặc bạn không có quyền xóa hồ sơ này.");
            }

            // 2. Xóa dữ liệu trong bảng nguoi_than trước (Vì bạn đã lưu cả "bản thân" vào đây)
            await conn.execute(
                'DELETE FROM nguoi_than WHERE Ma_benh_nhan = ?', 
                [maBenhNhan]
            );

            // 3. Xóa dữ liệu gốc trong bảng benh_nhan
            await conn.execute(
                'DELETE FROM benh_nhan WHERE Ma_benh_nhan = ?', 
                [maBenhNhan]
            );

            await commitTransaction(conn);
            return true;
        } catch (error) {
            if (conn) {
                await rollbackTransaction(conn);
            }
            throw new Error('Lỗi model deleteHealthRecord: ' + error.message);
        }
    }

    // Thêm vào trong class HealthRecordModel
    static async deleteAllHealthRecords(userID) {
        let conn;
        try {
            conn = await beginTransaction();

            // 1. Tìm tất cả các hồ sơ (Ma_benh_nhan) thuộc về user này
            const [rows] = await conn.execute(
                'SELECT Ma_benh_nhan FROM benh_nhan WHERE Ma_nguoi_dung = ?', 
                [userID]
            );

            if (rows.length > 0) {
                const maBenhNhanList = rows.map(r => r.Ma_benh_nhan);
                const placeholders = maBenhNhanList.map(() => '?').join(',');

                // 2. Xóa các bản ghi liên quan trong bảng nguoi_than trước (để không dính lỗi khóa ngoại)
                await conn.execute(
                    `DELETE FROM nguoi_than WHERE Ma_benh_nhan IN (${placeholders})`, 
                    maBenhNhanList
                );

                // 3. Xóa toàn bộ hồ sơ trong bảng benh_nhan
                await conn.execute(
                    'DELETE FROM benh_nhan WHERE Ma_nguoi_dung = ?', 
                    [userID]
                );
            }

            await commitTransaction(conn);
            return true;
        } catch (error) {
            if (conn) {
                await rollbackTransaction(conn);
            }
            throw new Error('Lỗi model deleteAllHealthRecords: ' + error.message);
        }
    }
}