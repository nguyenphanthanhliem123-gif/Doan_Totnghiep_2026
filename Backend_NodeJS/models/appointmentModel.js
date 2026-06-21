import { beginTransaction, commitTransaction, execute, rollbackTransaction } from "../config/db.js";

export default class appointmentModel {

    // Lấy danh sách lịch hẹn của bệnh nhân dựa trên userID
    static async getPatientAppointments(userID) {
        try {
            // 1. Lưu lịch sử cho các ca sắp bị hệ thống tự động hủy
            const insertHistorySql = `
                INSERT INTO lich_su_trang_thai_lich_hen (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Nguoi_thay_doi)
                SELECT lh.Ma_lich_hen, 'pending', 'cancelled', 'system'
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                WHERE lh.Trang_thai_lich_hen = 'pending' AND kg.Thoi_gian_Bdau < NOW()
            `;
            await execute(insertHistorySql);

            // 2. Nhả khung giờ từ 'booked' về lại 'available' cho các ca quá hạn
            const releaseSlotSql = `
                UPDATE khung_gio_kham kg
                JOIN lich_hen lh ON lh.Ma_khung_gio = kg.Ma_khung_gio
                SET kg.Trang_thai = 'available'
                WHERE lh.Trang_thai_lich_hen = 'pending' AND kg.Thoi_gian_Bdau < NOW()
            `;
            await execute(releaseSlotSql);

            // 3. Cập nhật trạng thái lịch hẹn thành 'cancelled'
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
            // 1. Lấy thông tin chung của Lịch Hẹn (Vỏ lịch hẹn)
            const sqlLichHen = `
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
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                JOIN phong_kham pk ON kg.Ma_phong_kham = pk.Ma_phong_kham
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                JOIN nguoi_dung nd_bn ON bn.Ma_nguoi_dung = nd_bn.Ma_nguoi_dung
                LEFT JOIN nguoi_than nt ON lh.Ma_nguoi_than = nt.Ma_nguoi_than
                LEFT JOIN thanh_toan tt ON lh.Ma_lich_hen = tt.Ma_lich_hen
                WHERE lh.Ma_lich_hen = ?
            `;
            
            const [details] = await execute(sqlLichHen, [appointmentID]);
            
            if (details.length === 0) return null; // Nếu không tìm thấy lịch hẹn

            const appointmentData = details[0];

            // 2. Lấy danh sách dịch vụ từ bảng chi tiết
            const sqlDichVu = `
                SELECT dv.Ten_dich_vu, ct.Gia_tien
                FROM chi_tiet_lich_hen ct
                JOIN dich_vu dv ON ct.Ma_dich_vu = dv.Ma_dich_vu
                WHERE ct.Ma_lich_hen = ?
            `;
            const [services] = await execute(sqlDichVu, [appointmentID]);

            // Gộp danh sách tên dịch vụ thành một chuỗi cách nhau bởi dấu phẩy
            appointmentData.Ten_dich_vu = services.map(s => s.Ten_dich_vu).join(', ');
            
            // Bạn có thể giữ lại mảng dịch vụ chi tiết nếu muốn hiển thị từng dòng giá ở Frontend
            appointmentData.Danh_sach_dich_vu = services; 

            return appointmentData;
        } catch (error) {
            throw new Error('Lỗi truy vấn chi tiết lịch hẹn: ' + error.message);
        }
    }

    // Hủy lịch hẹn với điều kiện chặn hủy trước 2 giờ
    static async cancelAppointment(appointmentID) {
        let conn;
        try {
            conn = await beginTransaction();
            
            const checkSql = `
                SELECT lh.Ma_khung_gio, kg.Thoi_gian_Bdau, lh.Trang_thai_lich_hen 
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                WHERE lh.Ma_lich_hen = ?
            `;
            const [rows] = await conn.execute(checkSql, [appointmentID]);
            if (rows.length === 0) {
                return { success: false, message: "Không tìm thấy lịch hẹn này." };
            }

            const appointment = rows[0];
            const maKhungGio = appointment.Ma_khung_gio; 
            const trangThaiCu = appointment.Trang_thai_lich_hen; // Lấy trạng thái cũ
            
            if (trangThaiCu === 'cancelled' || trangThaiCu === 'absent') {
                return { success: false, message: "Lịch hẹn này đã được hủy hoặc báo vắng từ trước." };
            }
            if (trangThaiCu === 'done') {
                return { success: false, message: "Không thể hủy lịch khám đã hoàn thành." };
            }

            const startTime = new Date(appointment.Thoi_gian_Bdau);
            const now = new Date();
            const diffInHours = (startTime - now) / (1000 * 60 * 60);

            if (diffInHours < 2) {
                return { success: false, message: "Theo chính sách, bạn chỉ được phép hủy lịch khám trước giờ bắt đầu tối thiểu 2 tiếng." };
            }

            // 2. Cập nhật trạng thái lịch hẹn thành 'cancelled'
            const updateSql = `UPDATE lich_hen SET Trang_thai_lich_hen = 'cancelled' WHERE Ma_lich_hen = ?`;
            await conn.execute(updateSql, [appointmentID]);

            // 3. Lưu thay đổi lịch sử
            const insertHistorySql = `
                INSERT INTO lich_su_trang_thai_lich_hen 
                (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Nguoi_thay_doi) 
                VALUES (?, ?, 'cancelled', 'patient')
            `;
            await conn.execute(insertHistorySql, [appointmentID, trangThaiCu]);

            // 4. Nhả khung giờ về lại trạng thái 'available'
            const releaseSlotSql = `UPDATE khung_gio_kham SET Trang_thai = 'available' WHERE Ma_khung_gio = ?`;
            await conn.execute(releaseSlotSql, [maKhungGio]);

            await commitTransaction(conn);

            return { success: true, message: "Hủy lịch khám thành công." };

        } catch (error) {
            if(conn) await rollbackTransaction(conn);
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
            // Quét và hủy các ca 'pending' quá hạn
            // 1. Lưu lịch sử cho các ca sắp bị hệ thống tự động hủy
            const insertHistorySql = `
                INSERT INTO lich_su_trang_thai_lich_hen (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Nguoi_thay_doi)
                SELECT lh.Ma_lich_hen, 'pending', 'cancelled', 'system'
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                WHERE lh.Trang_thai_lich_hen = 'pending' AND kg.Thoi_gian_Bdau < NOW()
            `;
            await execute(insertHistorySql);

            // 2. Nhả khung giờ từ 'booked' về lại 'available' cho các ca quá hạn
            const releaseSlotSql = `
                UPDATE khung_gio_kham kg
                JOIN lich_hen lh ON lh.Ma_khung_gio = kg.Ma_khung_gio
                SET kg.Trang_thai = 'available'
                WHERE lh.Trang_thai_lich_hen = 'pending' AND kg.Thoi_gian_Bdau < NOW()
            `;
            await execute(releaseSlotSql);

            // 3. Cập nhật trạng thái lịch hẹn thành 'cancelled'
            const cleanupSql = `
                UPDATE lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                SET lh.Trang_thai_lich_hen = 'cancelled'
                WHERE lh.Trang_thai_lich_hen = 'pending' AND kg.Thoi_gian_Bdau < NOW()
            `;
            await execute(cleanupSql);

            const [doctorInfo] = await execute(`SELECT Ma_bac_si FROM bac_si WHERE Ma_nguoi_dung = ?`, [userID]);
            if (doctorInfo.length === 0) throw new Error('Tài khoản này không phải là bác sĩ.');
            const maBacSi = doctorInfo[0].Ma_bac_si;

            // Lịch chờ xác nhận: Lấy thêm danh sách Dịch Vụ
            const pendingSql = `
                SELECT 
                    lh.Ma_lich_hen, nd.Ten_nguoi_dung AS Ten_benh_nhan, 
                    kg.Thoi_gian_Bdau, lh.Trieu_chung,
                    GROUP_CONCAT(dv.Ten_dich_vu SEPARATOR ', ') AS Ten_dich_vu
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                JOIN nguoi_dung nd ON bn.Ma_nguoi_dung = nd.Ma_nguoi_dung
                LEFT JOIN chi_tiet_lich_hen ct ON lh.Ma_lich_hen = ct.Ma_lich_hen
                LEFT JOIN dich_vu dv ON ct.Ma_dich_vu = dv.Ma_dich_vu
                WHERE lh.Ma_bac_si = ? 
                AND lh.Trang_thai_lich_hen = 'pending'
                AND kg.Thoi_gian_Bdau >= NOW()
                GROUP BY lh.Ma_lich_hen
                ORDER BY kg.Thoi_gian_Bdau ASC
            `;
            const [pendingList] = await execute(pendingSql, [maBacSi]);

            // Lịch khám hôm nay: Lấy thêm danh sách Dịch Vụ
            const todaySql = `
                SELECT 
                    lh.Ma_lich_hen, nd.Ten_nguoi_dung AS Ten_benh_nhan, 
                    kg.Thoi_gian_Bdau, lh.Hinh_thuc,
                    GROUP_CONCAT(dv.Ten_dich_vu SEPARATOR ', ') AS Ten_dich_vu
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                JOIN nguoi_dung nd ON bn.Ma_nguoi_dung = nd.Ma_nguoi_dung
                LEFT JOIN chi_tiet_lich_hen ct ON lh.Ma_lich_hen = ct.Ma_lich_hen
                LEFT JOIN dich_vu dv ON ct.Ma_dich_vu = dv.Ma_dich_vu
                WHERE lh.Ma_bac_si = ? 
                AND lh.Trang_thai_lich_hen = 'confirmed' 
                AND DATE(kg.Thoi_gian_Bdau) = CURDATE()
                GROUP BY lh.Ma_lich_hen
                ORDER BY kg.Thoi_gian_Bdau ASC
            `;
            const [todayList] = await execute(todaySql, [maBacSi]);

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

            // 2. Lấy Mã khung giờ VÀ Trạng thái cũ của lịch hẹn hiện tại
            const [apptInfo] = await execute(
                `SELECT Ma_khung_gio, Trang_thai_lich_hen FROM lich_hen WHERE Ma_lich_hen = ? AND Ma_bac_si = ?`, 
                [appointmentID, maBacSi]
            );
            
            if (apptInfo.length === 0) {
                throw new Error('Lịch hẹn không tồn tại hoặc không thuộc thẩm quyền của bạn.');
            }

            const maKhungGio = apptInfo[0].Ma_khung_gio;
            const trangThaiCu = apptInfo[0].Trang_thai_lich_hen; // Lấy trạng thái cũ

            // 3. Xử lý logic dựa trên hành động của bác sĩ
            if (status === 'cancelled') {
                await execute(`UPDATE khung_gio_kham SET Trang_thai = 'available' WHERE Ma_khung_gio = ?`, [maKhungGio]);
            } else if (status === 'confirmed') {
                await execute(`UPDATE khung_gio_kham SET Trang_thai = 'booked' WHERE Ma_khung_gio = ?`, [maKhungGio]);
            }

            // 4. Cập nhật trạng thái mới cho bảng Lịch Hẹn
            await execute(`UPDATE lich_hen SET Trang_thai_lich_hen = ? WHERE Ma_lich_hen = ?`, [status, appointmentID]);

            // 5. Lưu lịch sử thay đổi
            if (trangThaiCu !== status) {
                await execute(
                    `INSERT INTO lich_su_trang_thai_lich_hen 
                    (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Nguoi_thay_doi) 
                    VALUES (?, ?, ?, 'doctor')`, 
                    [appointmentID, trangThaiCu, status]
                );
            }

            return { success: true, message: status === 'cancelled' ? "Đã từ chối và giải phóng khung giờ." : "Đã xác nhận lịch hẹn." };
        } catch (error) {
            throw new Error('Lỗi cập nhật trạng thái lịch hẹn: ' + error.message);
        }
    }

    // Lấy tất cả lịch hẹn của một bác sĩ (Dành cho màn hình Danh sách 5 Tabs)
    static async getAllDoctorAppointments(userID) {
        try {
            const [doctorInfo] = await execute(`SELECT Ma_bac_si FROM bac_si WHERE Ma_nguoi_dung = ?`, [userID]);
            if (doctorInfo.length === 0) throw new Error('Tài khoản này không phải là bác sĩ.');
            const maBacSi = doctorInfo[0].Ma_bac_si;

           // 1. Lưu lịch sử cho các ca sắp bị hệ thống tự động hủy (Theo mã bác sĩ)
            const insertHistorySql = `
                INSERT INTO lich_su_trang_thai_lich_hen (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Nguoi_thay_doi)
                SELECT lh.Ma_lich_hen, 'pending', 'cancelled', 'system'
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                WHERE lh.Trang_thai_lich_hen = 'pending' 
                AND kg.Thoi_gian_Bdau < NOW()
                AND lh.Ma_bac_si = ?
            `;
            await execute(insertHistorySql, [maBacSi]);

            // 2. Nhả khung giờ về lại 'available' (Theo mã bác sĩ)
            const releaseSlotSql = `
                UPDATE khung_gio_kham kg
                JOIN lich_hen lh ON lh.Ma_khung_gio = kg.Ma_khung_gio
                SET kg.Trang_thai = 'available'
                WHERE lh.Trang_thai_lich_hen = 'pending' 
                AND kg.Thoi_gian_Bdau < NOW()
                AND lh.Ma_bac_si = ?
            `;
            await execute(releaseSlotSql, [maBacSi]);

            // 3. Cập nhật trạng thái lịch hẹn thành 'cancelled' (Theo mã bác sĩ)
            const cleanupSql = `
                UPDATE lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                SET lh.Trang_thai_lich_hen = 'cancelled'
                WHERE lh.Trang_thai_lich_hen = 'pending' 
                AND kg.Thoi_gian_Bdau < NOW()
                AND lh.Ma_bac_si = ?
            `;
            await execute(cleanupSql, [maBacSi]);

            const sql = `
                SELECT 
                    lh.Ma_lich_hen,
                    lh.Ma_booking,
                    lh.Trang_thai_lich_hen,
                    lh.Hinh_thuc,
                    kg.Thoi_gian_Bdau,
                    kg.Thoi_gian_Kthuc,
                    nd.Ten_nguoi_dung AS Ten_benh_nhan,
                    nd.Anh_dai_dien AS Anh_benh_nhan,
                    GROUP_CONCAT(dv.Ten_dich_vu SEPARATOR ', ') AS Ten_dich_vu
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                JOIN nguoi_dung nd ON bn.Ma_nguoi_dung = nd.Ma_nguoi_dung
                LEFT JOIN chi_tiet_lich_hen ct ON lh.Ma_lich_hen = ct.Ma_lich_hen
                LEFT JOIN dich_vu dv ON ct.Ma_dich_vu = dv.Ma_dich_vu
                WHERE lh.Ma_bac_si = ?
                GROUP BY lh.Ma_lich_hen
                ORDER BY kg.Thoi_gian_Bdau DESC
            `;
            
            const [list] = await execute(sql, [maBacSi]);
            return list;
        } catch (error) {
            throw new Error('Lỗi truy vấn danh sách lịch hẹn bác sĩ: ' + error.message);
        }
    }

    // Lấy thông tin thanh toán và giờ khám của 1 lịch hẹn
    static async getAppointmentForRefund(appointmentID) {
        // Truy vấn nối bảng: lich_hen -> khung_gio_kham -> thanh_toan
        const sql = `
            SELECT 
                lh.Ma_booking, 
                kg.Thoi_gian_Bdau, 
                tt.Ma_giao_dich, 
                tt.Tong_tien, 
                tt.Thoi_diem_thanh_toan,
                tt.Trang_thai_thanh_toan
            FROM lich_hen lh
            JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
            LEFT JOIN thanh_toan tt ON lh.Ma_lich_hen = tt.Ma_lich_hen
            WHERE lh.Ma_lich_hen = ?
        `;
        const [rows] = await execute(sql, [appointmentID]);
        return rows.length > 0 ? rows[0] : null;
    }

    // Lấy chi tiết ca khám cho màn hình bác sĩ
    static async getDoctorAppointmentDetail(appointmentID) {
        try {
            const sqlLichHen = `
                SELECT 
                    lh.Ma_lich_hen,
                    lh.Ma_booking AS bookingCode,
                    lh.Hinh_thuc AS type,
                    lh.Trang_thai_lich_hen AS status,
                    lh.Trieu_chung AS symptoms,
                    lh.Link_video_call AS linkVideoCall,
                    kg.Thoi_gian_Bdau AS startTime,
                    kg.Thoi_gian_Kthuc AS endTime,
                    
                    -- Thông tin Bệnh nhân (Người trực tiếp khám)
                    CASE 
                        WHEN lh.Ma_nguoi_than IS NOT NULL THEN nt.Ten_nguoi_than
                        ELSE nd_bn.Ten_nguoi_dung
                    END AS patientName,
                    CASE 
                        WHEN lh.Ma_nguoi_than IS NOT NULL THEN TIMESTAMPDIFF(YEAR, nt.Ngay_sinh, NOW())
                        ELSE TIMESTAMPDIFF(YEAR, bn.Ngay_sinh, NOW())
                    END AS patientAge,
                    IF(bn.Gioi_tinh = 1, 'Nam', 'Nữ') AS patientGender,
                    CASE 
                        WHEN lh.Ma_nguoi_than IS NOT NULL THEN NULL
                        ELSE nd_bn.Anh_dai_dien
                    END AS patientAvatar,
                    
                    -- Tiền sử bệnh
                    bn.Nhom_mau AS bloodType,
                    bn.Di_ung AS allergies,
                    bn.Benh_nen AS backgroundDiseases,

                    -- Thông tin Người liên hệ (Chỉ áp dụng nếu khám cho người thân)
                    IF(lh.Ma_nguoi_than IS NOT NULL, 1, 0) AS isRelative,
                    nd_bn.Ten_nguoi_dung AS contactName,
                    nd_bn.Dien_thoai AS contactPhone,
                    nt.Quan_he AS relationship,

                    -- Thông tin Thanh toán
                    tt.Tong_tien AS totalAmount,
                    tt.Trang_thai_thanh_toan AS paymentStatus,
                    tt.Phuong_thuc AS paymentMethod

                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                JOIN nguoi_dung nd_bn ON bn.Ma_nguoi_dung = nd_bn.Ma_nguoi_dung
                LEFT JOIN nguoi_than nt ON lh.Ma_nguoi_than = nt.Ma_nguoi_than
                LEFT JOIN thanh_toan tt ON lh.Ma_lich_hen = tt.Ma_lich_hen
                WHERE lh.Ma_lich_hen = ?
            `;

            const [rows] = await execute(sqlLichHen, [appointmentID]);
            if (rows.length === 0) return null;

            const appointmentData = rows[0];

            // Lấy danh sách dịch vụ đi kèm
            const sqlDichVu = `
                SELECT dv.Ten_dich_vu
                FROM chi_tiet_lich_hen ct
                JOIN dich_vu dv ON ct.Ma_dich_vu = dv.Ma_dich_vu
                WHERE ct.Ma_lich_hen = ?
            `;
            const [services] = await execute(sqlDichVu, [appointmentID]);
            
            appointmentData.selectedServices = services.map(s => s.Ten_dich_vu).join(', ');

            return appointmentData;
        } catch (error) {
            throw new Error('Lỗi truy vấn chi tiết ca khám bác sĩ: ' + error.message);
        }
    }
}