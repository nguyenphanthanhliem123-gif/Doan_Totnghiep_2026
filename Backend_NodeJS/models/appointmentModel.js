import { execute } from "../config/db.js";

export default class appointmentModel {

    // Lấy danh sách lịch hẹn của bệnh nhân dựa trên userID
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

    // Lấy chi tiết lịch hẹn dựa trên Ma_lich_hen
    static async getAppointmentDetails(appointmentID) {
        try {
            const sql = `
                SELECT 
                    lh.Ma_lich_hen,
                    lh.Ma_booking,
                    lh.Ma_bac_si,
                    lh.Hinh_thuc,
                    lh.Trang_thai_lich_hen,
                    lh.Trieu_chung AS Ghi_chu,
                    kg.Thoi_gian_Bdau,
                    kg.Thoi_gian_Kthuc,
                    nd_bs.Ten_nguoi_dung AS Ten_bac_si,
                    nd_bs.Anh_dai_dien AS Anh_bac_si,
                    dv.Ten_dich_vu,
                    pk.Ten_phong_kham,
                    pk.Vi_tri AS Dia_chi_phong_kham,
                    tt.Tong_tien,
                    tt.Phuong_thuc AS Phuong_thuc_thanh_toan,
                    tt.Trang_thai_thanh_toan,
                    -- Logic thông minh để lấy đúng Tên người đi khám
                    CASE 
                        WHEN lh.Ma_nguoi_than IS NOT NULL THEN nt.Ten_nguoi_than
                        ELSE nd_bn.Ten_nguoi_dung
                    END AS Ten_nguoi_kham,
                    CASE 
                        WHEN lh.Ma_nguoi_than IS NOT NULL THEN nt.Quan_he
                        ELSE 'Bản thân'
                    END AS Moi_quan_he

                FROM lich_hen lh
                JOIN bac_si bs ON lh.Ma_bac_si = bs.Ma_bac_si
                JOIN nguoi_dung nd_bs ON bs.Ma_nguoi_dung = nd_bs.Ma_nguoi_dung
                JOIN dich_vu dv ON lh.Ma_dich_vu = dv.Ma_dich_vu
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                JOIN phong_kham pk ON kg.Ma_phong_kham = pk.Ma_phong_kham
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                JOIN nguoi_dung nd_bn ON bn.Ma_nguoi_dung = nd_bn.Ma_nguoi_dung
                LEFT JOIN nguoi_than nt ON lh.Ma_nguoi_than = nt.Ma_nguoi_than
                LEFT JOIN thanh_toan tt ON lh.Ma_lich_hen = tt.Ma_lich_hen
                WHERE lh.Ma_lich_hen = ?
            `;
            
            const [details] = await execute(sql, [appointmentID]);
            return details[0]; // Trả về 1 object duy nhất vì ID là độc nhất
        } catch (error) {
            throw new Error('Lỗi truy vấn chi tiết lịch hẹn: ' + error.message);
        }
    }

    // Hủy lịch hẹn với điều kiện chặn hủy trước 2 giờ
    static async cancelAppointment(appointmentID) {
        try {
            // 1. Lấy thời gian bắt đầu khám và trạng thái hiện tại để kiểm tra điều kiện
            const checkSql = `
                SELECT kg.Thoi_gian_Bdau, lh.Trang_thai_lich_hen 
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                WHERE lh.Ma_lich_hen = ?
            `;
            const [rows] = await execute(checkSql, [appointmentID]);
            if (rows.length === 0) {
                return { success: false, message: "Không tìm thấy lịch hẹn này." };
            }

            const appointment = rows[0];
            
            // Chặn nếu lịch đã xử lý rồi
            if (appointment.Trang_thai_lich_hen === 'cancelled' || appointment.Trang_thai_lich_hen === 'absent') {
                return { success: false, message: "Lịch hẹn này đã được hủy hoặc báo vắng từ trước." };
            }
            if (appointment.Trang_thai_lich_hen === 'done') {
                return { success: false, message: "Không thể hủy lịch khám đã hoàn thành." };
            }

            // Kiểm tra chính sách chặn hủy trước 2 giờ
            const startTime = new Date(appointment.Thoi_gian_Bdau);
            const now = new Date();
            const diffInHours = (startTime - now) / (1000 * 60 * 60); // Đổi mili-giây ra giờ

            if (diffInHours < 2) {
                return { success: false, message: "Theo chính sách, bạn chỉ được phép hủy lịch khám trước giờ bắt đầu tối thiểu 2 tiếng." };
            }

            // 2. Cập nhật trạng thái lịch hẹn thành 'cancelled'
            const updateSql = `UPDATE lich_hen SET Trang_thai_lich_hen = 'cancelled' WHERE Ma_lich_hen = ?`;
            await execute(updateSql, [appointmentID]);

            // 3. 🌟 TODO: KHỞI TẠO HOÀN TIỀN TỰ ĐỘNG (KHI KẾT NỐI VÍ MOMO / CỔNG THANH TOÁN)
            // - Kiểm tra bảng thanh_toan xem: Trang_thai_thanh_toan == 'paid' và Phương thức online hay không.
            // - Gọi sang API Hoàn tiền (Refund) của MoMo / Ngân hàng qua Ma_giao_dich.
            // - Cập nhật trạng thái bảng thanh_toan thành 'refunded'.
            console.log(`[TODO_REFUND]: Lịch hẹn ${appointmentID} thỏa điều kiện hoàn tiền nếu đã thanh toán online.`);

            return { success: true, message: "Hủy lịch khám thành công." };

        } catch (error) {
            throw new Error('Lỗi khi xử lý hủy lịch: ' + error.message);
        }
    }
}