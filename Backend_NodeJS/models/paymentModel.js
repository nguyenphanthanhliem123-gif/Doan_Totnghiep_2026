import { beginTransaction, commitTransaction, execute, rollbackTransaction } from '../config/db.js';


export default class paymentModel{
    static async getPaymentHistory(userID){
        try{
                // Câu lệnh SQL JOIN 3 bảng dựa trên cấu trúc DB của bạn
            const query = `
                SELECT 
                    tt.Ma_thanh_toan AS paymentId,
                    tt.Ma_lich_hen AS scheduleId,
                    tt.Ma_giao_dich AS transactionId,
                    lh.Ma_booking AS bookingCode,
                    tt.Tong_tien AS amount,
                    tt.Phuong_thuc AS method,
                    tt.Trang_thai_thanh_toan AS status,
                    tt.Thoi_diem_thanh_toan AS transactionDate
                FROM thanh_toan tt
                JOIN lich_hen lh ON tt.Ma_lich_hen = lh.Ma_lich_hen
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                WHERE bn.Ma_nguoi_dung = ?
                ORDER BY tt.Thoi_diem_thanh_toan DESC
            `;

            const [rows] = await execute(query, [userID]);

            // Xử lý dữ liệu thô từ DB thành ngôn ngữ hiển thị cho Frontend
            const formattedData = rows.map(row => {
                // Chuẩn hóa phương thức thanh toán
                let methodDisplay = "Không xác định";
                if (row.method === 'momo') methodDisplay = "Ví MoMo";
                if (row.method === 'cash') methodDisplay = "Tiền mặt";
                if (row.method === 'transfer') methodDisplay = "Chuyển khoản";
                if (row.method === 'vnpay') methodDisplay = "Ví VNPay";

                // Chuẩn hóa trạng thái thanh toán theo yêu cầu
                let statusDisplay = "Chờ xử lý";
                if (row.status === 'paid') statusDisplay = "Thành công";
                if (row.status === 'refunded') statusDisplay = " Đã hoàn tiền";
                if (row.status === 'failed') statusDisplay = "Thất bại";
                if (row.status === 'pending') statusDisplay = "Đang chờ";
                if (row.status === 'refund_fail') statusDisplay = "Hoàn tiền thất bại";

                return {
                    paymentId: row.paymentId,
                    scheduleId: row.scheduleId,
                    transactionId: row.transactionId,
                    bookingCode: row.bookingCode,
                    amount: row.amount,
                    method: methodDisplay,
                    status: statusDisplay,
                    transactionDate: row.transactionDate
                };
            });

            return formattedData;
        }catch(error){
            throw new Error("Lỗi paymentModel.getPaymentHistory(): " + error.message);
        }
    }

    static async getTotalMoney(Ma_lich_hen, Ma_booking){
        try{
            const sql = "SELECT Tong_tien FROM lich_hen WHERE Ma_lich_hen = ? OR Ma_booking = ? LIMIT 1";
            const [rows] = await execute(sql,[Ma_lich_hen, Ma_booking]);

            return rows;
        }
        catch(error){
            throw new Error("Lỗi paymentModel,getTotalMoney: " + error.message);
        }
    }

    static async updateStatus(bookingCode, status){
        try{
            const [result] = await execute(`UPDATE thanh_toan SET Trang_thai_thanh_toan = ? WHERE Ma_lich_hen = (SELECT Ma_lich_hen FROM lich_hen WHERE Ma_booking = ?)`,
                [status, bookingCode]);
            return result.affectedRows;
        }
        catch(error){
            throw new Error("Lỗi PaymentModel.updateStatus: " + error.message);
        }
    }

    static async getPayment(bookingCode) {
        try {
            // 1. Câu SQL lấy thông tin thanh toán chung (Đã bỏ JOIN dich_vu)
            const queryData = `
                SELECT 
                    tt.Ma_thanh_toan,
                    tt.Ma_giao_dich, 
                    lh.Ma_booking, 
                    lh.Ma_lich_hen, -- Bắt buộc lấy thêm trường này để làm điều kiện tìm dịch vụ
                    nt.Ten_nguoi_than AS Ten_benh_nhan, 
                    nd.Email, 
                    ndbs.Ten_nguoi_dung AS Ten_bac_si,
                    lh.Tong_tien,
                    pk.Ten_phong_kham,
                    pk.Vi_tri,
                    pk.Dien_thoai AS Dien_thoai_phong_kham,
                    pk.Email AS Email_phong_kham,
                    kgk.Thoi_gian_Bdau AS Ngay_kham
                FROM thanh_toan tt
                JOIN lich_hen lh ON tt.Ma_lich_hen = lh.Ma_lich_hen
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                JOIN nguoi_dung nd ON bn.Ma_nguoi_dung = nd.Ma_nguoi_dung
                JOIN nguoi_than nt ON nt.Ma_benh_nhan = bn.Ma_benh_nhan
                JOIN bac_si bs ON lh.Ma_bac_si = bs.Ma_bac_si
                JOIN nguoi_dung ndbs ON bs.Ma_nguoi_dung = ndbs.Ma_nguoi_dung
                JOIN khung_gio_kham kgk ON kgk.Ma_khung_gio = lh.Ma_khung_gio
                JOIN phong_kham pk ON pk.Ma_phong_kham = kgk.Ma_phong_kham
                WHERE lh.Ma_booking = ?
            `;
            const [rows] = await execute(queryData, [bookingCode]);

            // Nếu không tìm thấy hóa đơn nào, trả về null để Controller tự xử lý lỗi
            if (rows.length === 0) return null;

            // Tách riêng đối tượng thông tin chung
            const thongTinChung = rows[0];

            // 2. Câu SQL lấy mảng danh sách dịch vụ từ bảng chi_tiet_lich_hen
            const queryServices = `
                SELECT dv.Ma_dich_vu, dv.Ten_dich_vu, ctlh.Gia_tien
                FROM chi_tiet_lich_hen ctlh
                JOIN dich_vu dv ON ctlh.Ma_dich_vu = dv.Ma_dich_vu
                WHERE ctlh.Ma_lich_hen = ?
            `;
            const [services] = await execute(queryServices, [thongTinChung.Ma_lich_hen]);

            // 3. Trả về đúng cấu trúc mảng 2 phần tử theo yêu cầu
            return [
                thongTinChung,                         // Phần tử 0: Đối tượng thông tin chung
                { Danh_sach_dich_vu: services || [] }  // Phần tử 1: Đối tượng chứa mảng dịch vụ
            ];

        } catch (error) {
            throw new Error("Lỗi PaymentModel.getPayment: " + error.message);
        }
    }

    static async getAllPayment(){
        try{
            const sql = `
                SELECT
                    tt.*,
                    nd.Ten_nguoi_dung,
                    nd.Ma_nguoi_dung,
                    nd.Email,
                    nd.Dien_thoai,
                    nd.Anh_dai_dien,
                    lh.Ma_booking,
                    lh.Hinh_thuc,
                    lh.Trang_thai_lich_hen,
                    kg.Thoi_gian_Bdau,
                    kg.Thoi_gian_Kthuc
                FROM
                    thanh_toan tt
                JOIN lich_hen lh ON lh.Ma_lich_hen = tt.Ma_lich_hen
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                JOIN nguoi_dung nd ON bn.Ma_nguoi_dung = nd.Ma_nguoi_dung
                JOIN khung_gio_kham kg ON kg.Ma_khung_gio = lh.Ma_khung_gio
            `;

            const [rows] = await execute(sql);

            return rows;
        }catch(error){
            throw new Error("Lỗi getAllPayment: " + error.message);
        }
    }

    static async updatePaymentStatusForAdmin(paymentId, status, adminId, userId, reason) {
        let conn = await beginTransaction();
        try {
            const query = `UPDATE thanh_toan SET Trang_thai_thanh_toan = ? WHERE Ma_thanh_toan = ?`;
            const [result] = await conn.execute(query, [status, paymentId]);

            const queryAdminLog = `
                INSERT INTO admin_logs(
                    admin_id,
                    action,
                    target_type,
                    target_id,
                    reason
                )
                VALUES(?,?,?,?,?)
            `;

            await conn.execute(queryAdminLog,[adminId, `UPDATE_PAYMENT_STATUS_${status}_${paymentId}`, `USER`, userId, reason]);
            await commitTransaction(conn);
            return result.affectedRows > 0;
        } catch (error) {
            await rollbackTransaction(conn);
            throw new Error("Lỗi updatePaymentStatusForAdmin: " + error.message);
        }
    }

    static async checkPaymentStatus(bookingId){
        try{
            const [status] = await execute(`
                    SELECT Trang_thai_thanh_toan
                    FROM thanh_toan tt
                    JOIN lich_hen lh ON tt.Ma_lich_hen = lh.Ma_lich_hen AND lh.Ma_booking = ?
                `,[bookingId]);
            
            return status

        }catch(error)
        {
            throw new Error("Lỗi lấy trạng thái thanh toán: " + error.message);
        }
    }
}