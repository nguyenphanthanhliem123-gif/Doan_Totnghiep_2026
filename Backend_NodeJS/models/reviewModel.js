import { execute } from "../config/db.js";

export default class reviewModel {
    // Hàm lấy danh sách đánh giá của bác sĩ theo Ma_bac_si
    static async getReviewsByDoctorId(ma_bac_si) {
        try {
            // Thực hiện Double JOIN: danh_gia -> benh_nhan -> nguoi_dung
            const query = `
                SELECT 
                    dg.*, 
                    nd.Ten_nguoi_dung AS Ten_benh_nhan, 
                    nd.Anh_dai_dien 
                FROM danh_gia dg
                LEFT JOIN benh_nhan bn ON dg.Ma_benh_nhan = bn.Ma_benh_nhan
                LEFT JOIN nguoi_dung nd ON bn.Ma_nguoi_dung = nd.Ma_nguoi_dung
                WHERE dg.Ma_bac_si = ?
                ORDER BY dg.Ngay_tao DESC
            `;
            const [rows] = await execute(query, [ma_bac_si]);
            return rows;
        } catch (error) {
            throw new Error("Lỗi truy vấn danh sách đánh giá: " + error.message);
        }
    }
}