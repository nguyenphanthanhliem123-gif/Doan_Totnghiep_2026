import { execute } from "../config/db.js";

export default class doctorModel {
    // Hàm lấy chi tiết 1 bác sĩ theo ID
    static async getDoctorDetail(ma_bac_si) {
        try {
            const query = `
                SELECT 
                    bs.Ma_bac_si,
                    nd.Ten_nguoi_dung AS Ho_ten,
                    nd.Anh_dai_dien,
                    bs.Hoc_vi,
                    bs.Nam_kinh_nghiem,
                    bs.Mo_ta_ban_than,
                    ck.Ten_chuyen_khoa,
                    pk.Ten_phong_kham,
                    pk.Vi_tri AS Dia_chi
                FROM bac_si bs
                JOIN nguoi_dung nd ON bs.Ma_nguoi_dung = nd.Ma_nguoi_dung
                LEFT JOIN chuyen_khoa ck ON bs.Ma_chuyen_khoa = ck.Ma_chuyen_khoa
                -- Nối bảng trung gian, ưu tiên lấy phòng khám được đánh dấu là Noi_chinh = 1
                LEFT JOIN bac_si_phong_kham bspk ON bs.Ma_bac_si = bspk.Ma_bac_si AND bspk.Noi_chinh = 1
                LEFT JOIN phong_kham pk ON bspk.Ma_phong_kham = pk.Ma_phong_kham
                WHERE bs.Ma_bac_si = ?
                LIMIT 1
            `;
            
            const [rows] = await execute(query, [ma_bac_si]);
            return rows[0] ?? null;
        } catch (error) {
            throw new Error("Lỗi lấy dữ liệu bác sĩ: " + error.message);
        }
    }

    // Hàm lấy danh sách dịch vụ của bác sĩ
    static async getDoctorServices(ma_bac_si) {
        try {
            // Lấy dịch vụ dành riêng cho bác sĩ này
            const query = `
                SELECT Ma_dich_vu, Ten_dich_vu, Gia_tien
                FROM dich_vu
                WHERE Ma_bac_si = ?
                   OR Ma_chuyen_khoa = (SELECT Ma_chuyen_khoa FROM bac_si WHERE Ma_bac_si = ?)
            `;
            const [rows] = await execute(query, [ma_bac_si, ma_bac_si]);
            return rows;
        } catch (error) {
            throw new Error("Lỗi lấy danh sách dịch vụ: " + error.message);
        }
    }

    // Hàm lấy lịch làm việc của bác sĩ
    static async getDoctorSchedule(ma_bac_si) {
        try {
            // Lấy dữ liệu và tự động format ngày giờ bằng SQL để tránh lỗi múi giờ
            const query = `
                SELECT 
                    Ma_khung_gio,
                    DATE_FORMAT(Thoi_gian_Bdau, '%Y-%m-%d') AS Ngay,
                    DATE_FORMAT(Thoi_gian_Bdau, '%H:%i') AS Gio,
                    Trang_thai
                FROM khung_gio_kham
                WHERE Ma_bac_si = ? AND DATE(Thoi_gian_Bdau) >= CURDATE()
                ORDER BY Thoi_gian_Bdau ASC
            `;
            const [rows] = await execute(query, [ma_bac_si]);

            // Nhóm dữ liệu lại theo từng ngày
            const scheduleMap = {};
            rows.forEach(row => {
                const dateStr = row.Ngay; // Ví dụ: '2026-06-12'
                if (!scheduleMap[dateStr]) {
                    scheduleMap[dateStr] = []; // Nếu ngày này chưa có trong Map thì tạo mảng mới
                }
                scheduleMap[dateStr].push({
                    id: row.Ma_khung_gio,
                    time: row.Gio, // Ví dụ: '08:00'
                    status: row.Trang_thai // 'available', 'booked', 'locked'
                });
            });

            // Chuyển từ dạng Object Map sang dạng Mảng (Array) để Flutter dễ dùng
            const result = Object.keys(scheduleMap).map(date => ({
                date: date,
                slots: scheduleMap[date]
            }));

            return result;
        } catch (error) {
            throw new Error("Lỗi lấy lịch khám: " + error.message);
        }
    }
}