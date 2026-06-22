import { beginTransaction, commitTransaction, execute, rollbackTransaction } from "../config/db.js";


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
            console.log('==== DEBUG ====');
            console.log(ma_nguoi_dung);
            const [profile] = await execute(
                `SELECT
                    nd.Ma_nguoi_dung,
                    nd.Ten_nguoi_dung,
                    nd.Email,
                    nd.Dien_thoai,
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
                    -- ✅ 1. Dùng LEFT JOIN để nếu bảng benh_nhan bị trống thì vẫn lấy được nguoi_dung
                    LEFT JOIN benh_nhan bn ON nd.Ma_nguoi_dung = bn.Ma_nguoi_dung
                    
                    -- ✅ 2. BẮT BUỘC đưa điều kiện Quan_he lên trên mệnh đề ON (dùng AND)
                    -- Tuyệt đối không đưa xuống mệnh đề WHERE bên dưới.
                    LEFT JOIN nguoi_than nt ON bn.Ma_benh_nhan = nt.Ma_benh_nhan AND nt.Quan_he = 'bản thân'
                    
                    WHERE nd.Ma_nguoi_dung = ? 
                    LIMIT 1;`, 
            [ma_nguoi_dung]);
            
            // Thay vì check length < 1 rồi quăng lỗi chung chung, ta kiểm tra xem có dòng dữ liệu nào không
            if(profile.length < 1) throw new Error('Tài khoản này không tồn tại trên hệ thống.');
            
            return profile[0] ?? null;
        }
        catch(error){
            throw new Error('Lỗi database(profileModel.getProfileByMaNguoiDung): ' + error.message);
        }
    }

    static async updateProfile(fullName, birthDay, gender, address, avatar, phone, userID){
        let conn;
        
        console.log("==== DEBUG THÔNG TIN GỬI LÊN ====");
        console.log("=== fullName: ", fullName);
        console.log("=== birthDay: ", birthDay);
        console.log("=== gender: ", gender);
        console.log("=== address: ", address);
        console.log("=== avatar: ", avatar);
        console.log("=== phone: ", phone);
        console.log("=== userID: ", userID);

        try {

            conn = await beginTransaction();

            const safeFullName = fullName ?? null;
            const safeBirthDay = birthDay ?? null;
            const safeGender = gender ?? null;
            const safeAddress = address ?? null;
            const safeAvatar = avatar ?? null;
            const safePhone = phone ?? null;

            const sqlNguoiDung = `
                UPDATE nguoi_dung 
                SET Ten_nguoi_dung = ?, Anh_dai_dien = ?, Dien_thoai = ?
                WHERE Ma_nguoi_dung = ?
            `;
            await conn.execute(sqlNguoiDung, [safeFullName, safeAvatar, safePhone, userID]);


            const sqlBenhNhan = `
                UPDATE benh_nhan 
                SET Ngay_sinh = ?, Gioi_tinh = ?, Dia_chi = ? 
                WHERE Ma_nguoi_dung = ?
                ORDER BY Ma_nguoi_dung ASC
                LIMIT 1
            `;
            await conn.execute(sqlBenhNhan, [safeBirthDay, safeGender, safeAddress, userID]);


            await commitTransaction(conn);

            return true;
        } catch (error) {

            if (conn) {
                await rollbackTransaction(conn);
            }
            throw new Error('Lỗi database(profileModel.updateProfile): ' + error.message);
        }
    }
}