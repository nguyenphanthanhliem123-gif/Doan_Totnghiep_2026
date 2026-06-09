import { execute } from "../config/db.js";

export default class profileModel{
    static async getAll(){
        try{
            const [row] = await execute(
                `SELECT
                    Ma_nguoi_dung,
                    Ten_nguoi_dung,
                    Email,
                    Dien_thoai,
                    Dang_nhap_Oauth,
                    Ma_DN_Oauth,
                    Phan_quyen,
                    Anh_dai_dien,
                    Ngay_tao,
                    Ngay_cap_nhat,
                    Trang_thai
                FROM
                    nguoi_dung
                WHERE Ma_nguoi_dung = ? LIMIT 1`)
            if(row.length < 1) throw new Error('Không có người dùng nào');
            return row;
        }
        catch(error){
            throw new Error('Lỗi database(profileModel.getAll): ' + error.message);
        }
    }

    static async getProfileByMaNguoiDung(ma_nguoi_dung){
        try{
            const [profile] = await execute(
                `SELECT
                    Ma_nguoi_dung,
                    Ten_nguoi_dung,
                    Email,
                    Dien_thoai,
                    Dang_nhap_Oauth,
                    Ma_DN_Oauth,
                    Phan_quyen,
                    Anh_dai_dien,
                    Ngay_tao,
                    Ngay_cap_nhat,
                    Trang_thai
                FROM
                    nguoi_dung
                WHERE Ma_nguoi_dung = ? LIMIT 1`, 
            [ma_nguoi_dung]);
            if(profile.length < 1) throw new Error('Không tìm thấy người dùng này');
            return profile[0] ?? null;
        }
        catch(error){
            throw new Error('Lỗi database(profileModel.getProfileByMaNguoiDung): ' + error.message);
        }
    }
}