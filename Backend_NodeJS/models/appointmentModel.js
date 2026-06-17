import { execute } from "../config/db.js";

export default class appointmentModel {
    static async getPatientAppointments(userID) {
        try {
            const sql = `
                SELECT 
                    lh.Ma_lich_hen,
                    lh.Ma_booking,
                    lh.Trang_thai_lich_hen,
                    lh.Hinh_thuc,
                    kg.Thoi_gian_Bdau,
                    kg.Thoi_gian_Kthuc,
                    nd.Ten_nguoi_dung AS Ten_bac_si,
                    nd.Anh_dai_dien AS Anh_bac_si
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                JOIN bac_si bs ON lh.Ma_bac_si = bs.Ma_bac_si
                JOIN nguoi_dung nd ON bs.Ma_nguoi_dung = nd.Ma_nguoi_dung
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                WHERE bn.Ma_nguoi_dung = ?
                ORDER BY kg.Thoi_gian_Bdau DESC
            `;
            
            const [appointments] = await execute(sql, [userID]);
            return appointments;
        } catch (error) {
            throw new Error('Lỗi truy vấn lịch hẹn: ' + error.message);
        }
    }
}