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

// API Webhook nhận kết quả từ MoMo
momoRouter.post('/momo-webhook', async (req, res) => {
    try {
        console.log("👉 Đã nhận Webhook thành công từ MoMo:", req.body);
        const { resultCode, orderId } = req.body;

        const parts = orderId.split('_');
        const bookingCode = parts[parts.length - 1]; 

        if (resultCode === 0) {
            console.log(`🔥 Vé ${bookingCode} đã thanh toán THÀNH CÔNG!`);
        } else {
            console.log(`❌ Giao dịch cho vé ${bookingCode} không thành công.`);
        }

        return res.status(200).send(); 
    } catch (err) {
        console.error("Lỗi Webhook:", err.message);
        return res.status(500).send();
    }
});

export default momoRouter;