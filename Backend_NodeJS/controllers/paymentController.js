import paymentModel from "../models/paymentModel.js";

export default class paymentController{
    static async getPaymentHistory(req,res){
        try{
            const userID = req.Ma_nguoi_dung;

            const result = await paymentModel.getPaymentHistory(userID);

            return res.status(200).json({
                succeeded: true,
                paymentHistory: result
            });
        }
        catch(error){
            return res.status(500).json({
                succeeded: false,
                message: "Lỗi server " + error.message
            });
        }
    }
}