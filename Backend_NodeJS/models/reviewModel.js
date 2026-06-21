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

    static async createReview(data){
        try{
            console.log(data);
            const [checkDone] = await execute(
                `SELECT Trang_thai_lich_hen
                FROM lich_hen
                WHERE Ma_lich_hen = ?`
                ,[data.Ma_lich_hen]
            );

            if(checkDone[0].Trang_thai_lich_hen != 'done') throw new Error("Lịch hẹn này chưa hoàn thành.");

            
            const [checkReview] = await execute(`
                    SELECT *
                    FROM danh_gia
                    WHERE Ma_lich_hen = ?
                `,[data.Ma_lich_hen]);

            if(checkReview.length > 0) throw new Error("Bạn đã đáng giá lần khám này rồi.");

            const sql = `
                INSERT INTO danh_gia(
                    Ma_bac_si,
                    Ma_lich_hen,
                    Ma_benh_nhan,
                    So_sao,
                    Noi_dung,
                    Ngay_tao
                )
                VALUES(?,?,?,?,?,?)
            `;

            const [result] = await execute(sql,[data.Ma_bac_si, data.Ma_lich_hen, data.Ma_benh_nhan, data.So_sao, data.Noi_dung, new Date()]);

            return result.insertId ? result.insertId : null;
        }catch(error){
            throw new Error("Lỗi thêm đánh giá: " + error.message);
        }
    }
}