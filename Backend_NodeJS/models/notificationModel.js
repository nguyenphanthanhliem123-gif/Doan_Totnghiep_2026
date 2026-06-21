import { execute } from "../config/db.js";

export default class NotificationModel{
    static async getAllNotification(userID){
        try{
            const [rows] = await execute(
                `SELECT *
                FROM thong_bao
                where Ma_nguoi_dung = ?`,[userID]
            );
            return rows.length > 0? rows: [];
        }catch(error){
            throw new Error("Lỗi NotificationModel.getAllNotification: " + error.message);
        }
    }

    static async updateStatus(notificationID, userID){
        try{

            const queryCheck = `
                SELECT *
                FROM thong_bao
                WHERE Ma_nguoi_dung = ? AND Ma_thong_bao = ?
            `;

            const [resultCheck] = await execute(queryCheck,[notificationID, userID]);

            if(!(resultCheck.length > 0)) throw new Error("Thông báo này không thuộc về bạn");

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