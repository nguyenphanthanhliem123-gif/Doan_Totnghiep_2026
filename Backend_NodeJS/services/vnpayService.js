import crypto from 'crypto';
import moment from 'moment';
import axios from 'axios';

export default class VNPayServices{
    static async xulyHoanTienVNPay(thongTinGiaoDich){
        try {
            process.env.TZ = 'Asia/Ho_Chi_Minh';
            const date = new Date();
            
            // 1. Chuẩn bị các tham số theo đúng tài liệu VNPay WebAPI v2.1.0
            const vnp_RequestId = moment(date).format('HHmmss') + '_' + thongTinGiaoDich.maBooking; // Mã duy nhất cho mỗi yêu cầu hoàn tiền
            const vnp_Version = '2.1.0';
            const vnp_Command = 'refund';
            const vnp_TmnCode = process.env.VNP_TMN_CODE;
            const vnp_TransactionType = '02'; // '02' là hoàn tiền toàn phần (Full Refund), '03' là một phần
            const vnp_TxnRef = thongTinGiaoDich.maBooking; // Mã đơn hàng gốc lúc thanh toán
            const vnp_Amount = Math.round(parseFloat(thongTinGiaoDich.soTien) * 100); // Số tiền hoàn * 100
            const vnp_TransactionNo = thongTinGiaoDich.maGiaoDich; // Mã giao dịch của VNPay cấp lúc thanh toán thành công
            
            // Định dạng ngày giao dịch gốc và ngày tạo lệnh hoàn: YYYYMMDDHHmmss
            const vnp_TransactionDate = moment(thongTinGiaoDich.ngayThanhToan).format('YYYYMMDDHHmmss'); 
            // Tạm thời cộng thêm 5 phút để né việc lệch múi giờ với VNPay Sandbox
            const vnp_CreateDate = moment(date).add(5, 'minutes').format('YYYYMMDDHHmmss');
            
            const vnp_CreateBy = 'System_Auto_Refund'; // Tác nhân tạo lệnh
            const vnp_IpAddr = '127.0.0.1'; // IP Server
            const vnp_OrderInfo = `Hoan tien tu dong cho lich hen ${thongTinGiaoDich.maBooking}`;

            // 2. Tạo chuỗi ký bảo mật (Hash) theo quy định nghiêm ngặt của VNPay bằng dấu |
            const signData = [
                vnp_RequestId,
                vnp_Version,
                vnp_Command,
                vnp_TmnCode,
                vnp_TransactionType,
                vnp_TxnRef,
                vnp_Amount,
                vnp_TransactionNo,
                vnp_TransactionDate,
                vnp_CreateBy,
                vnp_CreateDate,
                vnp_IpAddr,
                vnp_OrderInfo
            ].join('|');

            const secretKey = process.env.VNP_HASH_SECRET;
            const hmac = crypto.createHmac("sha512", secretKey);
            const vnp_SecureHash = hmac.update(Buffer.from(signData, 'utf-8')).digest("hex");

            // 3. Đóng gói Payload thành JSON
            const dataBody = {
                vnp_RequestId,
                vnp_Version,
                vnp_Command,
                vnp_TmnCode,
                vnp_TransactionType,
                vnp_TxnRef,
                vnp_Amount,
                vnp_TransactionNo,
                vnp_TransactionDate,
                vnp_CreateDate,
                vnp_CreateBy,
                vnp_IpAddr,
                vnp_OrderInfo,
                vnp_SecureHash
            };
            console.log("👉 Đang gửi Payload này sang VNPay:", JSON.stringify(dataBody, null, 2));

            console.log(`[VNPay Refund] Đang gửi yêu cầu hoàn tiền cho Booking: ${vnp_TxnRef}...`);

            // 4. Gọi API sang VNPay
            const response = await axios.post(process.env.VNP_API_URL, dataBody, {
                headers: { 'Content-Type': 'application/json' }
            });

            // 5. Kiểm tra kết quả phản hồi từ VNPay
            if (response.data && response.data.vnp_ResponseCode === '00') {
                console.log(`✅ [VNPay Refund] Hoàn tiền THÀNH CÔNG cho Booking ${vnp_TxnRef}. Mã phản hồi: ${response.data.vnp_ResponseCode}`);
                return true;
            } else {
                console.error(`❌ [VNPay Refund] Thất bại. Mã lỗi VNPay: ${response.data ? response.data.vnp_ResponseCode : 'Không rõ'}`);
                return false;
            }

        } catch (error) {
            console.error("❌ [VNPay Refund] Lỗi kết nối hệ thống VNPay WebAPI:", error.message);
            return false;
        }
    }
}