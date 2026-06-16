import profileModel from "../models/ProfileModel.js";

export default class profileController{
    static async getAll(req,res){
        try{
            const users = await profileModel.getAll();

            return res.status(200).json({
                succeeded: true,
                users: users
            });
        }
        catch(error){
            return res.status(500).json({
                message: 'Lỗi server ' + error.message,
                succeeded: false,
            });
        }
    }
    static async getProfileByMaNguoiDung(req,res){
        try{
            const {Ma_nguoi_dung} = req.params;
            if(Ma_nguoi_dung < 1) return res.status(400).json({message: 'Mã người dùng không hợp lệ', succeeded: false});
            const result = await profileModel.getProfileByMaNguoiDung(Ma_nguoi_dung);
            if(!result) return res.status(404).json({message: 'Không tìm thấy người dùng này', succeeded: false});
            return res.status(200).json({user: result, succeeded: true});
        }
        catch(error){
            return res.status(500).json({
                succeeded: false,
                message: 'Lỗi server(profileController.getProfileByMaNguoiDung): ' +error.message
            });
        }
    }

    static async updateProfile(req,res){
        try{
            const {fullName, birthDay, gender, address, avatar, phone} = req.body;
            const userId = req.Ma_nguoi_dung;

            const result = await profileModel.updateProfile(fullName, birthDay, gender, address, avatar, phone, userId);

            if(result) return res.status(200).json({
                succeeded: true,
            });
        }
        catch(error){
            return res.status(500).json({
                succeeded: false,
                message: "Lỗi cập nhật hồ sơ người dùng(profileController.updateProfile): "+error.message
            });
        }
    }
}