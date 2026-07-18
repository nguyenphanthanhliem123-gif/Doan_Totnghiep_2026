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
            const { bookingId } = req.body; // Nhận chuỗi dạng "BK01-BK02-BK03"

            if (!bookingId) {
                return res.status(400).json({ 
                    succeeded: false, 
                    message: "Thiếu thông tin mã lịch hẹn (bookingId)!" 
                });
            }

            // Cắt chuỗi gộp thành mảng các mã đơn lẻ
            const bookingCodes = bookingId.split('-');
            let giaGocTuDB = 0;
            let foundAny = false;

            // 🔄 Vòng lặp tính tổng tiền của tất cả các mã lịch hẹn
            for (const code of bookingCodes) {
                const rows = await paymentModel.getTotalMoney(code, code);
                if (rows && rows.length > 0) {
                    giaGocTuDB += parseFloat(rows[0].Tong_tien);
                    foundAny = true;
                }
            }

            if (!foundAny) {
                return res.status(404).json({ 
                    succeeded: false, 
                    message: "Không tìm thấy thông tin lịch hẹn trong hệ thống!" 
                });
            }

            // Quy đổi số tiền theo yêu cầu của VNPay (Nhân với 100)
            const vnpayAmount = Math.round(giaGocTuDB * 100);

            // ✅ Log số tiền sau khi tổng hợp thành công để kiểm tra
            console.log(`=== Chuỗi Booking: ${bookingId} | Tổng giá gốc các slot: ${giaGocTuDB} | Gửi VNPay: ${vnpayAmount}`);

            process.env.TZ = 'Asia/Ho_Chi_Minh';
            let date = new Date();
            let createDate = moment(date).format('YYYYMMDDHHmmss');
            let expireDate = moment(date).add(15, 'minutes').format('YYYYMMDDHHmmss');
            
            let ipAddr = req.headers['x-forwarded-for'] || 
                         req.connection.remoteAddress || 
                         req.socket.remoteAddress || 
                         req.connection.socket.remoteAddress;

            let tmnCode = process.env.VNP_TMN_CODE;
            let secretKey = process.env.VNP_HASH_SECRET;
            let vnpUrl = process.env.VNP_URL;
            let returnUrl = process.env.VNP_RETURN_URL_PHONE;
            
            // vnp_TxnRef gửi sang VNPay chính là chuỗi gộp để lúc nhận về ta giải nén
            let orderId = bookingId; 

            let vnp_Params = {};
            vnp_Params['vnp_Version'] = '2.1.0';
            vnp_Params['vnp_Command'] = 'pay';
            vnp_Params['vnp_TmnCode'] = tmnCode;
            vnp_Params['vnp_Locale'] = 'vn';
            vnp_Params['vnp_CurrCode'] = 'VND';
            vnp_Params['vnp_TxnRef'] = orderId;
            vnp_Params['vnp_OrderInfo'] = 'Thanh toan chuoi lich kham ' + orderId;
            vnp_Params['vnp_OrderType'] = 'other';
            vnp_Params['vnp_ReturnUrl'] = returnUrl;
            vnp_Params['vnp_IpAddr'] = ipAddr;
            vnp_Params['vnp_CreateDate'] = createDate;
            vnp_Params['vnp_Amount'] = vnpayAmount;
            vnp_Params['vnp_ExpireDate'] = expireDate;

            vnp_Params = sortObject(vnp_Params);

            let signData = qs.stringify(vnp_Params, { encode: false });
            let hmac = crypto.createHmac("sha512", secretKey);
            let signed = hmac.update(new Buffer.from(signData, 'utf-8')).digest("hex"); 
            vnp_Params['vnp_SecureHash'] = signed;
            
            vnpUrl += '?' + qs.stringify(vnp_Params, { encode: false });

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

            delete vnp_Params['vnp_SecureHash'];
            delete vnp_Params['vnp_SecureHashType'];

            vnp_Params = sortObject(vnp_Params);

            let secretKey = process.env.VNP_HASH_SECRET;
            let signData = qs.stringify(vnp_Params, { encode: false });
            let hmac = crypto.createHmac("sha512", secretKey);
            let signed = hmac.update(new Buffer.from(signData, 'utf-8')).digest("hex");

            if (secureHash === signed) {
                let responseCode = vnp_Params['vnp_ResponseCode'];
                let combinedBookingId = vnp_Params['vnp_TxnRef']; // Nhận lại chuỗi gộp "BK01-BK02"
                let vnp_PayDate = vnp_Params['vnp_PayDate'];
                let vnp_TransactionNo = vnp_Params['vnp_TransactionNo'];
                let thoiDiemThanhToanChuan = moment(vnp_PayDate, 'YYYYMMDDHHmmss').format('YYYY-MM-DD HH:mm:ss');
                
                // Giải nén chuỗi gộp thành mảng các mã đơn lẻ để xử lý
                const bookingCodes = combinedBookingId.split('-');

                if (responseCode === '00') {
                    // 📦 Khởi tạo các biến gom thông tin để gửi 1 email duy nhất
                    let danhSachThongTinGop = [];
                    let tongTienChuoi = 0;
                    let tapHopTenDichVu = new Set(); // Dùng Set để tránh trùng lặp tên dịch vụ

                    // 🔄 VÒNG LẶP XỬ LÝ DATABASE CHO TỪNG MÃ BOOKING
                    for (let i = 0; i < bookingCodes.length; i++) {
                        const code = bookingCodes[i].trim();
                        const rows = await paymentModel.getPayment(code);
                        
                        // Cập nhật trạng thái hóa đơn sang 'paid' cho từng mã
                        await paymentModel.updateStatus(code, 'paid');
                        
                        if (rows && rows.length > 0) {
                            // 🛠️ SỬA LỖI DUPLICATE ENTRY: Nếu chuỗi thanh toán gộp có nhiều hơn 1 mã, 
                            // ta thêm hậu tố _1, _2... vào sau mã giao dịch để né trùng Unique Key trong DB.
                            const maGiaoDichLuuDB = bookingCodes.length > 1 
                                ? `${vnp_TransactionNo}_${i + 1}` 
                                : vnp_TransactionNo;

                            // Lưu mã giao dịch (đã xử lý né trùng) vào bản ghi thanh toán tương ứng
                            await bookingModel.saveTransactionCode(maGiaoDichLuuDB, thoiDiemThanhToanChuan, rows[0].Ma_thanh_toan);
                            
                            const thongTinChung = rows[0]; 
                            const doiTuongDichVu = rows[1] || { Danh_sach_dich_vu: [] };
                            const danhSachDichVu = doiTuongDichVu.Danh_sach_dich_vu || [];

                            // Cộng dồn tiền và gom dịch vụ
                            tongTienChuoi += parseFloat(thongTinChung.Tong_tien);
                            danhSachDichVu.forEach(dv => tapHopTenDichVu.add(dv.Ten_dich_vu));

                            // Lưu lại object thông tin chung để lát lấy thông tin Email, Tên bệnh nhân...
                            danhSachThongTinGop.push(thongTinChung);
                        }
                        console.log(`Booking ${code} đã cập nhật DB thành công!`);
                    }

                    // 📬 TIẾN HÀNH GỘP HÓA ĐƠN VÀ GỬI 1 EMAIL DUY NHẤT SAU KHI VÒNG LẶP KẾT THÚC
                    if (danhSachThongTinGop.length > 0) {
                        const thongTinMau = danhSachThongTinGop[0]; // Lấy thông tin cơ bản của user (Email, tên giống nhau)
                        const chuoiMaBookingGop = bookingCodes.join(' - '); // Gộp thành: "BK20260718_7642 - BK20260718_4867"
                        const chuoiTenDichVuGop = tapHopTenDichVu.size > 0 
                            ? Array.from(tapHopTenDichVu).join(', ') 
                            : "Dịch vụ khám bệnh";

                        const thongTinHoaDonTong = {
                            maGiaoDich: vnp_TransactionNo, // Trên hóa đơn hiển thị mã gốc VNPay
                            maBooking: chuoiMaBookingGop,  // Hiển thị toàn bộ các mã booking đã gộp
                            tenBenhNhan: thongTinMau.Ten_benh_nhan,
                            emailNguoiDung: thongTinMau.Email,
                            tenBacSi: thongTinMau.Ten_bac_si,
                            tenDichVu: chuoiTenDichVuGop,
                            soTien: tongTienChuoi, // Tổng chi phí của tất cả các slot khám cộng lại
                            tenPhongKham: thongTinMau.Ten_phong_kham,
                            viTriPhongKham: thongTinMau.Vi_tri,
                            Dien_thoai_phong_kham: thongTinMau.Dien_thoai_phong_kham,
                            Email_phong_kham: thongTinMau.Email_phong_kham
                        };

                        console.log(`👉 Đang tiến hành tạo và gửi 1 EMAIL HÓA ĐƠN TỔNG cho chuỗi: ${chuoiMaBookingGop}`);
                        taoVaGuiHoaDonPDF(thongTinHoaDonTong).catch(err => console.error("Lỗi gửi email gộp ngầm:", err));
                    }

                    return res.status(200).send("Thanh toán thành công. Vui lòng quay lại ứng dụng.");
                } else {
                    // ❌ XỬ LÝ KHI THANH TOÁN THẤT BẠI HOẶC BỊ HỦY (Giữ nguyên logic cũ của bạn)
                    const { execute } = await import('../config/db.js');
                    
                    for (const code of bookingCodes) {
                        await paymentModel.updateStatus(code.trim(), 'failed');
                        const [lhRows] = await execute(`SELECT Ma_lich_hen, Ma_khung_gio, Hinh_thuc FROM lich_hen WHERE Ma_booking = ?`, [code.trim()]);

                        if (lhRows.length > 0 && lhRows[0].Hinh_thuc === 'online') {
                            const maLichHen = lhRows[0].Ma_lich_hen;
                            const maKhungGio = lhRows[0].Ma_khung_gio;

                            await execute(`UPDATE lich_hen SET Trang_thai_lich_hen = 'cancelled' WHERE Ma_booking = ?`, [code.trim()]);
                            await execute(
                                `INSERT INTO lich_su_trang_thai_lich_hen (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Ly_do_thay_doi, Nguoi_thay_doi) 
                                VALUES (?, 'pending', 'cancelled', 'Hệ thống tự động hủy do giao dịch VNPay thất bại/quá hạn', 'system')`,
                                [maLichHen]
                            );
                            await execute(`UPDATE khung_gio_kham SET Trang_thai = 'available' WHERE Ma_khung_gio = ?`, [maKhungGio]);
                        }
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