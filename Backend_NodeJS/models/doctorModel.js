import { beginTransaction, execute } from "../config/db.js";

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
                SELECT Ma_dich_vu, Ten_dich_vu, Gia_tien, ck.Ma_chuyen_khoa, ck.Ten_chuyen_khoa
                FROM dich_vu
                LEFT JOIN chuyen_khoa ck ON dich_vu.Ma_chuyen_khoa = ck.Ma_chuyen_khoa
                WHERE Ma_bac_si = ?
                   OR ck.Ma_chuyen_khoa = (SELECT Ma_chuyen_khoa FROM bac_si WHERE Ma_bac_si = ?)
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
            // Điều kiện mặc định: Bác sĩ phải đang hoạt động
            let conditions = ["b.Trang_thai_hoat_dong = 'active'"];
            let params = [];

            // 1. Kiểm tra bộ lọc chuyên khoa
            if (filters.specialtyId) {
                conditions.push("b.Ma_chuyen_khoa = ?");
                params.push(filters.specialtyId);
            }

            // 2. Lọc theo khu vực (Sử dụng pk.Vi_tri)
            if (filters.location) {
                conditions.push("pk.Vi_tri LIKE ?");
                params.push(`%${filters.location}%`);
            }

            // 3. SỬA TẠI ĐÂY: Lọc theo ngày còn lịch (Dùng bảng khung_gio_kham)
            let dateJoin = "";
            if (filters.availableDate) {
                // Join với bảng khung_gio_kham
                dateJoin = "JOIN khung_gio_kham kgk ON b.Ma_bac_si = kgk.Ma_bac_si";
                
                // Dùng DATE(kgk.Thoi_gian_Bdau) để cắt lấy phần Ngày từ DATETIME, và trạng thái 'available'
                conditions.push("DATE(kgk.Thoi_gian_Bdau) = ? AND kgk.Trang_thai = 'available'");
                params.push(filters.availableDate);
            }

            let whereClause = conditions.length > 0 ? "WHERE " + conditions.join(" AND ") : "";

            let distanceSelect = "0 AS Khoang_cach"; 
            if (filters.sortBy === 'distance_asc' && filters.userLat && filters.userLng) {
                distanceSelect = `
                    (6371 * acos(
                        cos(radians(${Number(filters.userLat)})) 
                        * cos(radians(pk.Vi_do)) 
                        * cos(radians(pk.Kinh_do) - radians(${Number(filters.userLng)})) 
                        + sin(radians(${Number(filters.userLat)})) 
                        * sin(radians(pk.Vi_do))
                    )) AS Khoang_cach
                `;
            }

            // CÂU LỆNH SQL HOÀN CHỈNH
            let query = `
                SELECT 
                    b.Ma_bac_si, 
                    nd.Ten_nguoi_dung AS Ten_bac_si, 
                    nd.Anh_dai_dien, 
                    b.Hoc_vi,
                    b.Nam_kinh_nghiem,
                    c.Ten_chuyen_khoa,
                    pk.Ten_phong_kham,
                    pk.Vi_tri AS Khu_vuc,
                    MIN(dv.Gia_tien) AS Gia_kham,
                    AVG(dg.So_sao) AS Diem_danh_gia,
                    ${distanceSelect}
                FROM bac_si b
                JOIN nguoi_dung nd ON b.Ma_nguoi_dung = nd.Ma_nguoi_dung
                LEFT JOIN chuyen_khoa c ON b.Ma_chuyen_khoa = c.Ma_chuyen_khoa
                LEFT JOIN bac_si_phong_kham bspk ON b.Ma_bac_si = bspk.Ma_bac_si
                LEFT JOIN phong_kham pk ON bspk.Ma_phong_kham = pk.Ma_phong_kham
                LEFT JOIN dich_vu dv ON b.Ma_bac_si = dv.Ma_bac_si    
                LEFT JOIN danh_gia dg ON b.Ma_bac_si = dg.Ma_bac_si    
                ${dateJoin}
                ${whereClause}
                GROUP BY b.Ma_bac_si
            `;

            // 4. Xử lý các bộ lọc số lượng trong HAVING
            let havingConditions = [];
            if (filters.minPrice) havingConditions.push(`MIN(dv.Gia_tien) >= ${Number(filters.minPrice)}`);
            if (filters.maxPrice) havingConditions.push(`MIN(dv.Gia_tien) <= ${Number(filters.maxPrice)}`);
            if (filters.minRating) havingConditions.push(`AVG(dg.So_sao) >= ${Number(filters.minRating)}`);

            if (havingConditions.length > 0) {
                query += " HAVING " + havingConditions.join(" AND ");
            }

            let orderByClause = "ORDER BY b.Ma_bac_si DESC";

            if (filters.sortBy === 'rating_desc') {
                orderByClause = "ORDER BY Diem_danh_gia DESC";
            } else if (filters.sortBy === 'price_asc') {
                orderByClause = "ORDER BY Gia_kham ASC";
            } else if (filters.sortBy === 'distance_asc' && filters.userLat && filters.userLng) {
                orderByClause = "ORDER BY Khoang_cach ASC";
            }

            query += ` ${orderByClause}`;

            // Thực thi câu lệnh
            const [rows] = await execute(query, params);
            return rows;
        } catch (error) {
            console.error("Lỗi chi tiết SQL:", error.message); // In lỗi ra terminal backend để dễ debug
            throw new Error('Lỗi DB getDoctorsFilter: ' + error.message);
        }
    }

    static async updateProfileDoctor(ma_nguoi_dung, data) {
        try {
            // 1. Khởi tạo mảng chứa các câu lệnh SET và mảng chứa giá trị tương ứng
            const setClauses = [];
            const values = [];

            // 2. Kiểm tra từng trường dữ liệu, nếu có tồn tại (khác undefined) thì mới đưa vào câu Query
            if (data.Ma_chuyen_khoa !== undefined) {
                setClauses.push("Ma_chuyen_khoa = ?");
                values.push(data.Ma_chuyen_khoa);
            }
            
            if (data.Mo_ta_ban_than !== undefined) {
                setClauses.push("Mo_ta_ban_than = ?");
                values.push(data.Mo_ta_ban_than);
            }
            
            if (data.Hoc_vi !== undefined) {
                setClauses.push("Hoc_vi = ?");
                values.push(data.Hoc_vi);
            }
            
            if (data.So_nam_kinh_nghiem !== undefined) {
                setClauses.push("Nam_kinh_nghiem = ?");
                values.push(data.So_nam_kinh_nghiem);
            }

            // 3. Nếu không có trường nào được gửi lên để update, thoát hàm sớm
            if (setClauses.length === 0) {
                return { affectedRows: 0, message: "Không có dữ liệu nào cần thay đổi." };
            }

            // 4. Ghép mảng setClauses thành chuỗi (VD: "Ma_chuyen_khoa = ?, Mo_ta_ban_than = ?")
            const sql = `
                UPDATE bac_si
                SET ${setClauses.join(', ')}
                WHERE Ma_nguoi_dung = ?
            `;

            // 5. Đẩy điều kiện WHERE (Mã người dùng) vào cuối mảng values
            values.push(ma_nguoi_dung);

            // 6. Thực thi câu lệnh SQL động
            const [result] = await execute(sql, values);
            return result;

        } catch (error) {
            throw new Error("Lỗi khi cập nhật hồ sơ bác sĩ: " + error.message);
        }
    }

    static async getDoctorDetailByUserID(userID) {
        console.log('=== userID: ' + userID);
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
                    ck.Ma_chuyen_khoa,
                    pk.Ten_phong_kham,
                    pk.Vi_tri AS Dia_chi
                FROM bac_si bs
                JOIN nguoi_dung nd ON bs.Ma_nguoi_dung = nd.Ma_nguoi_dung
                LEFT JOIN chuyen_khoa ck ON bs.Ma_chuyen_khoa = ck.Ma_chuyen_khoa
                -- Nối bảng trung gian, ưu tiên lấy phòng khám được đánh dấu là Noi_chinh = 1
                LEFT JOIN bac_si_phong_kham bspk ON bs.Ma_bac_si = bspk.Ma_bac_si AND bspk.Noi_chinh = 1
                LEFT JOIN phong_kham pk ON bspk.Ma_phong_kham = pk.Ma_phong_kham
                WHERE bs.Ma_nguoi_dung = ?
                LIMIT 1
            `;
            
            const [rows] = await execute(query, [userID]);
            return rows[0] ?? null;
        } catch (error) {
            throw new Error("Lỗi lấy dữ liệu bác sĩ: " + error.message);
        }
    }


    static async getDoctorClinicsByUserId(userId) {
        try {
            const query = `
                SELECT bspk.Ma_phong_kham, bspk.Noi_chinh
                FROM bac_si_phong_kham bspk
                JOIN bac_si bs ON bspk.Ma_bac_si = bs.Ma_bac_si
                WHERE bs.Ma_nguoi_dung = ?
            `;
            const [rows] = await execute(query, [userId]);
            return rows;
        } catch (error) {
            throw new Error("Lỗi khi lấy danh sách phòng khám đã chọn: " + error.message);
        }
    }
}