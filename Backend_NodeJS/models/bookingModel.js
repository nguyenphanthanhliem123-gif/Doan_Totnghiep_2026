import { execute } from "../config/db.js";

export default class bookingModel {
    // Lấy danh sách các ngày CÒN SLOT TRỐNG của 1 bác sĩ
    static async getAvailableDates(ma_bac_si) {
        const query = `
            SELECT DISTINCT DATE(Thoi_gian_Bdau) AS Ngay_trong 
            FROM khung_gio_kham 
            WHERE Ma_bac_si = ? AND Trang_thai = 'available'
            ORDER BY Ngay_trong ASC
        `;
        const [rows] = await execute(query, [ma_bac_si]);
        // Trả về mảng các chuỗi ngày dạng YYYY-MM-DD (Ví dụ: ['2026-07-07', '2026-07-08'])
        return rows.map(row => row.Ngay_trong.toISOString().split('T')[0]);
    }

    // Kiểm tra trạng thái khung giờ
    static async getSlot(ma_khung_gio) {
        const query = `SELECT Trang_thai FROM khung_gio_kham WHERE Ma_khung_gio = ?`;
        const [rows] = await execute(query, [ma_khung_gio]);
        return rows.length ? rows[0] : null;
    }

    // Lấy giá tiền thật của dịch vụ
    static async getServicePrice(ma_dich_vu) {
        const query = `SELECT Gia_tien FROM dich_vu WHERE Ma_dich_vu = ?`;
        const [rows] = await execute(query, [ma_dich_vu]);
        return rows.length ? rows[0] : null;
    }

    static async getSlotReal(Ma_khung_gio){
        try{
               const checkSql = `
                    SELECT COUNT(*) as count 
                    FROM lich_hen 
                    WHERE Ma_khung_gio = ? AND Trang_thai_lich_hen != 'cancelled'
                `;
                const [rows] = await execute(checkSql, [Ma_khung_gio]);

                return rows;
        }catch(error){
            throw new Error("Lỗi bookingModel.getSlotReal: " + error.message);
        }
    }


    // Tạo lịch hẹn mới vào Database
    static async createAppointment(data) {
        const query = `
            INSERT INTO lich_hen 
            (Ma_booking, Ma_bac_si, Ma_benh_nhan, Ma_nguoi_than, Ma_khung_gio, Hinh_thuc, Trieu_chung, Trang_thai_lich_hen, Tong_tien, Link_video_call) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;
<<<<<<< HEAD

        const linkJitsi = data.Hinh_thuc == 'online' ? "https://meet.ffmuc.net/": null;
        // 🌟 ĐÃ FIX: Xóa data.Ma_dich_vu khỏi params
        const params = [
            data.Ma_booking, data.Ma_bac_si, data.Ma_benh_nhan, data.Ma_nguoi_than, 
            data.Ma_khung_gio, data.Hinh_thuc, data.Trieu_chung, data.Tong_tien, linkJitsi + data.Ma_booking
=======
        const params = [
            data.Ma_booking, data.Ma_bac_si, data.Ma_benh_nhan, data.Ma_nguoi_than, data.Ma_khung_gio, data.Hinh_thuc, data.Trieu_chung, 'pending', data.Tong_tien, "https://meet.ffmuc.net/" + data.Ma_booking
>>>>>>> 171b0d7436586421d2ae33ef013141cae4fc3bc5
        ];
        const [result] = await execute(query, params);
        const insertId = result.insertId;

        // Ghi nhận lịch sử tạo mới
        await execute(
            `INSERT INTO lich_su_trang_thai_lich_hen (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Nguoi_thay_doi) 
             VALUES (?, NULL, 'pending', 'patient')`,
            [insertId]
        );

        return insertId;
    }

    // Tạo chi tiết lịch hẹn vào Database
    static async createAppointmentDetail(detailData) {
        const query = `
            INSERT INTO chi_tiet_lich_hen (Ma_lich_hen, Ma_dich_vu, Gia_tien) 
            VALUES (?, ?, ?)
        `;
        const [result] = await execute(query, [
            detailData.Ma_lich_hen,
            detailData.Ma_dich_vu,
            detailData.Gia_tien
        ]);
        return result.insertId;
    }

    // Cập nhật lại khung giờ thành 'booked' (Đã đầy)
    static async updateSlotStatus(ma_khung_gio, status) {
        const query = `UPDATE khung_gio_kham SET Trang_thai = ? WHERE Ma_khung_gio = ?`;
        await execute(query, [status, ma_khung_gio]);
    }

    // Hàm tiện ích: Lấy Ma_benh_nhan từ Ma_nguoi_dung
    static async getPatientIdByUserId(ma_nguoi_dung) {
        const query = `SELECT Ma_benh_nhan FROM benh_nhan WHERE Ma_nguoi_dung = ?`;
        const [rows] = await execute(query, [ma_nguoi_dung]);
        return rows.length ? rows[0].Ma_benh_nhan : null;
    }

    static async getDoctorSchedule(date){
        try{
            const query = `
                SELECT * 
                FROM khung_gio_kham kgk 
                    JOIN bac_si bs ON bs.Ma_bac_si = kgk.Ma_bac_si
                    JOIN nguoi_dung nd ON nd.Ma_nguoi_dung = bs.Ma_nguoi_dung
                    JOIN phong_kham pk ON  pk.Ma_phong_kham = kgk.Ma_phong_kham
                WHERE  DATE(kgk.Thoi_gian_Bdau)  = ? AND kgk.Trang_thai = 'available'
            `;

            const [rows] = await execute(query,[date]);

            return rows.length ?  rows : null;
        }
        catch(error){
            throw new Error('Lỗi bookingModel.getDoctorSchedule: ' + error.message);
        }
    }
    // Hàm lưu thông tin thanh toán
    static async createPayment(paymentData) {
        const query = `INSERT INTO thanh_toan (Ma_lich_hen, Phuong_thuc, Trang_thai_thanh_toan, Ma_giao_dich, Tong_tien) 
                       VALUES (?, ?, ?, ?, ?)`;
        const [result] = await execute(query, [
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
}