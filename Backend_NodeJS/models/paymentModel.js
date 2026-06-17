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
}