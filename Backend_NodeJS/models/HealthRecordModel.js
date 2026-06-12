import { beginTransaction, commitTransaction, execute, rollbackTransaction } from "../config/db.js";
import { encrypt } from "../utils/cryptoUtil.js";

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
}