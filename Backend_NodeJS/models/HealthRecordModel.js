import { beginTransaction, commitTransaction, execute, rollbackTransaction } from "../config/db.js";
import { decrypt, encrypt } from "../utils/cryptoUtil.js";

export default class healthRecordModel{
    static async getAllHealthRecordByUserID(userID){
        try{
            const sql = `
            SELECT 
                bn.Ma_benh_nhan,
                bn.Ma_nguoi_dung,
                
                -- Xử lý Tên hiển thị của hồ sơ
                COALESCE(nt.Ten_nguoi_than, nd.Ten_nguoi_dung) AS Ten_ho_so,
                
                -- Xử lý Vai trò / Mối quan hệ để dễ phân biệt trên giao diện
                COALESCE(nt.Quan_he, 'Chủ tài khoản') AS Vai_tro,
                
                bn.Ngay_sinh, 
                bn.Gioi_tinh, 
                bn.Dia_chi, 
                bn.Nhom_mau, 
                bn.Di_ung, 
                bn.Benh_nen
                
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

    static async addRelativeProfile(userID, tenNguoiThan, moiQuanHe, birthDay, gender, address, nhomMau, diUng, benhNen){
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
                (Ma_benh_nhan, Ten_nguoi_than, Quan_he, Ngay_sinh) 
                VALUES (?, ?, ?, ?)
            `;

            await conn.execute(sqlNguoiThan, [
                newMaBenhNhan, 
                tenNguoiThan || null, 
                moiQuanHe || null,
                birthDay
            ]);

            await commitTransaction(conn);
            return true;
        }
        catch(error){
            await rollbackTransaction(conn);
            throw new Error('Lỗi thêm hồ sơ sức khỏe(healthRecordModel.addRelativeProfile): ' + error.message);
        }
    }

    static async updateHealthRecord(maBenhNhan, userID, tenHoSo, moiQuanHe, birthDay, gender, address, nhomMau, diUng, benhNen) {
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

            // 3. Cập nhật bảng nguoi_than (Nếu có tên người thân và mối quan hệ gửi lên)
            // Cột Quan_he hay Moi_quan_he tùy thuộc vào DB của bạn (tôi đang dùng Quan_he dựa theo log lỗi của bạn ở trên)
            if (tenHoSo && moiQuanHe) {
                const sqlNguoiThan = `
                    UPDATE nguoi_than 
                    SET Ten_nguoi_than = ?, Quan_he = ?
                    WHERE Ma_benh_nhan = ?
                `;
                await conn.execute(sqlNguoiThan, [tenHoSo, moiQuanHe, maBenhNhan]);
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
            // ✅ Đã sửa SQL: Join thêm bảng nguoi_dung và dùng COALESCE
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
                    COALESCE(nt.Quan_he, 'Chủ tài khoản') AS Vai_tro
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

            // Giải mã các trường dữ liệu y tế an toàn
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
}