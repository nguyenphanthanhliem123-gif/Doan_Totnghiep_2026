// Backend_NodeJS/models/chatbotModel.js
import { execute } from "../config/db.js";

export default class ChatbotModel {
    // 1. Tạo phiên hội thoại mới hoàn toàn
    static async createSession(userId, sessionToken, message) {
        try {
            const jsonChuDe = JSON.stringify(message || "Cuộc trò chuyện mới");
            const sql = `
                INSERT INTO phien_hoi_thoai (Ma_nguoi_dung, Session_token, Chu_de, Bat_dau) 
                VALUES (?, ?, ?, NOW())
            `;
            const [result] = await execute(sql, [userId, sessionToken, jsonChuDe]);
            return result.insertId;
        } catch (error) {
            throw new Error('Lỗi tạo phiên hội thoại: ' + error.message);
        }
    }

    // 2. Lấy 10 tin nhắn lịch sử gần nhất theo mã phiên để làm context cho AI
    static async getChatHistory(sessionToken) {
        const sql = `
            SELECT tn.Vai_tro, tn.Noi_dung 
            FROM tin_nhan_hoi_thoai tn
            JOIN phien_hoi_thoai ph ON tn.Ma_hoi_thoai = ph.Ma_hoi_thoai
            WHERE ph.Session_token = ?
            ORDER BY tn.Ngay_tao ASC
            LIMIT 10
        `;
        const [rows] = await execute(sql, [sessionToken]);
        return rows;
    }

    // 3. Lưu tin nhắn đơn lẻ của người dùng hoặc AI
    static async saveMessage(sessionToken, vaiTro, noiDung) {
        const sql = `
            INSERT INTO tin_nhan_hoi_thoai (Ma_hoi_thoai, Vai_tro, Noi_dung, Ngay_tao) 
            VALUES (
                (SELECT Ma_hoi_thoai FROM phien_hoi_thoai WHERE Session_token = ? LIMIT 1), 
                ?, ?, NOW()
            )
        `;
        await execute(sql, [sessionToken, vaiTro, noiDung]);
    }

    // 4. Tìm kiếm bác sĩ theo chuyên khoa (Sắp xếp theo đánh giá giảm dần)
    static async searchDoctors(specialty) {
        const query = `
            SELECT bs.Ma_bac_si, nd.Ten_nguoi_dung AS ten_bac_si, ck.Ten_chuyen_khoa, bs.Hoc_vi, AVG(dg.So_sao) AS diem_danh_gia
            FROM bac_si bs
            JOIN nguoi_dung nd ON bs.Ma_nguoi_dung = nd.Ma_nguoi_dung
            JOIN chuyen_khoa ck ON bs.Ma_chuyen_khoa = ck.Ma_chuyen_khoa
            LEFT JOIN danh_gia dg ON bs.Ma_bac_si = dg.Ma_bac_si
            WHERE ck.Ten_chuyen_khoa LIKE ?
            GROUP BY bs.Ma_bac_si ORDER BY diem_danh_gia DESC LIMIT 5;
        `;
        const [rows] = await execute(query, [`%${specialty}%`]);
        return rows;
    }

    // 5. Tìm lịch trống theo Chuyên khoa + bộ lọc Ngày/Buổi nâng cao
    static async searchAvailableSlots(specialty, targetDate = null, timeOfDay = null) {
        let query = `
            SELECT 
                bs.Ma_bac_si, nd.Ten_nguoi_dung AS ten_bac_si, ck.Ten_chuyen_khoa, bs.Hoc_vi,
                AVG(dg.So_sao) AS diem_danh_gia, kg.Ma_khung_gio,
                DATE_FORMAT(kg.Thoi_gian_Bdau, '%Y-%m-%d %H:%i') AS start_time,
                DATE_FORMAT(kg.Thoi_gian_Kthuc, '%H:%i') AS end_time
            FROM khung_gio_kham kg
            JOIN bac_si bs ON kg.Ma_bac_si = bs.Ma_bac_si
            JOIN nguoi_dung nd ON bs.Ma_nguoi_dung = nd.Ma_nguoi_dung
            JOIN chuyen_khoa ck ON bs.Ma_chuyen_khoa = ck.Ma_chuyen_khoa
            LEFT JOIN danh_gia dg ON bs.Ma_bac_si = dg.Ma_bac_si
            WHERE ck.Ten_chuyen_khoa LIKE ? AND kg.Trang_thai = 'available'
        `;
        
        let params = [`%${specialty}%`];

        if (targetDate) {
            query += ` AND DATE(kg.Thoi_gian_Bdau) = ?`;
            params.push(targetDate);
        }
        
        if (timeOfDay === 'morning') {
            query += ` AND HOUR(kg.Thoi_gian_Bdau) < 12`;
        } else if (timeOfDay === 'afternoon') {
            query += ` AND HOUR(kg.Thoi_gian_Bdau) >= 12 AND HOUR(kg.Thoi_gian_Bdau) < 17`;
        } else if (timeOfDay === 'evening') {
            query += ` AND HOUR(kg.Thoi_gian_Bdau) >= 17`;
        }

        query += `
            GROUP BY kg.Ma_khung_gio, bs.Ma_bac_si
            ORDER BY diem_danh_gia DESC, kg.Thoi_gian_Bdau ASC
            LIMIT 15;
        `;
        
        const [rows] = await execute(query, params);
        return rows;
    }

    // 6. Tìm lịch trống đích danh theo tên bác sĩ
    static async checkDoctorSchedule(doctorName) {
        const query = `
            SELECT 
                bs.Ma_bac_si, nd.Ten_nguoi_dung AS ten_bac_si, ck.Ten_chuyen_khoa, kg.Ma_khung_gio,
                DATE_FORMAT(kg.Thoi_gian_Bdau, '%Y-%m-%d %H:%i') AS start_time,
                DATE_FORMAT(kg.Thoi_gian_Kthuc, '%H:%i') AS end_time
            FROM khung_gio_kham kg
            JOIN bac_si bs ON kg.Ma_bac_si = bs.Ma_bac_si
            JOIN nguoi_dung nd ON bs.Ma_nguoi_dung = nd.Ma_nguoi_dung
            JOIN chuyen_khoa ck ON bs.Ma_chuyen_khoa = ck.Ma_chuyen_khoa
            WHERE nd.Ten_nguoi_dung LIKE ? AND kg.Trang_thai = 'available'
            ORDER BY kg.Thoi_gian_Bdau ASC LIMIT 10;
        `;
        const [rows] = await execute(query, [`%${doctorName}%`]);
        return rows;
    }

    // 7. Lấy hồ sơ chi tiết của bác sĩ
    static async getDoctorProfile(doctorName) {
        const query = `
            SELECT 
                bs.Ma_bac_si, 
                nd.Ten_nguoi_dung AS ten_bac_si, 
                ck.Ten_chuyen_khoa, 
                bs.Hoc_vi, 
                bs.Nam_kinh_nghiem,
                bs.Mo_ta_ban_than,
                bs.Tom_tat_danh_gia,
                bs.Badges_sentiment,
                pk.Ten_phong_kham,
                pk.Vi_tri AS dia_chi_phong_kham,
                -- Gom tất cả dịch vụ của bác sĩ này lại thành 1 dòng (VD: Khám nội soi: 200000 VNĐ | Tái khám: 120000 VNĐ)
                GROUP_CONCAT(DISTINCT CONCAT(dv.Ten_dich_vu, ': ', FORMAT(dv.Gia_tien, 0), ' VNĐ') SEPARATOR ' | ') AS danh_sach_dich_vu
            FROM bac_si bs
            JOIN nguoi_dung nd ON bs.Ma_nguoi_dung = nd.Ma_nguoi_dung
            JOIN chuyen_khoa ck ON bs.Ma_chuyen_khoa = ck.Ma_chuyen_khoa
            -- Lấy thông tin phòng khám chính (Nơi làm việc chính)
            LEFT JOIN bac_si_phong_kham bspk ON bs.Ma_bac_si = bspk.Ma_bac_si AND bspk.Noi_chinh = 1
            LEFT JOIN phong_kham pk ON bspk.Ma_phong_kham = pk.Ma_phong_kham
            -- Lấy danh sách dịch vụ bác sĩ đó cung cấp
            LEFT JOIN dich_vu dv ON bs.Ma_bac_si = dv.Ma_bac_si
            WHERE nd.Ten_nguoi_dung LIKE ?
            GROUP BY bs.Ma_bac_si, pk.Ten_phong_kham, pk.Vi_tri
            LIMIT 1;
        `;
        // Tìm kiếm linh hoạt với LIKE
        const [rows] = await execute(query, [`%${doctorName}%`]);
        return rows;
    }


    // 8. TÌM LỊCH SỚM NHẤT THEO CHUYÊN KHOA (Dùng cho câu hỏi: "Đặt lịch khoa Nội sớm nhất")
    static async findEarliestSlotWithSpecialty(specialty) {
        const query = `
            SELECT 
                bs.Ma_bac_si, nd.Ten_nguoi_dung AS ten_bac_si, ck.Ten_chuyen_khoa,
                kg.Ma_khung_gio, DATE_FORMAT(kg.Thoi_gian_Bdau, '%Y-%m-%d %H:%i') AS start_time
            FROM khung_gio_kham kg
            JOIN bac_si bs ON kg.Ma_bac_si = bs.Ma_bac_si
            JOIN nguoi_dung nd ON bs.Ma_nguoi_dung = nd.Ma_nguoi_dung
            JOIN chuyen_khoa ck ON bs.Ma_chuyen_khoa = ck.Ma_chuyen_khoa
            WHERE ck.Ten_chuyen_khoa LIKE ? 
              AND kg.Trang_thai = 'available' 
              AND kg.Thoi_gian_Bdau >= NOW()
            ORDER BY kg.Thoi_gian_Bdau ASC
            LIMIT 1;
        `;
        const [rows] = await execute(query, [`%${specialty}%`]);
        return rows;
    }

    // 9. TÌM LỊCH SỚM NHẤT TRÊN TOÀN HỆ THỐNG (KHÔNG CẦN KHOA) (Dùng cho câu hỏi: "Sắp xếp cho tôi khám sớm nhất có thể")
    static async findEarliestSlotAnySpecialty() {
        const query = `
            SELECT 
                bs.Ma_bac_si, nd.Ten_nguoi_dung AS ten_bac_si, ck.Ten_chuyen_khoa,
                kg.Ma_khung_gio, DATE_FORMAT(kg.Thoi_gian_Bdau, '%Y-%m-%d %H:%i') AS start_time
            FROM khung_gio_kham kg
            JOIN bac_si bs ON kg.Ma_bac_si = bs.Ma_bac_si
            JOIN nguoi_dung nd ON bs.Ma_nguoi_dung = nd.Ma_nguoi_dung
            JOIN chuyen_khoa ck ON bs.Ma_chuyen_khoa = ck.Ma_chuyen_khoa
            WHERE kg.Trang_thai = 'available' 
              AND kg.Thoi_gian_Bdau >= NOW()
            ORDER BY kg.Thoi_gian_Bdau ASC
            LIMIT 1;
        `;
        const [rows] = await execute(query, []);
        return rows;
    }

    // 10. CHỐT ĐẶT LỊCH HẸN VÀO DATABASE
    static async createNewAppointment(userId, maKhungGio, maBacSi, maDichVu = null, giaTien = 0) {
        try {
            const dateStr = new Date().toISOString().split('T')[0].replace(/-/g, '');
            const randomCode = Math.floor(1000 + Math.random() * 9000);
            const maBooking = `BK${dateStr}_${randomCode}`;

            // 1. Tạo lịch hẹn gốc (Với Tổng tiền lấy từ tham số truyền vào)
            const sqlInsertLichHen = `
                INSERT INTO lich_hen (Ma_booking, Ma_bac_si, Ma_benh_nhan, Ma_khung_gio, Hinh_thuc, Trang_thai_lich_hen, Tong_tien, Ngay_tao) 
                VALUES (?, ?, ?, ?, 'offline', 'pending', ?, NOW())
            `;
            const [insertResult] = await execute(sqlInsertLichHen, [maBooking, maBacSi, userId, maKhungGio, giaTien]);
            const maLichHen = insertResult.insertId;

            // 2. NẾU CÓ CHỈ ĐỊNH DỊCH VỤ -> Ghi vào bảng chi_tiet_lich_hen
            if (maDichVu && giaTien > 0) {
                const sqlInsertChiTiet = `
                    INSERT INTO chi_tiet_lich_hen (Ma_lich_hen, Ma_dich_vu, Gia_tien)
                    VALUES (?, ?, ?)
                `;
                await execute(sqlInsertChiTiet, [maLichHen, maDichVu, giaTien]);
            }

            // 3. Khóa khung giờ ('booked')
            const sqlUpdateKhungGio = `UPDATE khung_gio_kham SET Trang_thai = 'booked' WHERE Ma_khung_gio = ?`;
            await execute(sqlUpdateKhungGio, [maKhungGio]);

            // 4. Lưu vết lịch sử
            const sqlInsertLichSu = `
                INSERT INTO lich_su_trang_thai_lich_hen (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Nguoi_thay_doi, Ngay_thay_doi)
                VALUES (?, NULL, 'pending', 'patient', NOW())
            `;
            await execute(sqlInsertLichSu, [maLichHen]);

            return maBooking; 
        } catch (error) {
            console.error("Lỗi Model Đặt lịch:", error);
            throw new Error('Không thể ghi dữ liệu đặt lịch.');
        }
    }
}