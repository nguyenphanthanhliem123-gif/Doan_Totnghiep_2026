import { beginTransaction, commitTransaction, execute, rollbackTransaction } from "../config/db.js";
import { decrypt } from '../utils/cryptoUtil.js';

export default class appointmentModel {

    // Lấy danh sách lịch hẹn của bệnh nhân dựa trên userID
    static async getPatientAppointments(userID, status = 'all', date = 'all', search = '') {
        try {
            // Tự động cập nhật trạng thái lịch hẹn "pending" sang "reschedule_pending" nếu đã quá giờ khám
            const insertHistorySql = `
                INSERT INTO lich_su_trang_thai_lich_hen (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Nguoi_thay_doi)
                SELECT lh.Ma_lich_hen, 'pending', 'reschedule_pending', 'system'
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                WHERE lh.Trang_thai_lich_hen = 'pending' AND kg.Thoi_gian_Bdau < NOW()
            `;
            await execute(insertHistorySql);

            const releaseSlotSql = `
                UPDATE khung_gio_kham kg
                JOIN lich_hen lh ON lh.Ma_khung_gio = kg.Ma_khung_gio
                SET kg.Trang_thai = 'available'
                WHERE lh.Trang_thai_lich_hen = 'pending' AND kg.Thoi_gian_Bdau < NOW()
            `;
            await execute(releaseSlotSql);

            const cleanupSql = `
                UPDATE lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                SET lh.Trang_thai_lich_hen = 'reschedule_pending'
                WHERE lh.Trang_thai_lich_hen = 'pending' AND kg.Thoi_gian_Bdau < NOW()
            `;
            await execute(cleanupSql);

            let sql = `
                SELECT 
                    lh.Ma_lich_hen,
                    lh.Ma_booking,
                    lh.Ma_bac_si,
                    lh.Trang_thai_lich_hen,
                    lh.Hinh_thuc,
                    kg.Thoi_gian_Bdau,
                    kg.Thoi_gian_Kthuc,
                    nd.Ten_nguoi_dung AS Ten_bac_si,
                    nd.Anh_dai_dien AS Anh_bac_si,
                    bs.Trang_thai_hoat_dong AS Trang_thai_bac_si
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                JOIN bac_si bs ON lh.Ma_bac_si = bs.Ma_bac_si
                JOIN nguoi_dung nd ON bs.Ma_nguoi_dung = nd.Ma_nguoi_dung
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                WHERE bn.Ma_nguoi_dung = ?
            `;
            
            const params = [userID];

            // Điều kiện lọc trạng thái
            if (status && status !== 'all') {
                // Các trạng thái: 'pending','confirmed','done','cancelled','absent','reschedule_pending'
                sql += ` AND lh.Trang_thai_lich_hen = ?`;
                params.push(status);
            }

            // Điều kiện lọc ngày
            if (date && date !== 'all') {
                sql += ` AND DATE(kg.Thoi_gian_Bdau) = ?`;
                params.push(date);
            }

            // Điều kiện tìm kiếm (Tên Bác sĩ hoặc Mã Booking)
            if (search && search.trim() !== '') {
                sql += ` AND (nd.Ten_nguoi_dung LIKE ? OR lh.Ma_booking LIKE ?)`;
                const searchParam = `%${search.trim()}%`;
                params.push(searchParam, searchParam);
            }

            sql += ` ORDER BY kg.Thoi_gian_Bdau DESC`;
            
            const [appointments] = await execute(sql, params);
            return appointments;
        } catch (error) {
            throw new Error('Lỗi truy vấn lịch hẹn: ' + error.message);
        }
    }

    // Lấy tất cả lịch hẹn của bệnh nhân dựa trên userID
    static async getAllPatienAppointment(userID){
        try{
            const sql = `
                SELECT 
                    lh.Ma_lich_hen,
                    lh.Ma_booking,
                    lh.Ma_bac_si,
                    lh.Trang_thai_lich_hen,
                    lh.Hinh_thuc,
                    lh.Tong_tien,
                    kg.Thoi_gian_Bdau,
                    kg.Thoi_gian_Kthuc,
                    nd.Ten_nguoi_dung AS Ten_bac_si,
                    nd.Anh_dai_dien AS Anh_bac_si,
                    ck.Ma_chuyen_khoa,
                    ck.Ten_chuyen_khoa
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                JOIN bac_si bs ON lh.Ma_bac_si = bs.Ma_bac_si
                JOIN nguoi_dung nd ON bs.Ma_nguoi_dung = nd.Ma_nguoi_dung
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                JOIN chuyen_khoa ck ON ck.Ma_chuyen_khoa = bs.Ma_chuyen_khoa
                WHERE bn.Ma_nguoi_dung = ?
                ORDER BY kg.Thoi_gian_Bdau DESC
            `;
            
            const [appointments] = await execute(sql, [userID]);
            return appointments;
        }catch (error) {
            throw new Error('Lỗi truy vấn lịch hẹn: ' + error.message);
        }
    }

    // Lấy chi tiết lịch hẹn dựa trên Ma_lich_hen
    static async getAppointmentDetails(appointmentID) {
        try {
            const sqlLichHen = `
                SELECT 
                    lh.Ma_lich_hen,
                    lh.Ma_booking,
                    lh.Ma_bac_si,
                    lh.Hinh_thuc,
                    lh.Trang_thai_lich_hen,
                    lh.Trieu_chung AS Ghi_chu,
                    lh.Link_video_call,
                    bn.Ma_nguoi_dung,
                    bn.Ma_benh_nhan,
                    kg.Thoi_gian_Bdau,
                    kg.Thoi_gian_Kthuc,
                    nd_bs.Ten_nguoi_dung AS Ten_bac_si,
                    nd_bs.Anh_dai_dien AS Anh_bac_si,
                    nd_bn.Email,
                    nd_bs.Ma_nguoi_dung AS Ma_nguoi_dung_bac_si,
                    pk.Ten_phong_kham,
                    pk.Vi_tri AS Dia_chi_phong_kham,
                    lh.Tong_tien,
                    tt.Phuong_thuc AS Phuong_thuc_thanh_toan,
                    tt.Trang_thai_thanh_toan,
                    bs.Trang_thai_hoat_dong AS Trang_thai_bac_si,
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
                LEFT JOIN thanh_toan tt ON tt.Ma_lich_hen = lh.Ma_lich_hen
                WHERE lh.Ma_lich_hen = ?
            `;
            
            const [details] = await execute(sqlLichHen, [appointmentID]);
            if (details.length === 0) return null;

            const appointmentData = details[0];

            const sqlDichVu = `
                SELECT dv.Ten_dich_vu, ct.Gia_tien
                FROM chi_tiet_lich_hen ct
                JOIN dich_vu dv ON ct.Ma_dich_vu = dv.Ma_dich_vu
                WHERE ct.Ma_lich_hen = ?
            `;
            const [services] = await execute(sqlDichVu, [appointmentID]);

            appointmentData.Ten_dich_vu = services.map(s => s.Ten_dich_vu).join(', ');
            appointmentData.Danh_sach_dich_vu = services; 

            return appointmentData;
        } catch (error) {
            throw new Error('Lỗi truy vấn chi tiết lịch hẹn: ' + error.message);
        }
    }

    // Hủy lịch hẹn với điều kiện chặn hủy trước 2 giờ, không kiểm tra 2 giờ nếu bị bác sĩ ép dời lịch
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
            if (rows.length === 0) return { success: false, message: "Không tìm thấy lịch hẹn này." };

            const appointment = rows[0];
            const maKhungGio = appointment.Ma_khung_gio; 
            const trangThaiCu = appointment.Trang_thai_lich_hen; 
            
            if (trangThaiCu === 'cancelled' || trangThaiCu === 'absent') {
                return { success: false, message: "Lịch hẹn này đã được hủy hoặc báo vắng từ trước." };
            }
            if (trangThaiCu === 'done') {
                return { success: false, message: "Không thể hủy lịch khám đã hoàn thành." };
            }

            // Bỏ qua check 2 tiếng nếu bị bác sĩ ép dời lịch (Tránh lỗi kẹt ngày cũ)
            if (trangThaiCu !== 'reschedule_pending') {
                const startTime = new Date(appointment.Thoi_gian_Bdau);
                const now = new Date();
                const diffInHours = (startTime - now) / (1000 * 60 * 60);

                if (diffInHours < 2) {
                    return { success: false, message: "Theo chính sách, bạn chỉ được phép hủy lịch khám trước giờ bắt đầu tối thiểu 2 tiếng." };
                }
            }

            const updateSql = `UPDATE lich_hen SET Trang_thai_lich_hen = 'cancelled' WHERE Ma_lich_hen = ?`;
            await conn.execute(updateSql, [appointmentID]);

            const insertHistorySql = `
                INSERT INTO lich_su_trang_thai_lich_hen 
                (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Nguoi_thay_doi) 
                VALUES (?, ?, 'cancelled', 'patient')
            `;
            await conn.execute(insertHistorySql, [appointmentID, trangThaiCu]);

            const releaseSlotSql = `UPDATE khung_gio_kham SET Trang_thai = 'available' WHERE Ma_khung_gio = ?`;
            await conn.execute(releaseSlotSql, [maKhungGio]);

            await commitTransaction(conn);

            return { success: true, message: "Hủy lịch khám thành công." };

        } catch (error) {
            if(conn) await rollbackTransaction(conn);
            throw new Error('Lỗi khi xử lý hủy lịch: ' + error.message);
        }
    }

    // Đổi lịch hẹn với điều kiện chặn đổi trước 2 giờ, không cộng lượt đổi nếu bác sĩ ép dời lịch
    static async rescheduleAppointment(appointmentID, newSlotID) {
        let conn;
        try {
            conn = await beginTransaction();

            const oldSql = `
                SELECT lh.Ma_khung_gio, lh.Trang_thai_lich_hen, lh.So_lan_doi_lich, 
                       lh.Ma_benh_nhan, lh.Ma_nguoi_than, kg.Thoi_gian_Bdau 
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                WHERE lh.Ma_lich_hen = ?
            `;
            const [oldRows] = await conn.execute(oldSql, [appointmentID]);
            if (oldRows.length === 0) throw new Error("Không tìm thấy lịch hẹn.");
            
            const appt = oldRows[0];
            const now = new Date();

            if (appt.So_lan_doi_lich >= 1 && appt.Trang_thai_lich_hen !== 'reschedule_pending') {
                throw new Error("Bạn đã hết lượt đổi lịch cho ca khám này.");
            }

            if (appt.Trang_thai_lich_hen !== 'reschedule_pending') {
                const startTime = new Date(appt.Thoi_gian_Bdau);
                if ((startTime - now) / (1000 * 60 * 60) < 2) {
                    throw new Error("Theo chính sách, chỉ được tự đổi lịch trước giờ khám tối thiểu 2 tiếng.");
                }
            }

            const checkNewSlot = await conn.execute(
                `SELECT Trang_thai, Thoi_gian_Bdau FROM khung_gio_kham WHERE Ma_khung_gio = ? FOR UPDATE`, 
                [newSlotID]
            );
            if (checkNewSlot[0].length === 0 || checkNewSlot[0][0].Trang_thai !== 'available') {
                throw new Error("Khung giờ này vừa có người nhanh tay hơn đặt mất. Vui lòng chọn giờ khác.");
            }
            const newSlotTime = new Date(checkNewSlot[0][0].Thoi_gian_Bdau);
            if (newSlotTime < now) {
                throw new Error("Không thể đổi sang khung giờ trong quá khứ.");
            }

            let conflictSql = `
                SELECT lh.Ma_lich_hen 
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                WHERE lh.Ma_benh_nhan = ? 
                AND lh.Trang_thai_lich_hen IN ('pending', 'confirmed')
                AND kg.Thoi_gian_Bdau < (SELECT Thoi_gian_Kthuc FROM khung_gio_kham WHERE Ma_khung_gio = ?)
                AND kg.Thoi_gian_Kthuc > (SELECT Thoi_gian_Bdau FROM khung_gio_kham WHERE Ma_khung_gio = ?)
            `;
            const conflictParams = [appt.Ma_benh_nhan, newSlotID, newSlotID];
            if (appt.Ma_nguoi_than) {
                conflictSql += ` AND lh.Ma_nguoi_than = ?`;
                conflictParams.push(appt.Ma_nguoi_than);
            } else {
                conflictSql += ` AND lh.Ma_nguoi_than IS NULL`;
            }
            conflictSql += ` FOR UPDATE`;
            const [conflictRows] = await conn.execute(conflictSql, conflictParams);
            
            if (conflictRows.length > 0) {
                throw new Error("Người khám này đã có một lịch hẹn khác bị trùng hoặc giao thoa với giờ bạn vừa chọn!");
            }

            if (appt.Trang_thai_lich_hen !== 'reschedule_pending') {
                await conn.execute(`UPDATE khung_gio_kham SET Trang_thai = 'available' WHERE Ma_khung_gio = ?`, [appt.Ma_khung_gio]);
            }
            
            await conn.execute(`UPDATE khung_gio_kham SET Trang_thai = 'booked' WHERE Ma_khung_gio = ?`, [newSlotID]);
            
            // Xử lý động Update Lịch hẹn: Chỉ cộng lượt đổi nếu bệnh nhân TỰ Ý ĐỔI
            let updateLichHenSql = `UPDATE lich_hen SET Ma_khung_gio = ?, Trang_thai_lich_hen = 'pending'`;
            if (appt.Trang_thai_lich_hen !== 'reschedule_pending') {
                updateLichHenSql += `, So_lan_doi_lich = So_lan_doi_lich + 1`;
            }
            updateLichHenSql += ` WHERE Ma_lich_hen = ?`;
            await conn.execute(updateLichHenSql, [newSlotID, appointmentID]);

            await conn.execute(
                `INSERT INTO lich_su_trang_thai_lich_hen (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Nguoi_thay_doi) VALUES (?, ?, 'pending', 'patient')`, 
                [appointmentID, appt.Trang_thai_lich_hen]
            );

            await commitTransaction(conn);
            return { success: true, message: "Đổi lịch khám thành công! Vui lòng chờ bác sĩ xác nhận lại." };
        } catch (error) {
            if (conn) await rollbackTransaction(conn);
            throw new Error(error.message);
        }
    }

    // Các hàm của trang bác sĩ sẽ được đặt ở dưới đây

    // Lấy dữ liệu trang chủ Bác sĩ
    static async getDoctorDashboard(userID) {
        try {
            // Dọn dẹp ngầm: Chuyển tất cả lịch hẹn 'pending' đã quá giờ sang 'reschedule_pending'
            const insertHistorySql = `
                INSERT INTO lich_su_trang_thai_lich_hen (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Nguoi_thay_doi)
                SELECT lh.Ma_lich_hen, 'pending', 'reschedule_pending', 'system'
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                WHERE lh.Trang_thai_lich_hen = 'pending' AND kg.Thoi_gian_Bdau < NOW()
            `;
            await execute(insertHistorySql);

            const releaseSlotSql = `
                UPDATE khung_gio_kham kg
                JOIN lich_hen lh ON lh.Ma_khung_gio = kg.Ma_khung_gio
                SET kg.Trang_thai = 'available'
                WHERE lh.Trang_thai_lich_hen = 'pending' AND kg.Thoi_gian_Bdau < NOW()
            `;
            await execute(releaseSlotSql);

            const cleanupSql = `
                UPDATE lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                SET lh.Trang_thai_lich_hen = 'reschedule_pending'
                WHERE lh.Trang_thai_lich_hen = 'pending' AND kg.Thoi_gian_Bdau < NOW()
            `;
            await execute(cleanupSql);

            const [doctorInfo] = await execute(`SELECT Ma_bac_si FROM bac_si WHERE Ma_nguoi_dung = ?`, [userID]);
            if (doctorInfo.length === 0) throw new Error('Tài khoản này không phải là bác sĩ.');
            const maBacSi = doctorInfo[0].Ma_bac_si;

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

            const revenueDetailsSql = `
                SELECT 
                    nd.Ten_nguoi_dung AS Ten_benh_nhan,
                    kg.Thoi_gian_Bdau,
                    lh.Tong_tien,
                    GROUP_CONCAT(dv.Ten_dich_vu SEPARATOR ', ') AS Ten_dich_vu
                FROM lich_hen lh
                JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                JOIN benh_nhan bn ON lh.Ma_benh_nhan = bn.Ma_benh_nhan
                JOIN nguoi_dung nd ON bn.Ma_nguoi_dung = nd.Ma_nguoi_dung
                LEFT JOIN chi_tiet_lich_hen ct ON lh.Ma_lich_hen = ct.Ma_lich_hen
                LEFT JOIN dich_vu dv ON ct.Ma_dich_vu = dv.Ma_dich_vu
                WHERE lh.Ma_bac_si = ? 
                  AND lh.Trang_thai_lich_hen = 'done'
                  AND DATE(kg.Thoi_gian_Bdau) = CURDATE()
                GROUP BY lh.Ma_lich_hen
                ORDER BY kg.Thoi_gian_Bdau ASC
            `;
            const [revenueDetails] = await execute(revenueDetailsSql, [maBacSi]);
            const todayRevenue = revenueDetails.reduce((sum, item) => sum + Number(item.Tong_tien || 0), 0);

            return {
                stats: {
                    pendingCount: pendingList.length,
                    todayCount: todayList.length,
                    cancelledCount: cancelCount[0].CancelCount,
                    todayRevenue: todayRevenue
                },
                revenueDetails: revenueDetails,
                pendingAppointments: pendingList,
                todayAppointments: todayList
            };

        } catch (error) {
            throw new Error('Lỗi truy vấn Dashboard Bác sĩ: ' + error.message);
        }
    }

    // Cập nhật trạng thái lịch hẹn và khung giờ khám
    static async updateAppointmentStatus(appointmentID, status, userID) {
        try {
            const [doctorInfo] = await execute(`SELECT Ma_bac_si FROM bac_si WHERE Ma_nguoi_dung = ?`, [userID]);
            if (doctorInfo.length === 0) throw new Error('Không có quyền truy cập.');
            const maBacSi = doctorInfo[0].Ma_bac_si;

            const [apptInfo] = await execute(
                `SELECT Ma_khung_gio, Trang_thai_lich_hen FROM lich_hen WHERE Ma_lich_hen = ? AND Ma_bac_si = ?`, 
                [appointmentID, maBacSi]
            );
            if (apptInfo.length === 0) throw new Error('Lịch hẹn không tồn tại.');

            const maKhungGio = apptInfo[0].Ma_khung_gio;
            const trangThaiCu = apptInfo[0].Trang_thai_lich_hen;

            if (status === 'cancelled' || status === 'reschedule_pending') {
                await execute(`UPDATE khung_gio_kham SET Trang_thai = 'available' WHERE Ma_khung_gio = ?`, [maKhungGio]);
            } else if (status === 'confirmed') {
                await execute(`UPDATE khung_gio_kham SET Trang_thai = 'booked' WHERE Ma_khung_gio = ?`, [maKhungGio]);
            }

            await execute(`UPDATE lich_hen SET Trang_thai_lich_hen = ? WHERE Ma_lich_hen = ?`, [status, appointmentID]);

            if (trangThaiCu !== status) {
                await execute(
                    `INSERT INTO lich_su_trang_thai_lich_hen (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Nguoi_thay_doi) VALUES (?, ?, ?, 'doctor')`, 
                    [appointmentID, trangThaiCu, status]
                );
            }

            return { success: true, message: "Đã cập nhật trạng thái lịch hẹn." };
        } catch (error) {
            throw new Error('Lỗi cập nhật trạng thái: ' + error.message);
        }
    }

    // Cập nhật trạng thái lịch hẹn sang 'done' và khung giờ khám sang 'available'
    static async updateAppointmentStatusDone(appointmentID, userID){
        try{
            const [doctorInfo] = await execute(`SELECT Ma_bac_si FROM bac_si WHERE Ma_nguoi_dung = ?`, [userID]);
            if (doctorInfo.length === 0) throw new Error('Không có quyền truy cập.');
            const maBacSi = doctorInfo[0].Ma_bac_si;

            const [apptInfo] = await execute(
                `SELECT Trang_thai_lich_hen, Ma_khung_gio FROM lich_hen WHERE Ma_lich_hen = ? AND Ma_bac_si = ?`, 
                [appointmentID, maBacSi]
            );
            
            if (apptInfo.length === 0) {
                throw new Error('Lịch hẹn không tồn tại hoặc không thuộc thẩm quyền của bạn.');
            }

            const trangThaiCu = apptInfo[0].Trang_thai_lich_hen;
            const maKhungGio = apptInfo[0].Ma_khung_gio; 

            const [result] = await execute(`UPDATE lich_hen SET Trang_thai_lich_hen = 'done' WHERE Ma_lich_hen = ?`, [appointmentID]);
            await execute(`UPDATE khung_gio_kham SET Trang_thai = 'available' WHERE Ma_khung_gio = ?`, [maKhungGio]);

            if (trangThaiCu !== 'done') {
                await execute(
                    `INSERT INTO lich_su_trang_thai_lich_hen 
                    (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Nguoi_thay_doi) 
                    VALUES (?, ?, 'done', 'doctor')`, 
                    [appointmentID, trangThaiCu]
                );
            }

            return result.affectedRows;
        }catch(error){
            throw new Error('Lỗi cập nhật trạng thái lịch hẹn: ' + error.message);
        }
    }

    // Cập nhật trạng thái lịch hẹn sang 'absent' và khung giờ khám sang 'available'
    static async updateAppointmentStatusAbsent(appointmentID, userID) {
        try {
            const [doctorInfo] = await execute(`SELECT Ma_bac_si FROM bac_si WHERE Ma_nguoi_dung = ?`, [userID]);
            if (doctorInfo.length === 0) throw new Error('Không có quyền truy cập.');
            const maBacSi = doctorInfo[0].Ma_bac_si;

            const [apptInfo] = await execute(
                `SELECT lh.Trang_thai_lich_hen, lh.Ma_khung_gio, kg.Thoi_gian_Bdau 
                 FROM lich_hen lh
                 JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio
                 WHERE lh.Ma_lich_hen = ? AND lh.Ma_bac_si = ?`, 
                [appointmentID, maBacSi]
            );
            
            if (apptInfo.length === 0) {
                throw new Error('Lịch hẹn không tồn tại hoặc không thuộc thẩm quyền của bạn.');
            }

            const trangThaiCu = apptInfo[0].Trang_thai_lich_hen;
            const maKhungGio = apptInfo[0].Ma_khung_gio;
            const startTime = new Date(apptInfo[0].Thoi_gian_Bdau);
            
            const now = new Date();
            const diffInMinutes = (now - startTime) / (1000 * 60);
            if (diffInMinutes < 15) {
                throw new Error('Chỉ được báo vắng sau khi giờ bắt đầu ca khám đã trôi qua tối thiểu 15 phút.');
            }

            if (trangThaiCu !== 'confirmed') {
                throw new Error('Chỉ có thể báo vắng cho những ca khám đã được xác nhận (confirmed).');
            }

            const [result] = await execute(`UPDATE lich_hen SET Trang_thai_lich_hen = 'absent' WHERE Ma_lich_hen = ?`, [appointmentID]);
            await execute(`UPDATE khung_gio_kham SET Trang_thai = 'available' WHERE Ma_khung_gio = ?`, [maKhungGio]);

            await execute(
                `INSERT INTO lich_su_trang_thai_lich_hen 
                (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Nguoi_thay_doi) 
                VALUES (?, 'confirmed', 'absent', 'doctor')`, 
                [appointmentID]
            );

            return result.affectedRows;
        } catch (error) {
            throw new Error(error.message);
        }
    }

    // Lấy tất cả lịch hẹn của một bác sĩ
    static async getAllDoctorAppointments(userID, status = 'all', date = 'all', search = '') {
        try {
            const [doctorInfo] = await execute(`SELECT Ma_bac_si FROM bac_si WHERE Ma_nguoi_dung = ?`, [userID]);
            if (doctorInfo.length === 0) throw new Error('Tài khoản này không phải là bác sĩ.');
            const maBacSi = doctorInfo[0].Ma_bac_si;

            let sql = `
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
            `;
            
            const params = [maBacSi];

            // Điều kiện lọc trạng thái
            if (status && status !== 'all') {
                sql += ` AND lh.Trang_thai_lich_hen = ?`;
                params.push(status);
            }

            // Điều kiện lọc ngày
            if (date && date !== 'all') {
                sql += ` AND DATE(kg.Thoi_gian_Bdau) = ?`;
                params.push(date);
            }

            // Điều kiện tìm kiếm (Theo Tên Bệnh Nhân hoặc Mã Booking)
            if (search && search.trim() !== '') {
                sql += ` 
                    AND (
                        nd.Ten_nguoi_dung LIKE ? 
                        OR lh.Ma_booking LIKE ?
                        OR EXISTS (
                            SELECT 1 FROM nguoi_than nt WHERE nt.Ma_nguoi_than = lh.Ma_nguoi_than AND nt.Ten_nguoi_than LIKE ?
                        )
                    )
                `;
                const searchParam = `%${search.trim()}%`;
                params.push(searchParam, searchParam, searchParam);
            }

            sql += `
                GROUP BY lh.Ma_lich_hen
                ORDER BY kg.Thoi_gian_Bdau DESC
            `;
            
            const [list] = await execute(sql, params);
            return list;
        } catch (error) {
            throw new Error('Lỗi truy vấn danh sách lịch hẹn bác sĩ: ' + error.message);
        }
    }

    // Lấy thông tin lịch hẹn để dời lịch
    static async getAppointmentForReschedule(appointmentID) {
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

    // Lấy chi tiết lịch hẹn của bác sĩ dựa trên Ma_lich_hen
    static async getDoctorAppointmentDetail(appointmentID) {
        try {
            const sqlLichHen = `
                SELECT 
                    lh.Ma_lich_hen,
                    lh.Ma_benh_nhan,
                    lh.Ma_nguoi_than,
                    lh.Ma_booking AS bookingCode,
                    lh.Hinh_thuc AS type,
                    lh.Trang_thai_lich_hen AS status,
                    lh.Trieu_chung AS symptoms,
                    lh.Link_video_call AS linkVideoCall,
                    kg.Thoi_gian_Bdau AS startTime,
                    kg.Thoi_gian_Kthuc AS endTime,
                    nd_bn.Ma_nguoi_dung,
                    nd_bn.Ten_nguoi_dung,
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
                    bn.Nhom_mau AS bloodType,
                    bn.Di_ung AS allergies,
                    bn.Benh_nen AS backgroundDiseases,
                    IF(lh.Ma_nguoi_than IS NOT NULL, 1, 0) AS isRelative,
                    nd_bn.Ten_nguoi_dung AS contactName,
                    nd_bn.Dien_thoai AS contactPhone,
                    nt.Quan_he AS relationship,
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

            appointmentData.bloodType = appointmentData.bloodType ? decrypt(appointmentData.bloodType) : null;
            appointmentData.allergies = appointmentData.allergies ? decrypt(appointmentData.allergies) : null;
            appointmentData.backgroundDiseases = appointmentData.backgroundDiseases ? decrypt(appointmentData.backgroundDiseases) : null;

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

    // Lấy lịch sử bệnh án của bệnh nhân dựa trên Ma_benh_nhan và Ma_nguoi_than
    static async getMedicalHistory(maBenhNhan, maNguoiThan) {
        try {
            const sql = `
                SELECT 
                    lh.Ma_lich_hen,
                    lh.Ma_booking,
                    lh.Trieu_chung,
                    kg.Thoi_gian_Bdau AS Ngay_kham,
                    dt.Chuan_doan_benh,
                    nd_bs.Ten_nguoi_dung AS Ten_bac_si,
                    GROUP_CONCAT(CONCAT(ctdt.Ten_thuoc, ' (', ctdt.So_luong, ')') SEPARATOR '; ') AS Danh_sach_thuoc
                FROM lich_hen lh
                INNER JOIN khung_gio_kham kg ON lh.Ma_khung_gio = kg.Ma_khung_gio 
                INNER JOIN bac_si bs ON lh.Ma_bac_si = bs.Ma_bac_si
                INNER JOIN nguoi_dung nd_bs ON bs.Ma_nguoi_dung = nd_bs.Ma_nguoi_dung
                LEFT JOIN don_thuoc dt ON lh.Ma_lich_hen = dt.Ma_lich_hen
                LEFT JOIN chi_tiet_dthuoc ctdt ON dt.Ma_don_thuoc = ctdt.Ma_don_thuoc
                WHERE 
                    lh.Ma_benh_nhan = ? 
                    AND lh.Ma_nguoi_than <=> ?  
                    AND lh.Trang_thai_lich_hen = 'done'
                GROUP BY 
                    lh.Ma_lich_hen,
                    lh.Ma_booking,
                    lh.Trieu_chung,
                    kg.Thoi_gian_Bdau,
                    dt.Chuan_doan_benh,
                    nd_bs.Ten_nguoi_dung
                ORDER BY kg.Thoi_gian_Bdau DESC
            `;

            const [rows] = await execute(sql, [maBenhNhan, maNguoiThan || null]);
            return rows;
        } catch (error) {
            console.error("Lỗi getMedicalHistory:", error); 
            throw new Error('Lỗi truy vấn lịch sử bệnh án: ' + error.message);
        }
    }

    // Hoàn thành lịch hẹn và tạo đơn thuốc
    static async completeAndPrescribe(appointmentID, userID, prescriptionData) {
        try {
            const { chuanDoan, ngayTaiKham, danhSachThuoc } = prescriptionData;

            const [doctorInfo] = await execute(`SELECT Ma_bac_si FROM bac_si WHERE Ma_nguoi_dung = ?`, [userID]);
            if (doctorInfo.length === 0) throw new Error('Không có quyền truy cập.');
            const maBacSi = doctorInfo[0].Ma_bac_si;

            const [apptInfo] = await execute(
                `SELECT Trang_thai_lich_hen, Ma_khung_gio FROM lich_hen WHERE Ma_lich_hen = ? AND Ma_bac_si = ?`, 
                [appointmentID, maBacSi]
            );
            
            if (apptInfo.length === 0) throw new Error('Lịch hẹn không tồn tại hoặc không thuộc quyền.');
            const trangThaiCu = apptInfo[0].Trang_thai_lich_hen;
            const maKhungGio = apptInfo[0].Ma_khung_gio;

            if (trangThaiCu !== 'confirmed') throw new Error('Chỉ có thể khám và kê đơn cho lịch hẹn đã được duyệt.');

            await execute(`UPDATE lich_hen SET Trang_thai_lich_hen = 'done' WHERE Ma_lich_hen = ?`, [appointmentID]);
            await execute(`UPDATE khung_gio_kham SET Trang_thai = 'available' WHERE Ma_khung_gio = ?`, [maKhungGio]);
            await execute(
                `INSERT INTO lich_su_trang_thai_lich_hen (Ma_lich_hen, Trang_thai_cu, Trang_thai_moi, Nguoi_thay_doi) VALUES (?, ?, 'done', 'doctor')`, 
                [appointmentID, trangThaiCu]
            );

            const sqlDonThuoc = `INSERT INTO don_thuoc (Ma_lich_hen, Chuan_doan_benh, Ngay_tai_kham) VALUES (?, ?, ?)`;
            const [resDonThuoc] = await execute(sqlDonThuoc, [appointmentID, chuanDoan, ngayTaiKham || null]);
            const maDonThuoc = resDonThuoc.insertId;

            if (danhSachThuoc && Array.isArray(danhSachThuoc) && danhSachThuoc.length > 0) {
                for (const thuoc of danhSachThuoc) {
                    await execute(
                        `INSERT INTO chi_tiet_dthuoc (Ma_don_thuoc, Ten_thuoc, So_luong, Lieu_dung) VALUES (?, ?, ?, ?)`,
                        [maDonThuoc, thuoc.tenThuoc, thuoc.soLuong, thuoc.lieuDung]
                    );
                }
            }

            return true;
        } catch (error) {
            throw new Error('Lỗi hoàn thành và kê đơn: ' + error.message);
        }
    }

    // Lấy chi tiết đơn thuốc dựa trên Ma_lich_hen
    static async getPrescriptionByAppointmentId(appointmentID) {
        try {
            const sqlDonThuoc = `SELECT Ma_don_thuoc, Chuan_doan_benh, Ngay_tai_kham, Ngay_tao FROM don_thuoc WHERE Ma_lich_hen = ?`;
            const [donThuocArr] = await execute(sqlDonThuoc, [appointmentID]);

            if (donThuocArr.length === 0) return null; 

            const donThuoc = donThuocArr[0];

            const sqlChiTiet = `SELECT Ten_thuoc, So_luong, Lieu_dung FROM chi_tiet_dthuoc WHERE Ma_don_thuoc = ?`;
            const [chiTietArr] = await execute(sqlChiTiet, [donThuoc.Ma_don_thuoc]);

            return {
                ...donThuoc,
                Danh_sach_thuoc: chiTietArr 
            };
        } catch (error) {
            throw new Error('Lỗi truy vấn chi tiết đơn thuốc: ' + error.message);
        }
    }
}