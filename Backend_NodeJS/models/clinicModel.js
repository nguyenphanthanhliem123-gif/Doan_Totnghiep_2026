import { beginTransaction, execute, commitTransaction, rollbackTransaction } from "../config/db.js";

export default class clinicModel {
    // Hàm lấy chi tiết phòng khám theo ID
    static async getClinicById(ma_phong_kham) {
        try {
            // Lấy thông tin cơ bản của phòng khám
            const queryClinic = `SELECT * FROM phong_kham WHERE Ma_phong_kham = ? LIMIT 1`;
            const [clinics] = await execute(queryClinic, [ma_phong_kham]);
            
            if (clinics.length === 0) return null;
            const clinic = clinics[0];

            // Lấy danh sách hình ảnh của phòng khám đó
            const queryImages = `SELECT Link_anh FROM anh_phong_kham WHERE Ma_phong_kham = ?`;
            const [images] = await execute(queryImages, [ma_phong_kham]);
            
            // Ép mảng object thành mảng string đường dẫn để Flutter dễ đọc
            clinic.danh_sach_anh = images.map(img => img.Link_anh);

            return clinic;
        } catch (error) {
            throw new Error("Lỗi lấy dữ liệu phòng khám: " + error.message);
        }
    }

    static async getAllClinics(){
        try{
            const query = `
                SELECT *
                FROM phong_kham
                ORDER BY Ma_phong_kham DESC
            `;

            const [rows] = await execute(query);

            return rows.length > 0 ? rows : [];
        }
        catch(error){
            throw new Error("Lỗi clinicModel.getAllClinics: " + error.message);
        }
    }

    static async updateDoctorClinics(userId, clinicsArray) {
        // clinicsArray dạng: [{ma_phong_kham: 1, noi_chinh: 1}, {ma_phong_kham: 2, noi_chinh: 0}]
        const conn = await beginTransaction();
        try {
            // 1. Lấy Ma_bac_si từ userId trước
            const [doctor] = await conn.execute("SELECT Ma_bac_si FROM bac_si WHERE Ma_nguoi_dung = ?", [userId]);
            if (!doctor.length) throw new Error("Không tìm thấy bác sĩ");
            const maBacSi = doctor[0].Ma_bac_si;

            // 2. Xóa toàn bộ liên kết phòng khám cũ của bác sĩ này
            await conn.execute("DELETE FROM bac_si_phong_kham WHERE Ma_bac_si = ?", [maBacSi]);

            // 3. Thêm mới lại các phòng khám được chọn từ giao diện
            const insertQuery = "INSERT INTO bac_si_phong_kham (Ma_bac_si, Ma_phong_kham, Noi_chinh) VALUES (?, ?, ?)";
            for (const clinic of clinicsArray) {
                await conn.execute(insertQuery, [maBacSi, clinic.ma_phong_kham, clinic.noi_chinh]);
            }

            // Nếu tất cả đều thành công thì lưu vào DB
            await commitTransaction(conn);
            return true;
        } catch (error) {
            // Nếu có bất kỳ lỗi nào xảy ra, hủy bỏ toàn bộ thao tác (khôi phục dữ liệu cũ)
            await rollbackTransaction(conn);
            throw new Error("Lỗi cập nhật phòng khám bác sĩ: " + error.message);
        }
    }

    static async addClinic(data) {
        const query = `
            INSERT INTO phong_kham (Ten_phong_kham, Mo_ta_phong_kham, Vi_tri, Kinh_do, Vi_do, Dien_thoai, Email, Link_trang_web, Tien_ich)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;
        const values = [
            data.Ten_phong_kham, data.Mo_ta_phong_kham || null, data.Vi_tri, 
            data.Kinh_do || null, data.Vi_do || null, data.Dien_thoai || null, 
            data.Email || null, data.Link_trang_web || null, data.Tien_ich || null
        ];
        const [result] = await execute(query, values);
        return result.insertId;
    }

    // 3. Cập nhật phòng khám
    static async updateClinic(id, data) {
        const query = `
            UPDATE phong_kham 
            SET Ten_phong_kham = ?, Mo_ta_phong_kham = ?, Vi_tri = ?, Kinh_do = ?, Vi_do = ?, Dien_thoai = ?, Email = ?, Link_trang_web = ?, Tien_ich = ?
            WHERE Ma_phong_kham = ?
        `;
        const values = [
            data.Ten_phong_kham, data.Mo_ta_phong_kham || null, data.Vi_tri, 
            data.Kinh_do || null, data.Vi_do || null, data.Dien_thoai || null, 
            data.Email || null, data.Link_trang_web || null, data.Tien_ich || null, id
        ];
        const [result] = await execute(query, values);
        return result.affectedRows > 0;
    }

    static async addClinicImage(maPhongKham, linkAnh) {
        const query = `INSERT INTO anh_phong_kham (Ma_phong_kham, Link_anh) VALUES (?, ?)`;
        const [result] = await execute(query, [maPhongKham, 'http://localhost:3001' + linkAnh]);
        return result.insertId;
    }
}