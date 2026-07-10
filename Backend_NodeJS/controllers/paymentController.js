import paymentModel from "../models/paymentModel.js";
import moment from 'moment';
import crypto from 'crypto';
import qs from 'qs';
import VNPayServices from "../services/vnpayService.js";
import { taoVaGuiHoaDonPDF } from "../utils/invoiceService.js";
import appointmentModel from "../models/AppointmentModel.js";
import bookingModel from "../models/bookingModel.js";
import e from "express";

// Hàm bắt buộc của VNPay dùng để sắp xếp các tham số theo bảng chữ cái trước khi mã hóa (Hash)
function sortObject(obj) {
    let sorted = {};
    let str = [];
    let key;
    for (key in obj) {
        // Sử dụng Object.prototype.hasOwnProperty.call thay vì obj.hasOwnProperty
        if (Object.prototype.hasOwnProperty.call(obj, key)) {
            str.push(encodeURIComponent(key));
        }
    }
    str.sort();
    for (key = 0; key < str.length; key++) {
        sorted[str[key]] = encodeURIComponent(obj[str[key]]).replace(/%20/g, "+");
    }
    return sorted;
}

export default class paymentController {
    static async getPaymentHistory(req, res) {
        try {
            const userID = req.Ma_nguoi_dung;
            const result = await paymentModel.getPaymentHistory(userID);

            return res.status(200).json({
                succeeded: true,
                paymentHistory: result
            });
        } catch (error) {
            return res.status(500).json({
                succeeded: false,
                message: "Lỗi server " + error.message
            });
        }
    }

    static async createVNPayUrl(req, res) {
        try {
            const { bookingId } = req.body;

            if (!bookingId) {
                return res.status(400).json({ 
                    succeeded: false, 
                    message: "Thiếu thông tin mã lịch hẹn (bookingId)!" 
                });
            }

            // Lấy số tiền từ Database
            const rows = await paymentModel.getTotalMoney(bookingId, bookingId);

            if (!rows || rows.length === 0) {
                return res.status(404).json({ 
                    succeeded: false, 
                    message: "Không tìm thấy thông tin lịch hẹn trong hệ thống!" 
                });
            }

            const giaGocTuDB = parseFloat(rows[0].Tong_tien);

            // Quy đổi số tiền theo yêu cầu của VNPay (Nhân với 100)
            const vnpayAmount = Math.round(giaGocTuDB * 100);

            // ✅ Log số tiền sau khi lấy từ DB thành công để kiểm tra
            console.log(`=== bookingId: ${bookingId} | Giá gốc DB: ${giaGocTuDB} | Gửi VNPay: ${vnpayAmount}`);

            process.env.TZ = 'Asia/Ho_Chi_Minh';
            let date = new Date();
            let createDate = moment(date).format('YYYYMMDDHHmmss');
            
            // Lấy IP của thiết bị
            let ipAddr = req.headers['x-forwarded-for'] || 
                         req.connection.remoteAddress || 
                         req.socket.remoteAddress || 
                         req.connection.socket.remoteAddress;

            let tmnCode = process.env.VNP_TMN_CODE;
            let secretKey = process.env.VNP_HASH_SECRET;
            let vnpUrl = process.env.VNP_URL;
            let returnUrl = process.env.VNP_RETURN_URL_PHONE;
            //let returnUrl = process.env.VNP_RETURN_URL_PHONE;
            
            let orderId = bookingId || moment(date).format('DDHHmmss');

            let vnp_Params = {};
            vnp_Params['vnp_Version'] = '2.1.0';
            vnp_Params['vnp_Command'] = 'pay';
            vnp_Params['vnp_TmnCode'] = tmnCode;
            vnp_Params['vnp_Locale'] = 'vn';
            vnp_Params['vnp_CurrCode'] = 'VND';
            vnp_Params['vnp_TxnRef'] = orderId;
            vnp_Params['vnp_OrderInfo'] = 'Thanh toan lich kham ' + orderId;
            vnp_Params['vnp_OrderType'] = 'other';
            vnp_Params['vnp_ReturnUrl'] = returnUrl;
            vnp_Params['vnp_IpAddr'] = ipAddr;
            vnp_Params['vnp_CreateDate'] = createDate;
            vnp_Params['vnp_Amount'] = vnpayAmount;

            // Sắp xếp dữ liệu
            vnp_Params = sortObject(vnp_Params);

            // Tạo chữ ký bảo mật (Hash)
            let signData = qs.stringify(vnp_Params, { encode: false });
            let hmac = crypto.createHmac("sha512", secretKey);
            let signed = hmac.update(new Buffer.from(signData, 'utf-8')).digest("hex"); 
            vnp_Params['vnp_SecureHash'] = signed;
            
            vnpUrl += '?' + qs.stringify(vnp_Params, { encode: false });

            // Trả link về cho Flutter
            return res.status(200).json({
                succeeded: true,
                message: "Tạo link VNPay thành công",
                data: {
                    paymentUrl: vnpUrl
                }
            });

        } catch (error) {
            console.error("Lỗi tạo VNPay URL: ", error);
            return res.status(500).json({ succeeded: false, message: "Lỗi Server" });
        }
    }

    // 2. API Hứng kết quả trả về từ VNPay
    static async vnpayReturn(req, res) {
        try {
            let vnp_Params = req.query;
            let secureHash = vnp_Params['vnp_SecureHash'];

            // Xóa hash ra khỏi tham số để xác thực lại
            delete vnp_Params['vnp_SecureHash'];
            delete vnp_Params['vnp_SecureHashType'];

            vnp_Params = sortObject(vnp_Params);

            let secretKey = process.env.VNP_HASH_SECRET;
            let signData = qs.stringify(vnp_Params, { encode: false });
            let hmac = crypto.createHmac("sha512", secretKey);
            let signed = hmac.update(new Buffer.from(signData, 'utf-8')).digest("hex");

            if (secureHash === signed) {
                let responseCode = vnp_Params['vnp_ResponseCode'];
                let bookingId = vnp_Params['vnp_TxnRef'];
                let vnp_PayDate = vnp_Params['vnp_PayDate'];
                let vnp_TransactionNo = vnp_Params['vnp_TransactionNo'];
                let thoiDiemThanhToanChuan = moment(vnp_PayDate, 'YYYYMMDDHHmmss').format('YYYY-MM-DD HH:mm:ss');
                const rows = await paymentModel.getPayment(bookingId);

                if (responseCode === '00') {
                    await paymentModel.updateStatus(bookingId, 'paid');
                    await bookingModel.saveTransactionCode(vnp_TransactionNo, thoiDiemThanhToanChuan, rows[0].Ma_thanh_toan);
                    console.log(`Booking ${bookingId} thanh toán THÀNH CÔNG!`);
                    if (rows && rows.length > 0) {
                        const thongTinChung = rows[0]; 
                        const doiTuongDichVu = rows[1] || { Danh_sach_dich_vu: [] };
                        const danhSachDichVu = doiTuongDichVu.Danh_sach_dich_vu || [];

                        // Gộp tên các dịch vụ lại thành một chuỗi cách nhau bằng dấu phẩy (Ví dụ: "Khám tổng quát, Xét nghiệm máu")
                        const chuoiTenDichVu = danhSachDichVu.length > 0 
                            ? danhSachDichVu.map(dv => dv.Ten_dich_vu).join(', ') 
                            : "Dịch vụ khám bệnh";

                        // Tạo gói dữ liệu chuẩn hóa để truyền vào hàm gửi hóa đơn email
                        const thongTinHoaDon = {
                            maGiaoDich: vnp_TransactionNo,
                            maBooking: thongTinChung.Ma_booking,
                            tenBenhNhan: thongTinChung.Ten_benh_nhan,
                            emailNguoiDung: thongTinChung.Email,
                            tenBacSi: thongTinChung.Ten_bac_si,
                            tenDichVu: chuoiTenDichVu,
                            soTien: thongTinChung.Tong_tien,
                            tenPhongKham: thongTinChung.Ten_phong_kham,
                            viTriPhongKham: thongTinChung.Vi_tri,
                            Dien_thoai_phong_kham: thongTinChung.Dien_thoai_phong_kham,
                            Email_phong_kham: thongTinChung.Email_phong_kham
                        };

                        console.log("👉 Chuẩn bị gửi hóa đơn cho các dịch vụ:", chuoiTenDichVu);

                        // Chạy ngầm việc gửi email hóa đơn PDF
                        taoVaGuiHoaDonPDF(thongTinHoaDon).catch(err => console.error("Lỗi gửi email ngầm:", err));
                    }
                    return res.status(200).send("Thanh toán thành công. Vui lòng quay lại ứng dụng.");
                } else {
                    // 🌟 NẾU THANH TOÁN VNPay THẤT BẠI HOẶC BỊ HỦY
                    await paymentModel.updateStatus(bookingId, 'failed');
                    
                    const { execute } = await import('../config/db.js');
                    // Kiểm tra xem lịch này là Online hay Offline (Lấy thêm Ma_lich_hen để ghi log)
                    const [lhRows] = await execute(`SELECT Ma_lich_hen, Ma_khung_gio, Hinh_thuc FROM lich_hen WHERE Ma_booking = ?`, [bookingId]);

                    if (lhRows.length > 0 && lhRows[0].Hinh_thuc === 'online') {
                        const maLichHen = lhRows[0].Ma_lich_hen;
                        const maKhungGio = lhRows[0].Ma_khung_gio;

                        // ❌ NẾU ONLINE: Hủy lịch
                        await execute(`UPDATE lich_hen SET Trang_thai_lich_hen = 'cancelled' WHERE Ma_booking = ?`, [bookingId]);
                        
                        // Ghi log hệ thống tự hủy
                        await execute(
                            `INSERT INTO lich_su_trang_thai_lich_hen (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Ly_do_thay_doi, Nguoi_thay_doi) 
                             VALUES (?, 'pending', 'cancelled', 'Hệ thống tự động hủy do giao dịch VNPay thất bại/quá hạn', 'system')`,
                            [maLichHen]
                        );

                        // Nhả Slot ngay lập tức
                        await execute(`UPDATE khung_gio_kham SET Trang_thai = 'available' WHERE Ma_khung_gio = ?`, [maKhungGio]);
                        console.log(`[VNPay] Đã tự động HỦY lịch ${bookingId} (Online) do không thanh toán.`);
                    } else {
                        // ✅ NẾU OFFLINE: Giữ nguyên lịch hẹn, bệnh nhân tới phòng khám trả tiền mặt sau
                        console.log(`[VNPay] Giữ nguyên lịch ${bookingId} (Offline) dù VNPay thất bại.`);
                    }
                    
                    return res.status(200).send("Thanh toán thất bại hoặc đã bị hủy.");
                }
            } else {
                return res.status(400).send("Chữ ký bảo mật không hợp lệ (Sai Checksum)!");
            }
        } catch (error) {
            console.error("Lỗi VNPay Return: ", error);
            return res.status(500).send("Lỗi xử lý giao dịch.");
        }
    }

    static async getAllPayment(req,res){
        try{
            const rows = await paymentModel.getAllPayment();

            return res.status(200).json({
                succeeded: true,
                payments: rows
            });
        }catch(error){
            return res.status(500).json({
                succeeded: false,
                message: error.message
            });
        }
    }

    static async updatePaymentStatusForAdmin(req, res) {
        try {
            const { id } = req.params;
            const { status, userId, reason } = req.body;
            const adminId = req.adminId;
            
            if(!id || !status || !userId || !reason) return res.status(400).json({
                success: false,
                message: "Thiếu thông tin cần thiết."
            });

            const success = await paymentModel.updatePaymentStatusForAdmin(id, status, adminId, userId, reason);
            if (success) {
                return res.status(200).json({ succeeded: true, message: "Cập nhật trạng thái thành công!" });
            }
            return res.status(400).json({ succeeded: false, message: "Không tìm thấy giao dịch hoặc cập nhật thất bại." });
        } catch (error) {
            console.error("Lỗi updatePaymentStatus:", error);
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    static async checkPaymentStatus(req, res) {
    try {
        const { bookingId } = req.params;
        // Giả sử paymentModel có hàm lấy thông tin giao dịch theo bookingId
        const rows = await paymentModel.checkPaymentStatus(bookingId); 
        
        if (rows && rows.length > 0) {
            // Trả về trạng thái hiện tại (pending, paid, failed...)
            return res.status(200).json({ succeeded: true, status: rows[0].Trang_thai_thanh_toan }); 
        }
        return res.status(404).json({ succeeded: false, message: "Không tìm thấy" });
    } catch (error) {
        return res.status(500).json({ succeeded: false, message: error.message });
    }
}
}