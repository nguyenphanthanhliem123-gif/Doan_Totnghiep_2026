import NotificationModel from "../models/notificationModel.js";

export default class NotificationController{
    static async getAllNotification(req,res){
        try{
            const userID = req.Ma_nguoi_dung;

            const rows = await NotificationModel.getAllNotification(userID);

            return res.status(200).json({
                succeeded: true,
                notifications: rows
            });
        }
        catch(error){
            return res.status(500).json({
                succeeded: false,
                message: error.message 
            });
        }
    }

    static async getNotificationUnRead(req,res){
        try{
            const userID = req.Ma_nguoi_dung;

            const notiUnRead = await NotificationModel.getNotificationsUnRead(userID);

            return res.status(200).json({
                succeeded: true,
                count: notiUnRead
            });
        }catch(error){
            return res.status(500).json({
                succeeded: false,
                message: error.message
            });
        }
    }

    static async updateStatus(req,res){
       try{
            const {notificationID} = req.params;
            const userID = req.Ma_nguoi_dung;

            if(!notificationID) return res.status(400).json({
                succeeded:false,
                message: "Thiếu mã thông báo"
            });

            const result = await NotificationModel.updateStatus(notificationID, userID);

            return res.status(200).json({
                succeeded: true
            });
        }
        catch(error){
            return res.status(500).json({
                succeeded:false,
                message: error.message
            });
        }
    }
}