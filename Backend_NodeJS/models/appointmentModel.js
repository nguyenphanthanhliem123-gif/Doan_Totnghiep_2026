import { execute } from "../config/db.js";

export default class appointmentModel {

    // Lấy danh sách lịch hẹn của bệnh nhân dựa trên userID
    static async getPatientAppointments(userID) {
        try {
            // Quét và hủy các ca 'pending' quá hạn trước khi query
            const cleanupSql = `
                UPDATE lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                SET lh.Trang_thai_lich_hen = 'cancelled'
                WHERE lh.Trang_thai_lich_hen = 'pending' AND kg.Thoi_gian_Bdau < NOW()
            `;
            await execute(cleanupSql);

            // Lấy danh sách lịch hẹn của bệnh nhân dựa trên userID
            const sql = `
                SELECT 
                    lh.Ma_lich_hen,
                    lh.Ma_booking,
                    lh.Ma_bac_si,
                    lh.Trang_thai_lich_hen,
                    lh.Hinh_thuc,
                    kg.Thoi_gian_Bdau,
                    kg.Thoi_gian_Kthuc,
                    nd.Ten_nguoi_dung AS Ten_bac_si,
                    nd.Anh_dai_dien AS Anh_bac_si
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                JOIN bac_si bs ON lh.Ma_bac_si = bs.Ma_bac_si
                JOIN nguoi_dung nd ON bs.Ma_nguoi_dung = nd.Ma_nguoi_dung
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                WHERE bn.Ma_nguoi_dung = ?
                ORDER BY kg.Thoi_gian_Bdau DESC
            `;
            
            const [appointments] = await execute(sql, [userID]);
            return appointments;
        } catch (error) {
            throw new Error('Lỗi truy vấn lịch hẹn: ' + error.message);
        }
    }

    // Lấy chi tiết lịch hẹn dựa trên Ma_lich_hen
    static async getAppointmentDetails(appointmentID) {
        try {
            const sql = `
                SELECT 
                    lh.Ma_lich_hen,
                    lh.Ma_booking,
                    lh.Ma_bac_si,
                    lh.Hinh_thuc,
                    lh.Trang_thai_lich_hen,
                    lh.Trieu_chung AS Ghi_chu,
                    lh.Link_video_call,
                    kg.Thoi_gian_Bdau,
                    kg.Thoi_gian_Kthuc,
                    nd_bs.Ten_nguoi_dung AS Ten_bac_si,
                    nd_bs.Anh_dai_dien AS Anh_bac_si,
                    dv.Ten_dich_vu,
                    pk.Ten_phong_kham,
                    pk.Vi_tri AS Dia_chi_phong_kham,
                    tt.Tong_tien,
                    tt.Phuong_thuc AS Phuong_thuc_thanh_toan,
                    tt.Trang_thai_thanh_toan,
                    -- Logic thông minh để lấy đúng Tên người đi khám
                    CASE 
                        WHEN lh.Ma_nguoi_than IS NOT NULL THEN nt.Ten_nguoi_than
                        ELSE nd_bn.Ten_nguoi_dung
                    END AS Ten_nguoi_kham,
                    CASE 
                        WHEN lh.Ma_nguoi_than IS NOT NULL THEN nt.Quan_he
                        ELSE 'Bản thân'
                    END AS Moi_quan_he

                FROM lich_hen lh
                JOIN bac_si bs ON lh.Ma_bac_si = bs.Ma_bac_si
                JOIN nguoi_dung nd_bs ON bs.Ma_nguoi_dung = nd_bs.Ma_nguoi_dung
                JOIN dich_vu dv ON lh.Ma_dich_vu = dv.Ma_dich_vu
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                JOIN phong_kham pk ON kg.Ma_phong_kham = pk.Ma_phong_kham
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                JOIN nguoi_dung nd_bn ON bn.Ma_nguoi_dung = nd_bn.Ma_nguoi_dung
                LEFT JOIN nguoi_than nt ON lh.Ma_nguoi_than = nt.Ma_nguoi_than
                LEFT JOIN thanh_toan tt ON lh.Ma_lich_hen = tt.Ma_lich_hen
                WHERE lh.Ma_lich_hen = ?
            `;
            
            const [details] = await execute(sql, [appointmentID]);
            return details[0]; // Trả về 1 object duy nhất vì ID là độc nhất
        } catch (error) {
            throw new Error('Lỗi truy vấn chi tiết lịch hẹn: ' + error.message);
        }
    }

    // Hủy lịch hẹn với điều kiện chặn hủy trước 2 giờ
    static async cancelAppointment(appointmentID) {
        try {
            // 1. Lấy thời gian bắt đầu khám, trạng thái VÀ LẤY THÊM Ma_khung_gio
            const checkSql = `
                SELECT lh.Ma_khung_gio, kg.Thoi_gian_Bdau, lh.Trang_thai_lich_hen 
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                WHERE lh.Ma_lich_hen = ?
            `;
            const [rows] = await execute(checkSql, [appointmentID]);
            if (rows.length === 0) {
                return { success: false, message: "Không tìm thấy lịch hẹn này." };
            }

            const appointment = rows[0];
            const maKhungGio = appointment.Ma_khung_gio; // LẤY MÃ KHUNG GIỜ ĐỂ TÍNH SAU SẼ NHẢ RA
            
            // Chặn nếu lịch đã xử lý rồi
            if (appointment.Trang_thai_lich_hen === 'cancelled' || appointment.Trang_thai_lich_hen === 'absent') {
                return { success: false, message: "Lịch hẹn này đã được hủy hoặc báo vắng từ trước." };
            }
            if (appointment.Trang_thai_lich_hen === 'done') {
                return { success: false, message: "Không thể hủy lịch khám đã hoàn thành." };
            }

            // Kiểm tra chính sách chặn hủy trước 2 giờ
            const startTime = new Date(appointment.Thoi_gian_Bdau);
            const now = new Date();
            const diffInHours = (startTime - now) / (1000 * 60 * 60);

            if (diffInHours < 2) {
                return { success: false, message: "Theo chính sách, bạn chỉ được phép hủy lịch khám trước giờ bắt đầu tối thiểu 2 tiếng." };
            }

            // 2. Cập nhật trạng thái lịch hẹn thành 'cancelled'
            const updateSql = `UPDATE lich_hen SET Trang_thai_lich_hen = 'cancelled' WHERE Ma_lich_hen = ?`;
            await execute(updateSql, [appointmentID]);

            // 🌟 3. Nhả khung giờ về lại trạng thái 'available'
            const releaseSlotSql = `UPDATE khung_gio_kham SET Trang_thai = 'available' WHERE Ma_khung_gio = ?`;
            await execute(releaseSlotSql, [maKhungGio]);

            // 4. TODO: KHỞI TẠO HOÀN TIỀN TỰ ĐỘNG...
            console.log(`[TODO_REFUND]: Lịch hẹn ${appointmentID} thỏa điều kiện hoàn tiền nếu đã thanh toán online.`);

            return { success: true, message: "Hủy lịch khám thành công." };

        } catch (error) {
            throw new Error('Lỗi khi xử lý hủy lịch: ' + error.message);
        }
    }

    // Đổi lịch hẹn với điều kiện chặn đổi trước 2 giờ và kiểm tra slot mới
    static async rescheduleAppointment(appointmentID, newSlotID) {
        try {
            // 1. Kiểm tra chính sách chặn đổi lịch trước 2 giờ
            const checkSql = `
                SELECT lh.Ma_khung_gio, kg.Thoi_gian_Bdau 
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                WHERE lh.Ma_lich_hen = ?
            `;
            const [rows] = await execute(checkSql, [appointmentID]);
            if (rows.length === 0) return { success: false, message: "Không tìm thấy lịch hẹn." };
            
            const oldSlotID = rows[0].Ma_khung_gio;
            const startTime = new Date(rows[0].Thoi_gian_Bdau);
            const now = new Date();
            
            if ((startTime - now) / (1000 * 60 * 60) < 2) {
                return { success: false, message: "Chỉ được đổi lịch trước giờ khám tối thiểu 2 tiếng." };
            }

            // 2. Kiểm tra slot mới có thực sự còn trống không (chống double booking)
            const checkNewSlot = await execute(`SELECT Trang_thai FROM khung_gio_kham WHERE Ma_khung_gio = ?`, [newSlotID]);
            if (checkNewSlot[0].length === 0 || checkNewSlot[0][0].Trang_thai !== 'available') {
                return { success: false, message: "Khung giờ này đã có người đặt hoặc không tồn tại." };
            }

            // 3. Thực hiện đổi lịch
            // Nhả slot cũ thành available
            await execute(`UPDATE khung_gio_kham SET Trang_thai = 'available' WHERE Ma_khung_gio = ?`, [oldSlotID]);
            // Khóa slot mới thành booked
            await execute(`UPDATE khung_gio_kham SET Trang_thai = 'booked' WHERE Ma_khung_gio = ?`, [newSlotID]);
            // Cập nhật slot mới cho lịch hẹn
            await execute(`UPDATE lich_hen SET Ma_khung_gio = ? WHERE Ma_lich_hen = ?`, [newSlotID, appointmentID]);

            return { success: true, message: "Đổi lịch khám thành công!" };
        } catch (error) {
            throw new Error('Lỗi khi đổi lịch: ' + error.message);
        }
    }

    // =====================================================================
    // CÁC HÀM DÀNH CHO BÁC SĨ (DOCTOR PORTAL)
    // =====================================================================

    // Lấy dữ liệu tổng hợp cho Trang chủ (Dashboard) của Bác sĩ
    static async getDoctorDashboard(userID) {
        try {
            // Quét và hủy các ca 'pending' quá hạn trước khi query
            const cleanupSql = `
                UPDATE lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                SET lh.Trang_thai_lich_hen = 'cancelled'
                WHERE lh.Trang_thai_lich_hen = 'pending' AND kg.Thoi_gian_Bdau < NOW()
            `;
            await execute(cleanupSql);

            // 1. Lấy Ma_bac_si dựa trên userID
            const [doctorInfo] = await execute(`SELECT Ma_bac_si FROM bac_si WHERE Ma_nguoi_dung = ?`, [userID]);
            if (doctorInfo.length === 0) throw new Error('Tài khoản này không phải là bác sĩ.');
            const maBacSi = doctorInfo[0].Ma_bac_si;

            // 2. Lịch chờ xác nhận: CHỈ lấy những ca có giờ bắt đầu TRONG TƯƠNG LAI
            const pendingSql = `
                SELECT lh.Ma_lich_hen, nd.Ten_nguoi_dung AS Ten_benh_nhan, kg.Thoi_gian_Bdau, lh.Trieu_chung
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                JOIN nguoi_dung nd ON bn.Ma_nguoi_dung = nd.Ma_nguoi_dung
                WHERE lh.Ma_bac_si = ? 
                AND lh.Trang_thai_lich_hen = 'pending'
                AND kg.Thoi_gian_Bdau >= NOW() -- 🌟 Thêm dòng này để ẩn ca quá hạn
                ORDER BY kg.Thoi_gian_Bdau ASC
            `;
            const [pendingList] = await execute(pendingSql, [maBacSi]);

            // 3. Lấy danh sách lịch khám hôm nay (Hiển thị tất cả ca confirmed của ngày hôm nay chưa xử lý)
            const todaySql = `
                SELECT lh.Ma_lich_hen, nd.Ten_nguoi_dung AS Ten_benh_nhan, kg.Thoi_gian_Bdau, lh.Hinh_thuc
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                JOIN nguoi_dung nd ON bn.Ma_nguoi_dung = nd.Ma_nguoi_dung
                WHERE lh.Ma_bac_si = ? 
                AND lh.Trang_thai_lich_hen = 'confirmed' 
                AND DATE(kg.Thoi_gian_Bdau) = CURDATE() -- 🌟 Chỉ giữ lại điều kiện ngày hôm nay, bỏ điều kiện NOW() của giờ kết thúc
                ORDER BY kg.Thoi_gian_Bdau ASC
            `;
            const [todayList] = await execute(todaySql, [maBacSi]);

            // 4. Thống kê số lượng lịch hẹn đã hủy hôm nay
            const cancelSql = `
                SELECT COUNT(*) as CancelCount 
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                WHERE lh.Ma_bac_si = ? AND lh.Trang_thai_lich_hen = 'cancelled'
                AND DATE(kg.Thoi_gian_Bdau) = CURDATE()
            `;
            const [cancelCount] = await execute(cancelSql, [maBacSi]);

            return {
                stats: {
                    pendingCount: pendingList.length,
                    todayCount: todayList.length,
                    cancelledCount: cancelCount[0].CancelCount
                },
                pendingAppointments: pendingList,
                todayAppointments: todayList
            };

        } catch (error) {
            throw new Error('Lỗi truy vấn Dashboard Bác sĩ: ' + error.message);
        }
    }

    // Bác sĩ xác nhận hoặc từ chối lịch hẹn
    static async updateAppointmentStatus(appointmentID, status, userID) {
        try {
            // 1. Xác thực quyền bác sĩ
            const [doctorInfo] = await execute(`SELECT Ma_bac_si FROM bac_si WHERE Ma_nguoi_dung = ?`, [userID]);
            if (doctorInfo.length === 0) throw new Error('Không có quyền truy cập.');
            const maBacSi = doctorInfo[0].Ma_bac_si;

            // 2. Lấy Mã khung giờ của lịch hẹn hiện tại
            const [apptInfo] = await execute(
                `SELECT Ma_khung_gio FROM lich_hen WHERE Ma_lich_hen = ? AND Ma_bac_si = ?`, 
                [appointmentID, maBacSi]
            );
            
            if (apptInfo.length === 0) {
                throw new Error('Lịch hẹn không tồn tại hoặc không thuộc thẩm quyền của bạn.');
            }

            const maKhungGio = apptInfo[0].Ma_khung_gio;

            // 3. Xử lý logic dựa trên hành động của bác sĩ
            if (status === 'cancelled') {
                // 🌟 Nhả khung giờ về lại trạng thái trống để người khác đặt
                await execute(`UPDATE khung_gio_kham SET Trang_thai = 'available' WHERE Ma_khung_gio = ?`, [maKhungGio]);
            } else if (status === 'confirmed') {
                // Đảm bảo chắc chắn slot này đã bị khóa khi bác sĩ duyệt
                await execute(`UPDATE khung_gio_kham SET Trang_thai = 'booked' WHERE Ma_khung_gio = ?`, [maKhungGio]);
            }

            // 4. Cập nhật trạng thái cho bảng Lịch Hẹn
            await execute(`UPDATE lich_hen SET Trang_thai_lich_hen = ? WHERE Ma_lich_hen = ?`, [status, appointmentID]);

            return { success: true, message: status === 'cancelled' ? "Đã từ chối và giải phóng khung giờ." : "Đã xác nhận lịch hẹn." };
        } catch (error) {
            throw new Error('Lỗi cập nhật trạng thái lịch hẹn: ' + error.message);
        }
    }

    // Lấy tất cả lịch hẹn của một bác sĩ (Dành cho màn hình Danh sách 5 Tabs)
    static async getAllDoctorAppointments(userID) {
        try {
            // Xác thực và lấy mã bác sĩ
            const [doctorInfo] = await execute(`SELECT Ma_bac_si FROM bac_si WHERE Ma_nguoi_dung = ?`, [userID]);
            if (doctorInfo.length === 0) throw new Error('Tài khoản này không phải là bác sĩ.');
            const maBacSi = doctorInfo[0].Ma_bac_si;

            // Quét dọn các ca 'pending' quá hạn của chính bác sĩ này
            const cleanupSql = `
                UPDATE lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                SET lh.Trang_thai_lich_hen = 'cancelled'
                WHERE lh.Trang_thai_lich_hen = 'pending' 
                AND kg.Thoi_gian_Bdau < NOW() 
                AND lh.Ma_bac_si = ?
            `;
            await execute(cleanupSql, [maBacSi]);

            // Truy vấn lấy toàn bộ lịch hẹn
            const sql = `
                SELECT 
                    lh.Ma_lich_hen,
                    lh.Ma_booking,
                    lh.Trang_thai_lich_hen,
                    lh.Hinh_thuc,
                    kg.Thoi_gian_Bdau,
                    kg.Thoi_gian_Kthuc,
                    nd.Ten_nguoi_dung AS Ten_benh_nhan,
                    nd.Anh_dai_dien AS Anh_benh_nhan
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                JOIN nguoi_dung nd ON bn.Ma_nguoi_dung = nd.Ma_nguoi_dung
                WHERE lh.Ma_bac_si = ?
                ORDER BY kg.Thoi_gian_Bdau DESC -- Xếp ca mới nhất lên đầu
            `;
            
            const [list] = await execute(sql, [maBacSi]);
            return list;
        } catch (error) {
            throw new Error('Lỗi truy vấn danh sách lịch hẹn bác sĩ: ' + error.message);
        }
    }
}