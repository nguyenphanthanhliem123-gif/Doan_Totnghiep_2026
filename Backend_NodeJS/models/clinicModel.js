import { execute } from "../config/db.js";

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
            `;

            const [rows] = await execute(query);

            return rows.length > 0 ? rows : [];
        }
        catch(error){
            throw new Error("Lỗi clinicModel.getAllClinics: " + error.message);
        }
    }
}