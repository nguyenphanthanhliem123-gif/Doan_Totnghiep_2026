import { execute, beginTransaction, commitTransaction, rollbackTransaction } from "../config/db.js";
import sendNotification from "../utils/notificationHelper.js";

export default class ReportModel {
    // 1. Lấy danh sách tất cả khiếu nại (Kèm tên người dùng từ bảng nguoi_dung)
    static async getAllReports() {
        try{
            // Giả định reporter_id và reported_id đều tham chiếu đến Ma_nguoi_dung
            const sql = `
                SELECT 
                    c.*, 
                    ng.Ten_nguoi_dung AS reporter_name, ng.Email AS reporter_email,
                    nb.Ten_nguoi_dung AS reported_name, nb.Email AS reported_email,
                    nb.Trang_thai AS reported_status
                FROM complaints c
                LEFT JOIN nguoi_dung ng ON c.reporter_id = ng.Ma_nguoi_dung
                LEFT JOIN nguoi_dung nb ON c.target_id = nb.Ma_nguoi_dung
                ORDER BY c.created_at DESC
            `;
            const [rows] = await execute(sql);
            return rows;
        }catch(error){
            throw new Error("Lỗi lấy tất cả khiếu nại: " + error.message);
        }
    }

    // 2. Xử lý khiếu nại (Admin)
    static async resolveReport(reportId, action, adminNote, targetUserId, adminId, io) {
        let conn = await beginTransaction();
        try {
            let finalStatus = 'resolved'; // Trạng thái của case
            if (action === 'bo_qua') {
                finalStatus = 'dismissed';
            }

            // Cập nhật bảng complaints
            await conn.execute(`
                UPDATE complaints 
                SET status = ?, resolution_note = ?, resolved_by = ?, resolved_at = NOW()
                WHERE id = ?
            `, [finalStatus, adminNote, adminId, reportId]);

            // Nếu Admin chọn KHÓA TÀI KHOẢN (status = 2)
            if (action === 'khoa') {
                await conn.execute(`
                    UPDATE nguoi_dung SET Trang_thai = 2 WHERE Ma_nguoi_dung = ?
                `, [targetUserId]);

                // Lưu log cho Admin
                await conn.execute(`
                    INSERT INTO admin_logs (admin_id, action, target_type, target_id, reason, created_at) 
                    VALUES (?, 'KHOA_TU_KHIEU_NAI', 'USER', ?, ?, NOW())
                `, [adminId, targetUserId, adminNote]);
            }

            if(action === 'canh_cao'){
                await sendNotification(
                    targetUserId,
                    "Cảnh cáo",
                    "Tài khoản bị cảnh cáo do vi phạm tiêu chuẩn cộng đồng, nếu tái diễn sẽ bị khóa vĩnh viễn.",
                    io
                )
            }

            await commitTransaction(conn);
            return true;
        } catch (error) {
            await rollbackTransaction(conn);
            throw error;
        }
    }

    static async createReport(userId, reportedId, reportedType, reason) {
        try {
            const reporter_type = reportedType == 'Patient' ? 'Doctor' : 'Patient';

            const sql = `
                INSERT INTO complaints (reporter_type, reporter_id, target_type, target_id, content, status)
                VALUES (?, ?, ?, ?, ?, 'open')
            `;
            
            await execute(sql, [reporter_type ,userId, reportedType, reportedId, reason]);

            return true;
        } catch (error) {
            throw new Error("Lỗi tạo report: " + error.message);
        }
    }
}