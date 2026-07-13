// Backend_NodeJS/models/chatbotModel.js
import { execute, beginTransaction, commitTransaction, rollbackTransaction } from "../config/db.js";

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
    static async searchDoctorsBySpecialty(specialty) {
        try {
            const query = `
                SELECT 
                    bs.Ma_bac_si, 
                    nd.Ten_nguoi_dung AS ten_bac_si, 
                    ck.Ten_chuyen_khoa, 
                    bs.Hoc_vi, 
                    bs.Mo_ta_ban_than,
                    AVG(dg.So_sao) AS diem_danh_gia
                FROM bac_si bs
                JOIN nguoi_dung nd ON bs.Ma_nguoi_dung = nd.Ma_nguoi_dung
                JOIN chuyen_khoa ck ON bs.Ma_chuyen_khoa = ck.Ma_chuyen_khoa
                LEFT JOIN danh_gia dg ON bs.Ma_bac_si = dg.Ma_bac_si
                WHERE ck.Ten_chuyen_khoa LIKE ?
                GROUP BY bs.Ma_bac_si 
                ORDER BY diem_danh_gia DESC 
                LIMIT 5;
            `;
            const [rows] = await execute(query, [`%${specialty}%`]);
            return rows;
        } catch (error) {
            console.error("Lỗi Model lấy danh sách bác sĩ: ", error);
            throw new Error("Không thể lấy danh sách bác sĩ.");
        }
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
    static async checkDoctorSchedule(doctorName, targetDate = null) {
        let query = `
            SELECT 
                bs.Ma_bac_si, nd.Ten_nguoi_dung AS ten_bac_si, ck.Ten_chuyen_khoa, kg.Ma_khung_gio,
                DATE_FORMAT(kg.Thoi_gian_Bdau, '%Y-%m-%d %H:%i') AS start_time,
                DATE_FORMAT(kg.Thoi_gian_Kthuc, '%H:%i') AS end_time
            FROM khung_gio_kham kg
            JOIN bac_si bs ON kg.Ma_bac_si = bs.Ma_bac_si
            JOIN nguoi_dung nd ON bs.Ma_nguoi_dung = nd.Ma_nguoi_dung
            JOIN chuyen_khoa ck ON bs.Ma_chuyen_khoa = ck.Ma_chuyen_khoa
            WHERE nd.Ten_nguoi_dung LIKE ? 
              AND kg.Trang_thai = 'available' 
              AND kg.Thoi_gian_Bdau >= NOW() -- LƯỚI AN TOÀN: Chặn lịch quá khứ
        `;
        
        let params = [`%${doctorName}%`];

        // Nếu AI truyền ngày cụ thể vào (VD: 2 ngày tới)
        if (targetDate) {
            query += ` AND DATE(kg.Thoi_gian_Bdau) = ?`;
            params.push(targetDate);
        }

        query += ` ORDER BY kg.Thoi_gian_Bdau ASC LIMIT 10;`;
        
        const [rows] = await execute(query, params);
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
            GROUP_CONCAT(DISTINCT CONCAT(dv.Ten_dich_vu, ' (Mã DV: ', dv.Ma_dich_vu, ') giá ', dv.Gia_tien, ' VNĐ') SEPARATOR ' | ') AS danh_sach_dich_vu,
            -- Nếu gõ sai tên, lấy tên của các bác sĩ khác cùng chuyên khoa để AI làm danh sách gợi ý
                (SELECT GROUP_CONCAT(nd2.Ten_nguoi_dung SEPARATOR ', ') 
                    FROM bac_si bs2 
                    JOIN nguoi_dung nd2 ON bs2.Ma_nguoi_dung = nd2.Ma_nguoi_dung 
                    WHERE bs2.Ma_chuyen_khoa = bs.Ma_chuyen_khoa AND nd2.Ten_nguoi_dung NOT LIKE ?) AS danh_sach_goi_y
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
        // Truyền tham số cho cả câu lệnh loại trừ ở Subquery và câu lệnh chính
        const [rows] = await execute(query, [`%${doctorName}%`, `%${doctorName}%`]);
        return rows;
    }

    // 8. TÌM LỊCH SỚM NHẤT (Hỗ trợ cả tìm theo Chuyên khoa hoặc Tên Bác sĩ)
    static async findEarliestSlot(keyword, isDoctor = false) {
        // Nếu isDoctor = true thì tìm theo tên bác sĩ, ngược lại tìm theo tên chuyên khoa
        let condition = isDoctor ? "nd.Ten_nguoi_dung LIKE ?" : "ck.Ten_chuyen_khoa LIKE ?";
        
        const query = `
            SELECT 
                bs.Ma_bac_si, nd.Ten_nguoi_dung AS ten_bac_si, ck.Ten_chuyen_khoa,
                kg.Ma_khung_gio, DATE_FORMAT(kg.Thoi_gian_Bdau, '%Y-%m-%d %H:%i') AS start_time
            FROM khung_gio_kham kg
            JOIN bac_si bs ON kg.Ma_bac_si = bs.Ma_bac_si
            JOIN nguoi_dung nd ON bs.Ma_nguoi_dung = nd.Ma_nguoi_dung
            JOIN chuyen_khoa ck ON bs.Ma_chuyen_khoa = ck.Ma_chuyen_khoa
            WHERE ${condition} 
              AND kg.Trang_thai = 'available' 
              AND kg.Thoi_gian_Bdau >= NOW()
            ORDER BY kg.Thoi_gian_Bdau ASC
            LIMIT 1;
        `;
        const [rows] = await execute(query, [`%${keyword}%`]);
        return rows;
    }

    // 9. CHỐT ĐẶT LỊCH HẸN VÀO DATABASE BẰNG TRANSACTION (Đồng bộ với luồng Booking chuẩn)
    static async createNewAppointment(userId, maKhungGio, maBacSi, danhSachDichVu = []) {
        let conn = null;
        try {
            conn = await beginTransaction(); // Bắt đầu Transaction

            // 1. SELECT FOR UPDATE: Khóa khung giờ (Chống Race Condition)
            const [checkRows] = await conn.execute(
                `SELECT Trang_thai, DATE_FORMAT(Thoi_gian_Bdau, '%Y-%m-%d') as Ngay_kham, DATE_FORMAT(Thoi_gian_Bdau, '%H:%i') as Gio_kham 
                 FROM khung_gio_kham WHERE Ma_khung_gio = ? FOR UPDATE`,
                [maKhungGio]
            );

            if (checkRows.length === 0) {
                throw new Error("Khung giờ không tồn tại trong hệ thống.");
            }
            if (checkRows[0].Trang_thai !== 'available') {
                throw new Error("Khung giờ này đã bị người khác đặt mất.");
            }

            const ngayKhamThucTe = checkRows[0].Ngay_kham;
            const gioKhamThucTe = checkRows[0].Gio_kham;

            // 2. Lấy ID Bệnh nhân thật từ userId
            const [patientRows] = await conn.execute(`SELECT Ma_benh_nhan FROM benh_nhan WHERE Ma_nguoi_dung = ? LIMIT 1`, [userId]);
            if (patientRows.length === 0) {
                throw new Error("Bạn chưa có hồ sơ bệnh nhân. Vui lòng cập nhật hồ sơ trước khi đặt lịch.");
            }
            const maBenhNhanThat = patientRows[0].Ma_benh_nhan;

            // 3. CHECK TRÙNG LỊCH CÁ NHÂN (Patient Conflict)
            const [conflictRows] = await conn.execute(`
                SELECT COUNT(*) as count 
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                WHERE lh.Ma_benh_nhan = ? 
                AND lh.Trang_thai_lich_hen IN ('pending', 'confirmed')
                AND kg.Thoi_gian_Bdau = ?`, 
                [maBenhNhanThat, checkRows[0].Thoi_gian_Bdau] // Dùng Thoi_gian_Bdau gốc, không format
            );

            if (conflictRows[0].count > 0) {
                throw new Error("Bạn đã có một lịch hẹn khác trùng với khung giờ này!");
            }

            // 4. Tạo mã Booking & Tính tiền
            const dateStr = new Date().toISOString().split('T')[0].replace(/-/g, '');
            const randomCode = Math.floor(1000 + Math.random() * 9000);
            const maBooking = `BK${dateStr}_${randomCode}`;
            
            let tongTien = 0;
            if (danhSachDichVu.length > 0) {
                tongTien = danhSachDichVu.reduce((sum, item) => sum + (item.gia_tien || 0), 0);
            }

            // 5. Tạo lịch hẹn gốc
            const sqlInsertLichHen = `
                INSERT INTO lich_hen (Ma_booking, Ma_bac_si, Ma_benh_nhan, Ma_khung_gio, Hinh_thuc, Trang_thai_lich_hen, Tong_tien, Ngay_tao) 
                VALUES (?, ?, ?, ?, 'offline', 'pending', ?, NOW())
            `;
            const [insertResult] = await conn.execute(sqlInsertLichHen, [maBooking, maBacSi, maBenhNhanThat, maKhungGio, tongTien]);
            const maLichHen = insertResult.insertId; 

            // 6. Ghi chi tiết dịch vụ
            if (danhSachDichVu.length > 0) {
                const sqlInsertChiTiet = `INSERT INTO chi_tiet_lich_hen (Ma_lich_hen, Ma_dich_vu, Gia_tien) VALUES (?, ?, ?)`;
                for (let dv of danhSachDichVu) {
                    await conn.execute(sqlInsertChiTiet, [maLichHen, dv.ma_dich_vu, dv.gia_tien]);
                }
            }

            // 7. Tạo thanh toán
            const maGiaoDich = `TXN_${maBooking}`;
            await conn.execute(
                `INSERT INTO thanh_toan (Ma_lich_hen, Phuong_thuc, Trang_thai_thanh_toan, Ma_giao_dich, Tong_tien) VALUES (?, ?, ?, ?, ?)`,
                [maLichHen, 'cash', 'pending', maGiaoDich, tongTien] // Đặt qua AI auto là trả tiền mặt
            );

            // 8. Khóa khung giờ
            await conn.execute(`UPDATE khung_gio_kham SET Trang_thai = 'booked' WHERE Ma_khung_gio = ?`, [maKhungGio]);

            // 9. Lưu vết lịch sử
            await conn.execute(
                `INSERT INTO lich_su_trang_thai_lich_hen (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Nguoi_thay_doi, Ngay_thay_doi) VALUES (?, NULL, 'pending', 'patient', NOW())`,
                [maLichHen]
            );

            await commitTransaction(conn); // Xác nhận lưu toàn bộ dữ liệu

            return {
                maBooking: maBooking,
                ngayKham: ngayKhamThucTe,
                gioKham: gioKhamThucTe
            }; 
        } catch (error) {
            if (conn) await rollbackTransaction(conn); // Hoàn tác nếu có bất kỳ lỗi gì
            console.error("Lỗi Model Đặt lịch (Transaction):", error.message);
            throw error; 
        }
    }

    // 10. GỢI Ý CHUYÊN KHOA THEO TRIỆU CHỨNG
    static async suggestSpecialtyBySymptom(symptomKeyword) {
        const sql = `
            SELECT Ten_chuyen_khoa, Mo_ta
            FROM chuyen_khoa 
            WHERE Ten_chuyen_khoa LIKE ? OR Mo_ta LIKE ?
            LIMIT 2
        `;
        const [specialties] = await execute(sql, [`%${symptomKeyword}%`, `%${symptomKeyword}%`]);
        return specialties;
    }

    // 11. TRA CỨU ĐƠN THUỐC GẦN NHẤT CỦA BỆNH NHÂN
    static async getRecentPrescription(userId) {
        const query = `
            SELECT 
                dt.Ma_don_thuoc, 
                dt.Chuan_doan_benh, 
                DATE_FORMAT(dt.Ngay_tao, '%d/%m/%Y') AS ngay_kham,
                DATE_FORMAT(dt.Ngay_tai_kham, '%d/%m/%Y') AS ngay_tai_kham,
                GROUP_CONCAT(CONCAT('- ', ct.Ten_thuoc, ': ', ct.So_luong, ' viên (', ct.Lieu_dung, ' - Giờ uống: ', IFNULL(ct.Gio_uong_thuoc, 'Tùy ý'), ')') SEPARATOR '\n') AS chi_tiet_thuoc
            FROM don_thuoc dt
            JOIN lich_hen lh ON dt.Ma_lich_hen = lh.Ma_lich_hen
            JOIN chi_tiet_dthuoc ct ON dt.Ma_don_thuoc = ct.Ma_don_thuoc
            WHERE lh.Ma_benh_nhan = (SELECT Ma_benh_nhan FROM benh_nhan WHERE Ma_nguoi_dung = ? LIMIT 1)
            GROUP BY dt.Ma_don_thuoc
            ORDER BY dt.Ngay_tao DESC
            LIMIT 1;
        `;
        const [rows] = await execute(query, [userId]);
        return rows;
    }

    // 12: Tìm ID khung giờ chính xác dựa vào Tên BS, Ngày và Giờ
    static async findExactSlotId(doctorName, targetDate, targetTime) {
        // targetTime từ AI gửi về sẽ luôn có định dạng "HH:mm" (VD: "08:30", "09:00")
        // Dùng '%H:%i' để MySQL đối chiếu chính xác từng phút, không cắt chuỗi.
        
        const query = `
            SELECT kg.Ma_khung_gio, bs.Ma_bac_si
            FROM khung_gio_kham kg
            JOIN bac_si bs ON kg.Ma_bac_si = bs.Ma_bac_si
            JOIN nguoi_dung nd ON bs.Ma_nguoi_dung = nd.Ma_nguoi_dung
            WHERE nd.Ten_nguoi_dung LIKE ? 
              AND DATE(kg.Thoi_gian_Bdau) = ?
              AND DATE_FORMAT(kg.Thoi_gian_Bdau, '%H:%i') = ? -- Bắt buộc khớp cả giờ và phút
              AND kg.Trang_thai = 'available'
            LIMIT 1;
        `;
        // Truyền thẳng targetTime vào thay vì hourPrefix như code cũ
        const [rows] = await execute(query, [`%${doctorName}%`, targetDate, targetTime]);
        return rows.length > 0 ? rows[0] : null;
    }
}