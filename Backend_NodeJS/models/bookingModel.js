import { beginTransaction, commitTransaction, execute, rollbackTransaction } from "../config/db.js";
import moment from 'moment';

export default class bookingModel {
    // Lấy danh sách các ngày CÒN Slot trống của 1 bác sĩ
    static async getAvailableDates(ma_bac_si) {
        try {
            // Lấy thời gian hiện tại chính xác theo múi giờ +07:00 bao gồm cả giờ phút giây
            const currentDateTimeStr = moment().utcOffset('+07:00').format('YYYY-MM-DD HH:mm:ss');
            
            // ✨ ĐÃ SỬA: Lọc trực tiếp điều kiện thời gian trực tiếp tại SQL để loại bỏ hoàn toàn 
            // logic kiểm tra thủ công bằng JS bị lỗi undefined 'row.Gio_Kham'
            const query = `
                SELECT DISTINCT 
                    DATE(kg.Thoi_gian_Bdau) AS Ngay_trong
                FROM khung_gio_kham kg
                JOIN bac_si bs ON kg.Ma_bac_si = bs.Ma_bac_si
                WHERE kg.Ma_bac_si = ? 
                AND kg.Trang_thai = 'available'
                AND bs.Trang_thai_hoat_dong = 'active'
                AND kg.Thoi_gian_Bdau >= ?
                ORDER BY Ngay_trong ASC
            `;
            const [rows] = await execute(query, [ma_bac_si, currentDateTimeStr]);
            return rows.map(row => moment(row.Ngay_trong).format('YYYY-MM-DD'));
        } catch (error) {
            console.error(">>> [LỖI SQL AvailableDates]:", error);
            throw new Error('Lỗi bookingModel.getAvailableDates: ' + error.message);
        }
    }

    // Kiểm tra trạng thái khung giờ (Hỗ trợ Transaction)
    static async getSlot(ma_khung_gio, conn = null) {
        const query = `SELECT Trang_thai, Thoi_gian_Bdau AS Thoi_gian FROM khung_gio_kham WHERE Ma_khung_gio = ?`;
        const [rows] = conn ? await conn.execute(query, [ma_khung_gio]) : await execute(query, [ma_khung_gio]);
        return rows.length ? rows[0] : null;
    }

    // Khóa hàng dữ liệu bằng khóa bi quan (Pessimistic Locking) để chống Race Condition trùng lịch
    static async getSlotForUpdate(ma_khung_gio, conn) {
        console.log("Tiến hàn khóa khung giờ...");
        const query = `SELECT Trang_thai FROM khung_gio_kham WHERE Ma_khung_gio = ? FOR UPDATE`;
        const [rows] = await conn.execute(query, [ma_khung_gio]);
        return rows.length ? rows[0] : null;
    }

    // Lấy giá tiền thật của dịch vụ (Hỗ trợ Transaction)
    static async getServicePrice(ma_dich_vu, conn = null) {
        const query = `SELECT Gia_tien FROM dich_vu WHERE Ma_dich_vu = ?`;
        const [rows] = conn ? await conn.execute(query, [ma_dich_vu]) : await execute(query, [ma_dich_vu]);
        return rows.length ? rows[0] : null;
    }

    // Kiểm tra trùng lịch hẹn thực tế (Hỗ trợ Transaction)
    static async getSlotReal(Ma_khung_gio, conn = null){
        const checkSql = `
            SELECT COUNT(*) as count 
            FROM lich_hen 
            WHERE Ma_khung_gio = ? 
              AND Trang_thai_lich_hen IN ('pending', 'confirmed')
        `;
        const [rows] = conn ? await conn.execute(checkSql, [Ma_khung_gio]) : await execute(checkSql, [Ma_khung_gio]);
        return rows;
    }

    // Tạo lịch hẹn mới vào Database (Chạy bên trong Transaction được truyền vào từ Controller)
    static async createAppointment(data, conn) {
        const query = `
            INSERT INTO lich_hen 
            (Ma_booking, Ma_bac_si, Ma_benh_nhan, Ma_nguoi_than, Ma_khung_gio, Hinh_thuc, Trieu_chung, Trang_thai_lich_hen, Tong_tien, Link_video_call) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;

        const linkJitsi = data.Hinh_thuc === 'online' ? `https://meet.ffmuc.net/${data.Ma_booking}` : null;
        
        const params = [
            data.Ma_booking,       
            data.Ma_bac_si,        
            data.Ma_benh_nhan,     
            data.Ma_nguoi_than,    
            data.Ma_khung_gio,     
            data.Hinh_thuc,        
            data.Trieu_chung,      
            'pending',             
            data.Tong_tien,        
            linkJitsi              
        ];

        const [result] = await conn.execute(query, params);
        const insertId = result.insertId;

        // Ghi nhận lịch sử tạo mới liền mạch trong cùng kết nối hệ thống
        await conn.execute(
            `INSERT INTO lich_su_trang_thai_lich_hen (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Nguoi_thay_doi) 
            VALUES (?, NULL, 'pending', 'patient')`,
            [insertId]
        );

        return insertId;
    }

    // Tạo chi tiết lịch hẹn vào Database (Hỗ trợ Transaction)
    static async createAppointmentDetail(detailData, conn) {
        const query = `
            INSERT INTO chi_tiet_lich_hen (Ma_lich_hen, Ma_dich_vu, Gia_tien) 
            VALUES (?, ?, ?)
        `;
        const [result] = await conn.execute(query, [
            detailData.Ma_lich_hen,
            detailData.Ma_dich_vu,
            detailData.Gia_tien
        ]);
        return result.insertId;
    }

    // Cập nhật lại khung giờ thành 'booked' (Hỗ trợ Transaction)
    static async updateSlotStatus(ma_khung_gio, status, conn) {
        const query = `UPDATE khung_gio_kham SET Trang_thai = ? WHERE Ma_khung_gio = ?`;
        await conn.execute(query, [status, ma_khung_gio]);
    }

    // Hàm tiện ích: Lấy Ma_benh_nhan từ Ma_nguoi_dung
    static async getPatientIdByUserId(ma_nguoi_dung) {
        const query = `SELECT Ma_benh_nhan FROM benh_nhan WHERE Ma_nguoi_dung = ?`;
        const [rows] = await execute(query, [ma_nguoi_dung]);
        return rows.length ? rows[0].Ma_benh_nhan : null;
    }


    static async checkPatienID(maBenhNhan, maNguoiThan = null, conn = null) {
        if (maNguoiThan) {
            // TRƯỜNG HỢP 1: Đặt cho người thân -> Xác thực cặp mã người thân & mã bệnh nhân có khớp nhau không
            const query = `
                SELECT Ma_benh_nhan 
                FROM nguoi_than 
                WHERE Ma_nguoi_than = ? AND Ma_benh_nhan = ?
            `;
            const [rows] = conn 
                ? await conn.execute(query, [maNguoiThan, maBenhNhan]) 
                : await execute(query, [maNguoiThan, maBenhNhan]);
                
            return rows.length ? rows[0].Ma_benh_nhan : null;
        } else {
            // TRƯỜNG HỢP 2: Đặt cho bản thân -> Xác thực xem mã bệnh nhân này có đúng là chính chủ không
            const query = `
                SELECT Ma_benh_nhan
                FROM nguoi_than
                WHERE Ma_benh_nhan = ? AND Quan_he = 'Bản thân'
            `;
            const [rows] = conn 
                ? await conn.execute(query, [maBenhNhan]) 
                : await execute(query, [maBenhNhan]);
                
            return rows.length ? rows[0].Ma_benh_nhan : null;
        }
    }

    // Lấy lịch làm việc chi tiết trong 1 ngày
    static async getDoctorSchedule(date){
        try{
            const query = `
                SELECT kgk.*, 
                    DATE_FORMAT(kgk.Thoi_gian_Bdau, '%H:%i') AS Gio_Kham 
                FROM khung_gio_kham kgk 
                JOIN bac_si bs ON bs.Ma_bac_si = kgk.Ma_bac_si
                JOIN nguoi_dung nd ON nd.Ma_nguoi_dung = bs.Ma_nguoi_dung
                JOIN phong_kham pk ON pk.Ma_phong_kham = kgk.Ma_phong_kham
                WHERE DATE(kgk.Thoi_gian_Bdau) = ? 
                AND kgk.Trang_thai = 'available'
                AND bs.Trang_thai_hoat_dong = 'active'
                ORDER BY kgk.Thoi_gian_Bdau ASC
            `;

            const [rows] = await execute(query, [date]);
            if (!rows || rows.length === 0) return [];

            const todayStr = moment().utcOffset('+07:00').format('YYYY-MM-DD');
            
            if (date === todayStr) {
                const currentHHmm = moment().utcOffset('+07:00').format('HH:mm');
                return rows.filter(row => row.Gio_Kham > currentHHmm);
            }

            return rows;
        }
        catch(error){
            console.error(">>> [LỖI SQL Schedule]:", error);
            throw new Error('Lỗi bookingModel.getDoctorSchedule: ' + error.message);
        }
    }
    
    // Hàm lưu thông tin thanh toán (Hỗ trợ Transaction)
    static async createPayment(paymentData, conn) {
        const query = `INSERT INTO thanh_toan (Ma_lich_hen, Phuong_thuc, Trang_thai_thanh_toan, Ma_giao_dich, Tong_tien) 
                       VALUES (?, ?, ?, ?, ?)`;
        const [result] = await conn.execute(query, [
            paymentData.Ma_lich_hen,
            paymentData.Phuong_thuc,
            paymentData.Trang_thai_thanh_toan,
            paymentData.Ma_giao_dich,
            paymentData.Tong_tien
        ]);
        return result.insertId;
    }

    static async saveTransactionCode(transactionCode, date, paymentCode){
        try{
            const query = `
                UPDATE thanh_toan 
                SET Ma_giao_dich = ?, Thoi_diem_thanh_toan = ?
                WHERE Ma_thanh_toan = ?
            `;
            const [result] = await execute(query, [transactionCode, date, paymentCode]);
            return result.affectedRows;
        }catch(error){
            throw new Error("Lỗi paymentModel.saveTransactionCode: " + error.message);
        }
    }

    // Kiểm tra trùng lịch hẹn của bệnh nhân
    static async checkPatientConflict(maBenhNhan, maKhungGio) {
        try {
            const query = `
                SELECT COUNT(*) as count 
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                WHERE lh.Ma_benh_nhan = ? 
                AND lh.Trang_thai_lich_hen IN ('pending', 'confirmed')
                AND kg.Thoi_gian_Bdau = (SELECT Thoi_gian_Bdau FROM khung_gio_kham WHERE Ma_khung_gio = ?)
            `;
            const [rows] = await execute(query, [maBenhNhan, maKhungGio]);
            return rows[0].count > 0;
        } catch (error) {
            throw new Error("Lỗi kiểm tra trùng lịch bệnh nhân: " + error.message);
        }
    }

    static async checkAmount(maBenhNhanThat, ngayDat, conn) {
        const [rows] = await conn.execute(
            `SELECT COUNT(*) as total 
            FROM lich_hen 
            WHERE Ma_benh_nhan = ? 
            AND DATE(Ngay_tao) = ? 
            AND Trang_thai_lich_hen IN ('pending', 'confirmed')`,
            [maBenhNhanThat, ngayDat]
        );

        return rows[0] || { total: 0 };
    }

    // Xử lý toàn bộ quy trình đặt lịch trong 1 Transaction
    static async createBookingTransaction(data, thongTinDichVu, paymentData) {
        let conn = await beginTransaction();
        try {
            // 1. SELECT FOR UPDATE: Khóa khung giờ để chống Race Condition cho khung giờ đó
            const [rows] = await conn.execute(
                `SELECT Trang_thai, Thoi_gian_Bdau FROM khung_gio_kham WHERE Ma_khung_gio = ? FOR UPDATE`, 
                [data.Ma_khung_gio]
            );

            if (rows.length === 0 || rows[0].Trang_thai !== 'available') {
                throw new Error("Khung giờ này không khả dụng hoặc đã có người đặt.");
            }

            // 2. CHECK TRÙNG LỊCH CÁ NHÂN (Patient Conflict)
            // Kiểm tra bệnh nhân đã có lịch nào khác vào đúng thời điểm đó chưa
            const [conflictRows] = await conn.execute(`
                SELECT COUNT(*) as count 
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                WHERE lh.Ma_benh_nhan = ? 
                AND lh.Trang_thai_lich_hen IN ('pending', 'confirmed')
                AND kg.Thoi_gian_Bdau = ?`, 
                [data.Ma_benh_nhan, rows[0].Thoi_gian_Bdau]
            );

            if (conflictRows[0].count > 0) {
                throw new Error("Bạn đã có một lịch hẹn khác vào khung giờ này!");
            }

            // 3. Tạo lịch hẹn (Vỏ)
            const sqlInsertLichHen = `
                INSERT INTO lich_hen (Ma_booking, Ma_bac_si, Ma_benh_nhan, Ma_nguoi_than, Ma_khung_gio, Hinh_thuc, Trieu_chung, Trang_thai_lich_hen, Tong_tien, Ngay_tao) 
                VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', ?, NOW())
            `;
            const [insertResult] = await conn.execute(sqlInsertLichHen, [
                data.Ma_booking, data.Ma_bac_si, data.Ma_benh_nhan, data.Ma_nguoi_than, 
                data.Ma_khung_gio, data.Hinh_thuc, data.Trieu_chung, data.Tong_tien
            ]);
            const maLichHen = insertResult.insertId;

            // 4. Tạo chi tiết lịch hẹn
            for (const item of thongTinDichVu) {
                await conn.execute(
                    `INSERT INTO chi_tiet_lich_hen (Ma_lich_hen, Ma_dich_vu, Gia_tien) VALUES (?, ?, ?)`,
                    [maLichHen, item.id, item.price]
                );
            }

            // 5. Tạo thanh toán
            await conn.execute(
                `INSERT INTO thanh_toan (Ma_lich_hen, Phuong_thuc, Trang_thai_thanh_toan, Ma_giao_dich, Tong_tien) VALUES (?, ?, ?, ?, ?)`,
                [maLichHen, paymentData.Phuong_thuc, paymentData.Trang_thai_thanh_toan, paymentData.Ma_giao_dich, paymentData.Tong_tien]
            );

            // 6. Update trạng thái khung giờ
            await conn.execute(`UPDATE khung_gio_kham SET Trang_thai = 'booked' WHERE Ma_khung_gio = ?`, [data.Ma_khung_gio]);

            // 7. Lưu log
            await conn.execute(
                `INSERT INTO lich_su_trang_thai_lich_hen (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Nguoi_thay_doi, Ngay_thay_doi) VALUES (?, NULL, 'pending', 'patient', NOW())`,
                [maLichHen]
            );

            await commitTransaction(conn);
            return { maLichHen, maBooking: data.Ma_booking };

        } catch (error) {
            if (conn) await rollbackTransaction(conn);
            throw error; 
        }
    }
}