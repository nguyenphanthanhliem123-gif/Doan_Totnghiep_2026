import { execute } from "../config/db.js";

export default class SearchModel {
    static async globalSearch(keyword) {
        try {
            const searchPattern = `%${keyword}%`;

            // 1. Tìm Bác sĩ (Kết hợp bảng nguoi_dung và ghép thêm học vị khi tìm kiếm)
            const [doctors] = await execute(`
                SELECT b.Ma_bac_si, nd.Ten_nguoi_dung AS Ten_bac_si, nd.Anh_dai_dien, c.Ten_chuyen_khoa, b.Hoc_vi
                FROM bac_si b
                JOIN nguoi_dung nd ON b.Ma_nguoi_dung = nd.Ma_nguoi_dung
                LEFT JOIN chuyen_khoa c ON b.Ma_chuyen_khoa = c.Ma_chuyen_khoa
                WHERE (
                    nd.Ten_nguoi_dung LIKE ? 
                    OR CONCAT(IFNULL(b.Hoc_vi, ''), ' ', nd.Ten_nguoi_dung) LIKE ?
                ) 
                AND b.Trang_thai_hoat_dong LIKE 'active'
                LIMIT 5
            `, [searchPattern, searchPattern]); // Truyền searchPattern 2 lần tương ứng với 2 dấu chấm hỏi (?)

            // 2. Tìm Chuyên khoa
            const [specialties] = await execute(`
                SELECT Ma_chuyen_khoa, Ten_chuyen_khoa, Icon
                FROM chuyen_khoa
                WHERE Ten_chuyen_khoa LIKE ?
                LIMIT 5
            `, [searchPattern]);

            // 3. Tìm Phòng khám
            const [clinics] = await execute(`
                SELECT Ma_phong_kham, Ten_phong_kham, Vi_tri
                FROM phong_kham
                WHERE Ten_phong_kham LIKE ?
                LIMIT 5
            `, [searchPattern]);

            return {
                doctors,
                specialties,
                clinics
            };
        } catch (error) {
            throw new Error('Lỗi database (SearchModel): ' + error.message);
        }
    }
}