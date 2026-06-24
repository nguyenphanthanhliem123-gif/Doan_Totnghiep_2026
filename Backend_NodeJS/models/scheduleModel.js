// Backend_NodeJS/models/scheduleModel.js
import { execute } from "../config/db.js";

export default class ScheduleModel {
    // Lưu hoặc cập nhật cấu hình thời gian
    static async saveConfig(doctorId, slotTime, breakTime, maxPatients) {
        try{
            const sql = `
                INSERT INTO cau_hinh_lich_kham (Ma_bac_si, Thoi_gian_slot, Thoi_gian_nghi, So_benh_nhan_max)
                VALUES (?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE Thoi_gian_slot = ?, Thoi_gian_nghi = ?, So_benh_nhan_max = ?
            `;
            await execute(sql, [doctorId, slotTime, breakTime, maxPatients, slotTime, breakTime, maxPatients]);
        }catch(error){
            throw new Error('Lỗi lưu cấu hình thời gian: ' + error.message);
        }
    }

    // Lưu/Cập nhật lịch làm việc cố định cho từng buổi
    static async saveWeeklySchedule(doctorId, weeklyData) {
        try{
            // weeklyData là mảng các đối tượng: [{ thu, buoi, gio_bat_dau, gio_ket_thuc, trang_thai }]
            const sql = `
                INSERT INTO lich_lam_viec_co_dinh (Ma_bac_si, Thu_trong_tuan, Buoi, Gio_bat_dau, Gio_ket_thuc, Trang_thai)
                VALUES (?, ?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE Gio_bat_dau = ?, Gio_ket_thuc = ?, Trang_thai = ?
            `;
            
            for (let item of weeklyData) {
                await execute(sql, [
                    doctorId, item.thu, item.buoi, item.gio_bat_dau, item.gio_ket_thuc, item.trang_thai,
                    item.gio_bat_dau, item.gio_ket_thuc, item.trang_thai
                ]);
            }
        }catch(error){
            throw new Error('Lỗi lưu lịch làm việc cố định: ' + error.message);
        }
    }

    // Lấy toàn bộ cấu hình lịch của bác sĩ
    static async getDoctorScheduleConfig(doctorId) {
        try{
            const [config] = await execute(`SELECT * FROM cau_hinh_lich_kham WHERE Ma_bac_si = ?`, [doctorId]);
            const [weekly] = await execute(`SELECT * FROM lich_lam_viec_co_dinh WHERE Ma_bac_si = ?`, [doctorId]);
            return {
                config: config[0] || { Thoi_gian_slot: 20, Thoi_gian_nghi: 5, So_benh_nhan_max: 30 },
                weeklySchedule: weekly
            };
        }catch(error){
            throw new Error('Lỗi lấy cấu hình lịch của bác sĩ: ' + error.message);
        }
    }

    static async generateSlotsForDateRange(doctorId, startDateStr, endDateStr) {
        try {
            // 1. Lấy thông số cấu hình thời gian của bác sĩ
            const [configRows] = await execute(
                `SELECT Thoi_gian_slot, Thoi_gian_nghi FROM cau_hinh_lich_kham WHERE Ma_bac_si = ?`, 
                [doctorId]
            );
            if (!configRows || configRows.length === 0) {
                throw new Error("Bác sĩ chưa thiết lập cấu hình thời gian (slot/nghỉ).");
            }
            const { Thoi_gian_slot: slotTime, Thoi_gian_nghi: breakTime } = configRows[0];

            // 2. Lấy danh sách các buổi đăng ký làm việc cố định ('lam')
            const [weeklySchedule] = await execute(
                `SELECT Thu_trong_tuan, Gio_bat_dau, Gio_ket_thuc FROM lich_lam_viec_co_dinh WHERE Ma_bac_si = ? AND Trang_thai = 'lam'`, 
                [doctorId]
            );
            if (weeklySchedule.length === 0) return { message: "Không có buổi làm việc nào được cấu hình trạng thái làm." };

            // 3. Lấy mã phòng khám chính của bác sĩ để điền vào khung giờ
            const [clinicRows] = await execute(
                `SELECT Ma_phong_kham FROM bac_si_phong_kham WHERE Ma_bac_si = ? ORDER BY Noi_chinh DESC LIMIT 1`,
                [doctorId]
            );
            if (!clinicRows || clinicRows.length === 0) {
                throw new Error("Bác sĩ chưa được phân bổ vào phòng khám nào.");
            }
            const clinicId = clinicRows[0].Ma_phong_kham;

            // Helper chuyển đổi "HH:mm:ss" thành số phút tổng
            const timeToMinutes = (timeStr) => {
                const [h, m] = timeStr.split(':').map(Number);
                return h * 60 + m;
            };

            // Helper chuyển đổi số phút tổng ngược lại thành "HH:mm:00"
            const minutesToTimeStr = (totalMinutes) => {
                const h = Math.floor(totalMinutes / 60).toString().padStart(2, '0');
                const m = (totalMinutes % 60).toString().padStart(2, '0');
                return `${h}:${m}:00`;
            };

            // 4. Tiến hành duyệt từng ngày trong khoảng từ ngày bắt đầu đến ngày kết thúc
            let current = new Date(startDateStr);
            const end = new Date(endDateStr);
            let slotsCreatedCount = 0;

            while (current <= end) {
                // Định dạng chuỗi ngày YYYY-MM-DD an toàn, tránh lệch múi giờ
                const yyyy = current.getFullYear();
                const mm = String(current.getMonth() + 1).padStart(2, '0');
                const dd = String(current.getDate()).padStart(2, '0');
                const dateStr = `${yyyy}-${mm}-${dd}`;

                // Xác định Thứ trong tuần theo DB của bạn (0 -> 8, 1 -> 2, ..., 6 -> 7)
                const dayOfWeek = current.getDay(); 
                const dbThu = dayOfWeek === 0 ? 8 : dayOfWeek + 1;

                // Lọc ra các buổi làm việc tương ứng với Thứ hiện tại
                const todaySessions = weeklySchedule.filter(item => item.Thu_trong_tuan === dbThu);

                for (const session of todaySessions) {
                    let startMin = timeToMinutes(session.Gio_bat_dau);
                    const endMin = timeToMinutes(session.Gio_ket_thuc);

                    // Cắt nhỏ thời gian thành từng slot
                    while (startMin + slotTime <= endMin) {
                        const slotStartStr = `${dateStr} ${minutesToTimeStr(startMin)}`;
                        const slotEndStr = `${dateStr} ${minutesToTimeStr(startMin + slotTime)}`;

                        // 5. Kiểm tra xem khung giờ này đã được tạo trước đó chưa
                        const [existing] = await execute(
                            `SELECT 1 FROM khung_gio_kham WHERE Ma_bac_si = ? AND Thoi_gian_Bdau = ? AND Thoi_gian_Kthuc = ? LIMIT 1`,
                            [doctorId, slotStartStr, slotEndStr]
                        );

                        if (!existing || existing.length === 0) {
                            // Tiến hành thêm khung giờ mới vào DB
                            await execute(
                                `INSERT INTO khung_gio_kham (Ma_bac_si, Ma_phong_kham, Thoi_gian_Bdau, Thoi_gian_Kthuc, Trang_thai)
                                 VALUES (?, ?, ?, ?, 'available')`,
                                [doctorId, clinicId, slotStartStr, slotEndStr]
                            );
                            slotsCreatedCount++;
                        }

                        // Nhảy cóc qua slot tiếp theo = kết thúc slot cũ + thời gian nghỉ giữa các ca
                        startMin += slotTime + breakTime;
                    }
                }

                // Tăng lên 1 ngày cho vòng lặp kế tiếp
                current.setDate(current.getDate() + 1);
            }

            return { succeeded: true, slotsCreated: slotsCreatedCount };
        } catch (error) {
            throw new Error('Lỗi tự động phát sinh khung giờ khám: ' + error.message);
        }
    }

    static async registerSuddenLeaveWithoutDBChange(doctorId, dateStr, buoi, reason) {
        try {
            // Khởi tạo điều kiện lọc theo Giờ của Buổi nghỉ
            let hourCondition = "";
            if (buoi === 'sang') hourCondition = "AND HOUR(Thoi_gian_Bdau) < 12";
            else if (buoi === 'chieu') hourCondition = "AND HOUR(Thoi_gian_Bdau) >= 12 AND HOUR(Thoi_gian_Bdau) < 18";
            else if (buoi === 'toi') hourCondition = "AND HOUR(Thoi_gian_Bdau) >= 18";

            // LỆNH 1: Khóa thẳng các slot trống (chuyển available -> locked)
            const [lockResult] = await execute(
                `UPDATE khung_gio_kham 
                 SET Trang_thai = 'locked' 
                 WHERE Ma_bac_si = ? AND DATE(Thoi_gian_Bdau) = ? ${hourCondition} AND Trang_thai = 'available'`,
                [doctorId, dateStr]
            );

            // LỆNH 2: Tìm các ca đã bị bệnh nhân đặt trước ('booked') để xử lý hủy
            const [bookedSlots] = await execute(
                `SELECT Ma_khung_gio FROM khung_gio_kham 
                 WHERE Ma_bac_si = ? AND DATE(Thoi_gian_Bdau) = ? ${hourCondition} AND Trang_thai = 'booked'`,
                [doctorId, dateStr]
            );

            let cancelledCount = 0;
            // Nếu có lịch hẹn bị ảnh hưởng, tiến hành hủy lịch của bệnh nhân
            if (bookedSlots && bookedSlots.length > 0) {
                const slotIds = bookedSlots.map(s => s.Ma_khung_gio);
                
                // Cập nhật trạng thái lịch hẹn sang 'da_huy' và đính kèm lý do vào 'Ghi_chu' có sẵn
                const [appointmentResult] = await execute(
                    `UPDATE lich_hen 
                     SET Trang_thai = 'da_huy', Ghi_chu = ? 
                     WHERE Ma_khung_gio IN (${slotIds.join(',')}) AND Trang_thai != 'da_huy'`,
                    [`Bác sĩ báo nghỉ đột xuất: ${reason || 'Không có lý do cụ thể.'}`]
                );
                
                // Đồng thời chuyển luôn các slot 'booked' này thành 'locked' để đóng ca khám
                await execute(
                    `UPDATE khung_gio_kham SET Trang_thai = 'locked' WHERE Ma_khung_gio IN (${slotIds.join(',')})`
                );
                
                cancelledCount = appointmentResult.affectedRows || 0;
            }

            return { 
                succeeded: true, 
                slotsLocked: lockResult.affectedRows || 0,
                appointmentsCancelled: cancelledCount 
            };
        } catch (error) {
            throw new Error('Lỗi khóa lịch: ' + error.message);
        }
    }
}