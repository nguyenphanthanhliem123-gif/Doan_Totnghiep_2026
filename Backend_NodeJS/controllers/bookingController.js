import bookingModel from '../models/bookingModel.js';

export default class bookingController {
    // Lấy danh sách các ngày còn slot trống
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

    // Tạo lịch hẹn mới (Hỗ trợ nhiều dịch vụ)
    static async createBooking(req, res) {
        try {
            const { Ma_bac_si, Ma_benh_nhan, Ma_nguoi_than, Ma_dich_vu, Ma_khung_gio, Hinh_thuc, Trieu_chung, Phuong_thuc, paymentMethod } = req.body;

            // 1. Kiểm tra đầu vào (Mảng dịch vụ)
            if (!Array.isArray(Ma_dich_vu) || Ma_dich_vu.length === 0) {
                return res.status(400).json({ succeeded: false, message: "Vui lòng chọn ít nhất 1 dịch vụ!" });
            }

            // 2. Kiểm tra hồ sơ bệnh nhân
            const maBenhNhanThat = await bookingModel.getPatientIdByUserId(Ma_benh_nhan);
            if (!maBenhNhanThat) return res.status(400).json({ succeeded: false, message: "Chưa có hồ sơ bệnh nhân!" });

            // 3. Kiểm tra số điện thoại
            const { execute } = await import('../config/db.js'); 
            const [userInfo] = await execute(`SELECT Dien_thoai FROM nguoi_dung WHERE Ma_nguoi_dung = ?`, [Ma_benh_nhan]);
            
            if (!userInfo || userInfo.length === 0 || !userInfo[0].Dien_thoai || userInfo[0].Dien_thoai.trim() === '') {
                return res.status(400).json({ 
                    succeeded: false, 
                    message: "Vui lòng cập nhật số điện thoại trong phần Hồ sơ trước khi đặt lịch!" 
                });
            }

            // 4. Kiểm tra trùng lịch cá nhân (Conflict check)
            const isConflict = await bookingModel.checkPatientConflict(maBenhNhanThat, Ma_khung_gio);
            if (isConflict) {
                return res.status(400).json({ succeeded: false, message: "Bạn đã có một lịch hẹn khác trùng khung giờ này!" });
            }

            // 5. Logic tiền tệ
            let Tong_tien = 0;
            const thongTinDichVu = [];
            for (const idDichVu of Ma_dich_vu) {
                const service = await bookingModel.getServicePrice(idDichVu);
                if (service) {
                    Tong_tien += parseFloat(service.Gia_tien);
                    thongTinDichVu.push({ id: idDichVu, price: service.Gia_tien });
                }
            }
            if (thongTinDichVu.length === 0) return res.status(404).json({ succeeded: false, message: "Dịch vụ không hợp lệ." });

            // 6. Xử lý thanh toán & Booking code
            const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
            const randomNum = Math.floor(1000 + Math.random() * 9000);
            const Ma_booking = `BK${dateStr}_${randomNum}`;
            const finalMethod = (Phuong_thuc || paymentMethod || 'cash').trim().toLowerCase();
            const Ma_giao_dich = finalMethod === 'cash' ? `TXN_${Ma_booking}` : null;

            // 7. GỌI HÀM TRANSACTION DUY NHẤT (Đã tích hợp kiểm tra slot FOR UPDATE trong model)
            const result = await bookingModel.createBookingTransaction(
                { Ma_booking, Ma_bac_si, Ma_benh_nhan: maBenhNhanThat, Ma_nguoi_than, Ma_khung_gio, Hinh_thuc, Trieu_chung, Tong_tien },
                thongTinDichVu,
                { Phuong_thuc: finalMethod, Trang_thai_thanh_toan: 'pending', Ma_giao_dich, Tong_tien }
            );

            return res.status(200).json({
                succeeded: true, 
                message: "Đặt lịch khám thành công!",
                data: { Ma_lich_hen: result.maLichHen, Ma_booking: result.maBooking, Tong_tien, Phuong_thuc: finalMethod, Ma_khung_gio }
            });

        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }

    // API lấy lịch làm việc của bác sĩ theo ngày
    static async getDoctorSchedule(req,res){
        try{
            const date = req.query.q || '';
            const doctorSchedule = await bookingModel.getDoctorSchedule(date);
            return  res.status(200).json({
                succeeded: true,
                schedule: doctorSchedule
            });
        }
        catch(error){
            return res.status(500).json({
                succeeded: false,
                message: error.message
            });
        }
    }

    // Hàm Hủy lịch tự động
    static async cancelUnpaidBooking(req, res) {
        try {
            const { bookingCode } = req.body;
            const { execute } = await import('../config/db.js');
            
            // 1. Tìm xem lịch này đang giữ khung giờ nào và lấy Ma_lich_hen
            const [rows] = await execute(`SELECT Ma_lich_hen, Ma_khung_gio FROM lich_hen WHERE Ma_booking = ?`, [bookingCode]);
            
            if (rows.length > 0) {
                const maLichHen = rows[0].Ma_lich_hen;
                const maKhungGio = rows[0].Ma_khung_gio;

                // 2. Hủy lịch hẹn
                await execute(`UPDATE lich_hen SET Trang_thai_lich_hen = 'cancelled' WHERE Ma_booking = ?`, [bookingCode]);
                
                // 3. Ghi log vào bảng lich_su_trang_thai_lich_hen
                await execute(
                    `INSERT INTO lich_su_trang_thai_lich_hen (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Ly_do_thay_doi, Nguoi_thay_doi) 
                     VALUES (?, 'pending', 'cancelled', 'Khách hàng hủy thanh toán trực tuyến', 'patient')`,
                    [maLichHen]
                );

                // 4. Nhả khung giờ đó về trạng thái available
                await execute(`UPDATE khung_gio_kham SET Trang_thai = 'available' WHERE Ma_khung_gio = ?`, [maKhungGio]);
                
                // 5. Đánh dấu thanh toán thất bại
                await execute(`UPDATE thanh_toan SET Trang_thai_thanh_toan = 'failed' WHERE Ma_lich_hen = ?`, [maLichHen]);
            }
            return res.status(200).json({ succeeded: true, message: "Đã hủy lịch chưa thanh toán và nhả slot." });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }
}