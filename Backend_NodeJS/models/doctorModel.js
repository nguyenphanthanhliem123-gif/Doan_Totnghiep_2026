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

    static async getDoctors(maChuyenKhoa = null) {
        console.log('=== MAchuyenkhoa: ' + maChuyenKhoa);
        try {
            let query = `
                SELECT 
                    b.Ma_bac_si, 
                    nd.Ten_nguoi_dung AS Ten_bac_si, 
                    nd.Anh_dai_dien, 
                    b.Hoc_vi,
                    b.Nam_kinh_nghiem, 
                    b.Tom_tat_danh_gia,
                    c.Ten_chuyen_khoa 
                FROM bac_si b
                JOIN nguoi_dung nd ON b.Ma_nguoi_dung = nd.Ma_nguoi_dung
                LEFT JOIN chuyen_khoa c ON b.Ma_chuyen_khoa = c.Ma_chuyen_khoa
                WHERE b.Trang_thai_hoat_dong = 'active'
            `;
            let params = [];

            // Lọc theo chuyên khoa nếu có truyền vào
            if (maChuyenKhoa) {
                query += ` AND b.Ma_chuyen_khoa = ?`;
                params.push(maChuyenKhoa);
            }

            console.log('=== DEBUG ===');
            console.log('=== query: ' + query);

            const [rows] = await execute(query, params);
            return rows;
        } catch (error) {
            throw new Error('Lỗi DB (doctorModel.getDoctors): ' + error.message);
        }
    }

    static async getDoctorsFilter(filters = {}) {
        try {
            // Điều kiện mặc định: Bác sĩ phải đang hoạt động hoạt động
            let conditions = ["b.Trang_thai_hoat_dong = 'active'"];
            let params = [];

            // 1. Kiểm tra bộ lọc chuyên khoa
            if (filters.specialtyId) {
                conditions.push("b.Ma_chuyen_khoa = ?");
                params.push(filters.specialtyId);
            }

            // 2. SỬA TÊN CỘT: Sử dụng pk.Vi_tri thay vì pk.Dia_chi
            if (filters.location) {
                conditions.push("pk.Vi_tri LIKE ?");
                params.push(`%${filters.location}%`);
            }

            let dateJoin = "";
            if (filters.availableDate) {
                dateJoin = "JOIN ca_kham ck ON b.Ma_bac_si = ck.Ma_bac_si";
                conditions.push("ck.Ngay_kham = ? AND ck.Trang_thai = 'Trống'");
                params.push(filters.availableDate);
            }

            let whereClause = conditions.length > 0 ? "WHERE " + conditions.join(" AND ") : "";

            // 🛑 CẬP NHẬT CÂU LỆNH SQL HOÀN CHỈNH: ĐÃ THÊM JOIN DICH_VU VÀ DANH_GIA
            let query = `
                SELECT 
                    b.Ma_bac_si, 
                    nd.Ten_nguoi_dung AS Ten_bac_si, 
                    nd.Anh_dai_dien, 
                    b.Hoc_vi,
                    b.Nam_kinh_nghiem,
                    c.Ten_chuyen_khoa,
                    pk.Ten_phong_kham,
                    pk.Vi_tri AS Khu_vuc, -- Sửa thành pk.Vi_tri
                    MIN(dv.Gia_tien) AS Gia_kham,
                    AVG(dg.So_sao) AS Diem_danh_gia
                FROM bac_si b
                JOIN nguoi_dung nd ON b.Ma_nguoi_dung = nd.Ma_nguoi_dung
                LEFT JOIN chuyen_khoa c ON b.Ma_chuyen_khoa = c.Ma_chuyen_khoa
                LEFT JOIN bac_si_phong_kham bspk ON b.Ma_bac_si = bspk.Ma_bac_si
                LEFT JOIN phong_kham pk ON bspk.Ma_phong_kham = pk.Ma_phong_kham
                LEFT JOIN dich_vu dv ON b.Ma_bac_si = dv.Ma_bac_si    -- 🌟 Bổ sung JOIN bảng dịch vụ
                LEFT JOIN danh_gia dg ON b.Ma_bac_si = dg.Ma_bac_si    -- 🌟 Bổ sung JOIN bảng đánh giá
                ${dateJoin}
                ${whereClause}
                GROUP BY b.Ma_bac_si
            `;

            // Xử lý các bộ lọc số lượng trong HAVING
            let havingConditions = [];
            if (filters.minPrice) havingConditions.push(`MIN(dv.Gia_tien) >= ${Number(filters.minPrice)}`);
            if (filters.maxPrice) havingConditions.push(`MIN(dv.Gia_tien) <= ${Number(filters.maxPrice)}`);
            if (filters.minRating) havingConditions.push(`AVG(dg.So_sao) >= ${Number(filters.minRating)}`);

            if (havingConditions.length > 0) {
                query += " HAVING " + havingConditions.join(" AND ");
            }

            // Thực thi câu lệnh
            const [rows] = await execute(query, params);
            return rows;
        } catch (error) {
            console.error("Lỗi chi tiết SQL:", error.message); // In lỗi ra terminal backend để dễ debug
            throw new Error('Lỗi DB getDoctorsFilter: ' + error.message);
        }
    }
}