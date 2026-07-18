import bookingModel from '../models/bookingModel.js';
import { beginTransaction, commitTransaction, rollbackTransaction } from "../config/db.js";

export default class bookingController {
    static async getAvailableDates(req, res) {
        try {
            const { doctorId } = req.params;
            if (!doctorId) return res.status(400).json({ succeeded: false, message: "Thiếu mã bác sĩ" });

            const dates = await bookingModel.getAvailableDates(doctorId);
            return res.status(200).json({ succeeded: true, data: dates });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    static async getTodayCount(req, res) {
        try {
            const Ma_nguoi_dung = req.Ma_nguoi_dung; // Lấy từ Token bảo mật
            const todayStr = new Date().toISOString().slice(0, 10);
            const { execute } = await import('../config/db.js');
            
            const [spamRows] = await execute(
                `SELECT COUNT(*) as total 
                FROM lich_hen lh
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                WHERE bn.Ma_nguoi_dung = ? 
                AND DATE(lh.Ngay_tao) = ? 
                AND lh.Trang_thai_lich_hen IN ('pending', 'confirmed')`,
                [Ma_nguoi_dung, todayStr]
            );
            return res.status(200).json({ succeeded: true, total: spamRows[0].total });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    static async createBooking(req, res) {
        let conn = await beginTransaction();
        try {
            const Ma_nguoi_dung = req.Ma_nguoi_dung; // Lấy từ Token bảo mật
            const { Ma_bac_si, Ma_benh_nhan, Ma_nguoi_than, Ma_dich_vu, Ma_khung_gio, Hinh_thuc, Trieu_chung } = req.body;

            // Chuyển đổi linh hoạt: Hỗ trợ cả 1 ID đơn lẻ hoặc một mảng chứa nhiều ID khung giờ gửi lên
            const slotIds = Array.isArray(Ma_khung_gio) ? Ma_khung_gio : [Ma_khung_gio];
            if (slotIds.length === 0) {
                await rollbackTransaction(conn);
                return res.status(400).json({ succeeded: false, message: "Vui lòng chọn ít nhất 1 khung giờ!" });
            }

            // 1. Kiểm tra mảng dịch vụ
            if (!Array.isArray(Ma_dich_vu) || Ma_dich_vu.length === 0) {
                await rollbackTransaction(conn);
                return res.status(400).json({ succeeded: false, message: "Vui lòng chọn ít nhất 1 dịch vụ!" });
            }

            // Kiểm tra xem mã người thân gửi lên có thực sự thuộc về user này không
            const maBenhNhanThat = await bookingModel.checkPatienID(Ma_benh_nhan, Ma_nguoi_than, conn);
            if (!maBenhNhanThat) {
                await rollbackTransaction(conn);
                return res.status(400).json({ 
                    succeeded: false, 
                    message: "Hồ sơ bệnh nhân không hợp lệ hoặc bạn đang cố truy cập trái phép hồ sơ người khác!" 
                });
            }

            // 2. Kiểm tra số điện thoại (Chặn tài khoản clone hoặc tài khoản chưa cập nhật thông tin)
            const [userInfo] = await conn.execute(`SELECT Dien_thoai FROM nguoi_dung WHERE Ma_nguoi_dung = ?`, [Ma_nguoi_dung]);
            if (!userInfo || userInfo.length === 0 || !userInfo[0].Dien_thoai || userInfo[0].Dien_thoai.trim() === '') {
                await rollbackTransaction(conn);
                return res.status(400).json({ succeeded: false, message: "Vui lòng cập nhật số điện thoại trước khi đặt lịch!" });
            }

            // 5. Chặn Spam lịch (Tối đa 5 lịch/ngày TRÊN TOÀN TÀI KHOẢN - Có cộng gộp các slot chuẩn bị đặt)
            const todayStr = new Date().toISOString().slice(0, 10);
            const [spamRows] = await conn.execute(
                `SELECT COUNT(*) as total 
                FROM lich_hen lh
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                WHERE bn.Ma_nguoi_dung = ? 
                AND DATE(lh.Ngay_tao) = ? 
                AND lh.Trang_thai_lich_hen IN ('pending', 'confirmed')`,
                [Ma_nguoi_dung, todayStr]
            );
            
            if (spamRows[0].total + slotIds.length > 5) {
                await rollbackTransaction(conn);
                return res.status(400).json({ 
                    succeeded: false, 
                    message: `Tài khoản của bạn đã đặt ${spamRows[0].total}/5 lịch hôm nay. Chọn thêm ${slotIds.length} khung giờ nữa sẽ vượt quá giới hạn tối đa cho phép!` 
                });
            }

            // 6. Tính toán chi phí cơ sở dựa trên dịch vụ (Áp dụng đồng đều cho mỗi slot)
            let Tong_tien_mot_slot = 0;
            const thongTinDichVu = [];
            for (const idDichVu of Ma_dich_vu) {
                const service = await bookingModel.getServicePrice(idDichVu, conn);
                if (service) {
                    Tong_tien_mot_slot += parseFloat(service.Gia_tien);
                    thongTinDichVu.push({ id: idDichVu, price: service.Gia_tien });
                }
            }

            if (thongTinDichVu.length === 0) {
                await rollbackTransaction(conn);
                return res.status(404).json({ succeeded: false, message: "Dịch vụ không hợp lệ." });
            }

            // Chuẩn hóa dữ liệu phương thức thanh toán trước khi vào vòng lặp
            let rawMethod = req.body.Phuong_thuc || req.body.paymentMethod || 'cash';
            let Phuong_thuc = rawMethod.toString().trim().toLowerCase();
            if (!['momo', 'cash', 'transfer', 'vnpay'].includes(Phuong_thuc)) Phuong_thuc = 'vnpay'; 

            const bookedAppointments = [];

            // 🔄 VÒNG LẶP TUẦN TỰ KIỂM TRA & LƯU TỪNG SLOT ĐÃ CHỌN TRONG TRANSACTION
            for (const idKhungGio of slotIds) {
                
                // 3. Cơ chế khóa hàng chặn Race Condition bằng Pessimistic Locking
                const slot = await bookingModel.getSlotForUpdate(idKhungGio, conn);
                
                if (!slot) {
                    await rollbackTransaction(conn);
                    return res.status(404).json({ succeeded: false, requiresReload: true, message: "Không tìm thấy một trong các khung giờ được chọn." });
                }

                if (slot.Trang_thai !== 'available') {
                    await rollbackTransaction(conn);
                    return res.status(400).json({ 
                        succeeded: false, 
                        requiresReload: true, // Gửi cờ hiệu ép Flutter gọi hàm _reloadSlots() ngay lập tức
                        message: "Một trong các khung giờ bạn chọn vừa có người nhanh tay đặt trước mất rồi! Vui lòng làm mới trang." 
                    });
                }

                // Chặn đặt lịch cho thời gian ở quá khứ
                const slotTime = new Date(slot.Thoi_gian_Bdau);
                const now = new Date();
                if (slotTime < now) {
                    await rollbackTransaction(conn);
                    return res.status(400).json({ succeeded: false, message: "Không thể đặt lịch cho khung giờ đã trôi qua trong quá khứ." });
                }

                // Chặn đặt lịch nếu Trạng thái hoạt động của Bác sĩ không phải là 'active'
                if (slot.Trang_thai_hoat_dong !== 'active') {
                    await rollbackTransaction(conn);
                    return res.status(400).json({ succeeded: false, message: "Bác sĩ tại khung giờ bạn chọn hiện đang tạm ngưng tiếp nhận bệnh nhân." });
                }

                // Kiểm tra trùng lặp lịch hẹn thực tế trong bảng lịch hẹn
                const rows = await bookingModel.getSlotReal(idKhungGio, conn);
                if (rows[0].count > 0) {
                    await rollbackTransaction(conn);
                    return res.status(400).json({ succeeded: false, requiresReload: true, message: "Hệ thống ghi nhận khung giờ này đã có lịch đặt trước!" });
                }

                // 4. Kiểm tra trùng lịch cá nhân (Chống giao thoa giờ của cùng một bệnh nhân)
                const isConflict = await bookingModel.checkPatientConflict(maBenhNhanThat, Ma_nguoi_than, idKhungGio, conn);
                if (isConflict) {
                    await rollbackTransaction(conn); 
                    return res.status(400).json({ succeeded: false, message: "Rất tiếc, người khám này đã có một lịch hẹn khác trùng hoặc giao thoa với thời gian này!" });
                }

                // 7. Xử lý sinh mã Booking độc nhất cho từng Slot cụ thể
                const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
                const randomNum = Math.floor(1000 + Math.random() * 9000);
                const Ma_booking = `BK${dateStr}_${randomNum}`;
                
                let Ma_giao_dich = Phuong_thuc === 'cash' ? `TXN_${Ma_booking}` : null;

                // 8. Lưu dữ liệu tuần tự vào các bảng liên kết
                const bookingData = { 
                    Ma_booking, Ma_bac_si, Ma_benh_nhan: maBenhNhanThat, 
                    Ma_nguoi_than, Ma_khung_gio: idKhungGio, Hinh_thuc, Trieu_chung, Tong_tien: Tong_tien_mot_slot 
                };
                const insertId = await bookingModel.createAppointment(bookingData, conn);

                // Thêm chi tiết dịch vụ cho từng cuộc hẹn
                for (const item of thongTinDichVu) {
                    await bookingModel.createAppointmentDetail({
                        Ma_lich_hen: insertId,
                        Ma_dich_vu: item.id,
                        Gia_tien: item.price
                    }, conn);
                }

                // Tạo bản ghi thanh toán tương ứng cho cuộc hẹn
                const paymentData = { Ma_lich_hen: insertId, Phuong_thuc, Trang_thai_thanh_toan: 'pending', Ma_giao_dich, Tong_tien: Tong_tien_mot_slot };
                await bookingModel.createPayment(paymentData, conn);
                
                // Cập nhật trạng thái slot sang 'booked'
                await bookingModel.updateSlotStatus(idKhungGio, 'booked', conn);

                // Đẩy thông tin vào mảng phản hồi
                bookedAppointments.push({
                    Ma_lich_hen: insertId,
                    Ma_booking,
                    Ma_khung_gio: idKhungGio
                });
            }
        
            await commitTransaction(conn);

            return res.status(200).json({
                succeeded: true, 
                message: "Đặt chuỗi lịch khám thành công!",
                data: bookedAppointments,
                combinedBookingCode: bookedAppointments.map(item => item.Ma_booking).join('-'),
                totalPrice: Tong_tien_mot_slot * slotIds.length,
                Phuong_thuc
            });

        } catch (error) {
            await rollbackTransaction(conn);
            return res.status(500).json({ succeeded: false, message: "Lỗi hệ thống trong tiến trình đặt lịch: " + error.message });
        }
    }

    static async getDoctorSchedule(req, res) {
        try {
            // Hứng tham số ngày và ID bác sĩ từ URL
            const date = req.query.date || req.query.q || '';
            const doctorId = req.query.doctorId; 

            // Kiểm tra rỗng
            if (!doctorId || doctorId === 'null') {
                return res.status(400).json({ succeeded: false, message: "Thiếu mã bác sĩ để xem lịch." });
            }

            const doctorSchedule = await bookingModel.getDoctorSchedule(doctorId, date);
            
            return res.status(200).json({ succeeded: true, schedule: doctorSchedule });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // Hàm Hủy lịch tự động
    static async cancelUnpaidBooking(req, res) {
        try {
            const { bookingCode } = req.body;
            const { execute } = await import('../config/db.js');
            
            const [rows] = await execute(`SELECT Ma_lich_hen, Ma_khung_gio FROM lich_hen WHERE Ma_booking = ?`, [bookingCode]);
            if (rows.length > 0) {
                const maLichHen = rows[0].Ma_lich_hen;
                const maKhungGio = rows[0].Ma_khung_gio;

                await execute(`UPDATE lich_hen SET Trang_thai_lich_hen = 'cancelled' WHERE Ma_booking = ?`, [bookingCode]);
                await execute(
                    `INSERT INTO lich_su_trang_thai_lich_hen (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Ly_do_thay_doi, Nguoi_thay_doi) 
                     VALUES (?, 'pending', 'cancelled', 'Khách hàng hủy thanh toán trực tuyến hoặc chủ động hủy tiến trình đợi', 'patient')`,
                    [maLichHen]
                );
                await execute(`UPDATE khung_gio_kham SET Trang_thai = 'available' WHERE Ma_khung_gio = ?`, [maKhungGio]);
                await execute(`UPDATE thanh_toan SET Trang_thai_thanh_toan = 'failed' WHERE Ma_lich_hen = ?`, [maLichHen]);
            }
            return res.status(200).json({ succeeded: true, message: "Đã hủy lịch chưa thanh toán và nhả slot." });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // 💡 HÀM MỚI 1: Xử lý hủy chuỗi đặt lịch gộp (Ví dụ: BK01-BK02)
    static async cancelCombinedUnpaidBooking(req, res) {
        try {
            const { bookingCode } = req.body;
            if (!bookingCode) return res.status(400).json({ succeeded: false, message: "Thiếu mã booking" });

            const codes = bookingCode.split('-'); // Tách chuỗi gộp thành mảng các mã riêng lẻ
            const { execute } = await import('../config/db.js');
            
            for (const code of codes) {
                const [rows] = await execute(`SELECT Ma_lich_hen, Ma_khung_gio FROM lich_hen WHERE Ma_booking = ?`, [code.trim()]);
                if (rows.length > 0) {
                    const maLichHen = rows[0].Ma_lich_hen;
                    const maKhungGio = rows[0].Ma_khung_gio;

                    await execute(`UPDATE lich_hen SET Trang_thai_lich_hen = 'cancelled' WHERE Ma_booking = ?`, [code.trim()]);
                    await execute(
                        `INSERT INTO lich_su_trang_thai_lich_hen (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Ly_do_thay_doi, Nguoi_thay_doi) 
                         VALUES (?, 'pending', 'cancelled', 'Hủy chuỗi thanh toán trực tuyến hoặc chủ động hủy tiến trình đợi', 'patient')`,
                        [maLichHen]
                    );
                    await execute(`UPDATE khung_gio_kham SET Trang_thai = 'available' WHERE Ma_khung_gio = ?`, [maKhungGio]);
                    await execute(`UPDATE thanh_toan SET Trang_thai_thanh_toan = 'failed' WHERE Ma_lich_hen = ?`, [maLichHen]);
                }
            }
            return res.status(200).json({ succeeded: true, message: "Đã giải phóng chuỗi khung giờ thành công." });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // 💡 HÀM MỚI 2: Quét trạng thái thanh toán tự động (Polling API) cho chuỗi đặt lịch gộp
    static async checkCombinedPaymentStatus(req, res) {
        try {
            const { bookingCode } = req.params;
            if (!bookingCode) return res.status(400).json({ succeeded: false, message: "Thiếu mã kiểm tra" });

            const codes = bookingCode.split('-');
            const { execute } = await import('../config/db.js');

            let paidCount = 0;
            let failedCount = 0;

            for (const code of codes) {
                const [rows] = await execute(
                    `SELECT tt.Trang_thai_thanh_toan 
                     FROM thanh_toan tt 
                     JOIN lich_hen lh ON tt.Ma_lich_hen = lh.Ma_lich_hen 
                     WHERE lh.Ma_booking = ?`, 
                    [code.trim()]
                );
                
                if (rows.length > 0) {
                    const status = rows[0].Trang_thai_thanh_toan;
                    if (status === 'paid') paidCount++;
                    if (status === 'failed' || status === 'cancelled') failedCount++;
                }
            }

            // Trả về trạng thái tổng hợp dựa trên toàn bộ các slot trong chuỗi
            if (paidCount === codes.length) {
                return res.status(200).json({ succeeded: true, status: 'paid' });
            } else if (failedCount > 0) {
                return res.status(200).json({ succeeded: true, status: 'failed' });
            }
            
            return res.status(200).json({ succeeded: true, status: 'pending' });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }
}