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
            //console.log(ma_nguoi_dung);
            const [profile] = await execute(
                `SELECT
                    nd.Ma_nguoi_dung,
                    nd.Ten_nguoi_dung,
                    nd.Email,
                    nd.Dang_nhap_Oauth,
                    nd.Ma_DN_Oauth,
                    nd.Phan_quyen,
                    nd.Anh_dai_dien,
                    nd.Ngay_tao,
                    nd.Ngay_cap_nhat,
                    nd.Trang_thai,

                    bn.Ma_benh_nhan,
                    bn.Ngay_sinh,
                    bn.Gioi_tinh,
                    bn.Dia_chi,
                    bn.Xac_minh_dien_thoai,
                    bn.Nhom_mau,
                    bn.Di_ung,
                    bn.Benh_nen

                    FROM nguoi_dung nd
                    LEFT JOIN benh_nhan bn ON bn.Ma_nguoi_dung = nd.Ma_nguoi_dung
                    WHERE nd.Ma_nguoi_dung = ?`, 
            [ma_nguoi_dung]);
            if(profile.length < 1) throw new Error('Không tìm thấy người dùng này');
            return profile[0] ?? null;
        }
        catch(error){
            throw new Error('Lỗi database(profileModel.getProfileByMaNguoiDung): ' + error.message);
        }
    }
}