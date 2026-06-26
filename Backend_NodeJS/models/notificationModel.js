import { execute } from "../config/db.js";

export default class NotificationModel{
    static async getAllNotification(userID){
        try{
            const [rows] = await execute(
                `SELECT *
                FROM thong_bao
                WHERE Ma_nguoi_dung = ?
                ORDER BY Ngay_gui DESC`,[userID]
            );
            return rows.length > 0? rows: [];
        }catch(error){
            throw new Error("Lỗi NotificationModel.getAllNotification: " + error.message);
        }
    }

    static async getNotificationsUnRead(userID){
        try{
            const sql = `
                SELECT COUNT(*) AS total
                FROM thong_bao
                WHERE Ma_nguoi_dung = ? AND Trang_thai_doc = 0
            `;

            const [result] = await execute(sql, [userID]);

            return result[0].total;
        }catch(error){
            throw new Error("Lỗi NotificationModel.getNotificationsUnRead: " + error.message);
        }
    }

    static async updateStatus(notificationID, userID){
        try{

            const queryCheck = `
                SELECT *
                FROM thong_bao
                WHERE Ma_nguoi_dung = ? AND Ma_thong_bao = ?
            `;

            const [resultCheck] = await execute(queryCheck,[ userID, notificationID]);

            if(resultCheck.length < 1) throw new Error("Thông báo này không thuộc về bạn");

            const query = `
                UPDATE thong_bao
                SET Trang_thai_doc = 1
                WHERE Ma_thong_bao = ?
            `;

            const result = await execute(query,[notificationID]);

            return result.affectedRows;
        }
        catch(error){
            throw new Error('Lỗi NotificationModel.updateStatus: ' + error.message);
        }
    }
}