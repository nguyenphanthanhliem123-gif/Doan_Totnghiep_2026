import { Router } from "express";
import crypto from 'crypto';
import axios from "axios";

const momoRouter = Router();

// Sử dụng bộ key Sandbox mặc định của MoMo (Không bị khóa, không cần đăng ký)
const partnerCode = "MOMO5RGX20191128";
const accessKey = "M83RhWfCvvRzo8pa";
const secretKey = "qsnfNxZvhDtt9g5g9thST6P7s6W1YscE";
const momoApiUrl = "https://test-payment.momo.vn/v2/gateway/api/create";

momoRouter.post('/create-momo-payment', async (req, res) => {
    try {
        const { bookingCode, amount } = req.body;

        const orderId = `DH_${new Date().getTime()}_${bookingCode}`;
        const requestId = `REQ_${new Date().getTime()}`;
        const orderInfo = `Thanh toan dat lich kham cho ve: ${bookingCode}`;
        const redirectUrl = "myapp://momo-callback";
        const ipnUrl = "https://irretentive-alex-wanly.ngrok-free.dev/api/booking-momo/momo-webhook"; 
        const requestType = "captureWallet";
        const extraData = ""; 

        // 🌟 SẮP XẾP THỦ CÔNG THEO ĐÚNG THỨ TỰ ALPHABET CỦA MOMO (Chữ viết hoa đứng trước chữ viết thường)
        // Thứ tự chuẩn: accessKey -> amount -> extraData -> ipnUrl -> orderId -> orderInfo -> partnerCode -> redirectUrl -> requestId -> requestType
        const rawSignature = `accessKey=${accessKey}&amount=${Number(amount)}&extraData=${extraData}&ipnUrl=${ipnUrl}&orderId=${orderId}&orderInfo=${orderInfo}&partnerCode=${partnerCode}&redirectUrl=${redirectUrl}&requestId=${requestId}&requestType=${requestType}`;
        
        // Tạo chữ ký mã hóa
        const signature = crypto.createHmac('sha256', secretKey).update(rawSignature).digest('hex');

        // Tạo Body đúng cấu trúc để gửi lên MoMo
        const requestBody = {
            partnerCode,
            requestId,
            orderId,
            amount: Number(amount),
            orderInfo,
            redirectUrl,
            ipnUrl,
            requestType,
            extraData,
            signature,
            lang: 'vi'
        };

        const momoResponse = await axios.post(momoApiUrl, requestBody);

        return res.status(200).json({
            succeeded: true,
            payUrl: momoResponse.data.payUrl,
            deeplink: momoResponse.data.deeplink,
        });

    } catch (error) {
        if (error.response) {
            console.error("Lỗi từ MoMo:", error.response.data);
            return res.status(500).json({ succeeded: false, message: "Cổng thanh toán MoMo từ chối" });
        }
        console.error("Lỗi kết nối:", error.message);
        return res.status(500).json({ succeeded: false, message: "Lỗi kết nối hệ thống" });
    }
});

momoRouter.post('/momo-webhook', async (req, res) => {
    try {
        console.log("👉 Đã nhận Webhook thành công từ MoMo:", req.body);
        const { resultCode, orderId, amount } = req.body; // Lấy thêm amount

        const parts = orderId.split('_');
        const bookingCode = parts[parts.length - 1]; 

        if (resultCode === 0) {
            console.log(`🔥 Vé ${bookingCode} đã thanh toán THÀNH CÔNG!`);
            
            // 1. THỰC HIỆN CẬP NHẬT TRẠNG THÁI DATABASE (Ví dụ)
            await db.execute(
                `UPDATE thanh_toan SET Trang_thai_thanh_toan = 'paid' WHERE Ma_lich_hen = (SELECT Ma_lich_hen FROM lich_hen WHERE Ma_booking = ?)`,
                [bookingCode]
            );

            // 2. TRUY VẤN LẤY THÔNG TIN ĐỂ IN HÓA ĐƠN
            // Viết câu lệnh JOIN để lấy tên bệnh nhân, bác sĩ, email từ DB của bạn
            const queryData = `
                SELECT 
                    tt.Ma_giao_dich, 
                    lh.Ma_booking, 
                    bn.Ho_ten AS Ten_benh_nhan, 
                    nd.Email, 
                    bs.Ho_ten AS Ten_bac_si,
                    'Khám tổng quát' AS Ten_dich_vu -- Bạn có thể JOIN thêm bảng Dịch vụ nếu có
                FROM thanh_toan tt
                JOIN lich_hen lh ON tt.Ma_lich_hen = lh.Ma_lich_hen
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                JOIN nguoi_dung nd ON bn.Ma_nguoi_dung = nd.Ma_nguoi_dung
                JOIN bac_si bs ON lh.Ma_bac_si = bs.Ma_bac_si
                WHERE lh.Ma_booking = ?
            `;
            const [rows] = await db.execute(queryData, [bookingCode]);

            // 3. GỌI HÀM GỬI EMAIL NẾU TÌM THẤY DỮ LIỆU
            if (rows.length > 0) {
                const thongTinHoaDon = {
                    maGiaoDich: rows[0].Ma_giao_dich,
                    maBooking: rows[0].Ma_booking,
                    tenBenhNhan: rows[0].Ten_benh_nhan,
                    emailNguoiDung: rows[0].Email,
                    tenBacSi: rows[0].Ten_bac_si,
                    tenDichVu: rows[0].Ten_dich_vu,
                    soTien: amount
                };

                // Chạy ngầm việc gửi email để không làm chậm phản hồi (response) về MoMo
                taoVaGuiHoaDonPDF(thongTinHoaDon).catch(err => console.error("Lỗi gửi email ngầm:", err));
            }

        } else {
            console.log(`❌ Giao dịch cho vé ${bookingCode} thất bại.`);
            // Có thể update trạng thái failed vào DB ở đây
        }

        return res.status(200).send(); 
    } catch (err) {
        console.error("Lỗi Webhook:", err.message);
        return res.status(500).send();
    }
});

export default momoRouter;