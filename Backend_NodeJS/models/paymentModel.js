import { execute } from '../config/db.js';

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

                // Chuẩn hóa trạng thái thanh toán theo yêu cầu
                let statusDisplay = "Chờ xử lý";
                if (row.status === 'paid') statusDisplay = "Thành công";
                if (row.status === 'refunded') statusDisplay = "Hoàn tiền";
                if (row.status === 'failed') statusDisplay = "Thất bại";
                if (row.status === 'pending') statusDisplay = "Đang chờ";

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

    static async updateStatus(bookingCode){
        try{
            const [result] = await execute(`UPDATE thanh_toan SET Trang_thai_thanh_toan = 'paid' WHERE Ma_lich_hen = (SELECT Ma_lich_hen FROM lich_hen WHERE Ma_booking = ?)`,
                [bookingCode]);
            return result.affectedRows;
        }
        catch(error){
            throw new Error("Lỗi PaymentModel.updateStatus: " + error.message);
        }
    }

    static async getPayment(bookingCode){
        try{
            const queryData = `
                SELECT 
                    tt.Ma_giao_dich, 
                    lh.Ma_booking, 
                    nt.Ten_nguoi_than AS Ten_benh_nhan, 
                    nd.Email, 
                    ndbs.Ten_nguoi_dung AS Ten_bac_si,
                    lh.Tong_tien,
                    dv.Ten_dich_vu,
                    pk.Ten_phong_kham,
                    pk.Vi_tri
                FROM thanh_toan tt
                JOIN lich_hen lh ON tt.Ma_lich_hen = lh.Ma_lich_hen
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                JOIN nguoi_dung nd ON bn.Ma_nguoi_dung = nd.Ma_nguoi_dung
                JOIN nguoi_than nt ON nt.Ma_benh_nhan = bn.Ma_benh_nhan
                JOIN bac_si bs ON lh.Ma_bac_si = bs.Ma_bac_si
                JOIN nguoi_dung ndbs ON bs.Ma_nguoi_dung = ndbs.Ma_nguoi_dung
                JOIN dich_vu dv ON lh.Ma_dich_vu = dv.Ma_dich_vu
                JOIN khung_gio_kham kgk ON kgk.Ma_khung_gio = lh.Ma_khung_gio
                JOIN phong_kham pk ON pk.Ma_phong_kham = kgk.Ma_phong_kham
                WHERE lh.Ma_booking = ?
            `;
            const [rows] = await execute(queryData, [bookingCode]);

            return rows.length > 0? rows: null;
        }catch(error){
            throw new Error("Lỗi PaymentModel.getPayment: " + error.message);
        }
    }
}