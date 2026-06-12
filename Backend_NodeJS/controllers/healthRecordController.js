import healthRecordModel from "../models/HealthRecordModel.js";
import { decrypt } from "../utils/cryptoUtil.js";

export default class healthRecordController{
    static async getAllHealthRecordByUserID(req,res){
        try{
            const userID = req.Ma_nguoi_dung;
            const healthRecords = await healthRecordModel.getAllHealthRecordByUserID(userID);

            const decryptedRows = healthRecords.map(row => {
                return{
                    ...row,
                    Nhom_mau: decrypt(row.Nhom_mau),
                    Di_ung: decrypt(row.Di_ung),
                    Benh_nen: decrypt(row.Benh_nen)
                };
            });

            return res.status(200).json({succeeded: true, healthRecords: decryptedRows});
        }catch(error){
            return res.status(500).json({succeeded: false, message: "Lỗi lấy tất cả hồ sơ sức khỏe của tài khoản: " + error.message});
        }
    }

    static async addRelativeProfile(req,res){
        try{
            const userID = req.Ma_nguoi_dung;
            const {tenNguoiThan, moiQuanHe, birthDay, gender, address, nhomMau, diUng, benhNen} = req.body;

            if(!tenNguoiThan || !moiQuanHe || !birthDay || !gender || !address) return res.status(400).json({
                succeeded: false,
                message: "Không được bỏ trống các thông tin họ tên, ngày sinh, địa chỉ"
            });



            const result = await healthRecordModel.addRelativeProfile(userID, tenNguoiThan, moiQuanHe, birthDay, gender, address, nhomMau ?? null, diUng ?? null, benhNen ?? null);

            if(!result) return res.status(500).json({succeeded: false, message: "Thêm hồ sơ sức khỏe thất bại: " + result});

            return res.status(200).json({
                succeeded: true,
            });
        }
        catch(error){
            return res.status(500).json({succeeded: false, message: "Thêm hồ sơ sức khỏe thất bại: " + error.message});
        }
    }
}