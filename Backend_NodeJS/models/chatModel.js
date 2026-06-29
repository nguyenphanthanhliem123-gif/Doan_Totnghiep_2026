import { execute } from "../config/db.js";
import { v4 as uuidv4 } from 'uuid';

export default class ChatModel{
    static async createSession(maNguoiDung, sessionToken, chuDe){
        try{
            const jsonChuDe = JSON.stringify(chuDe || "Cuộc trò chuyện mới");
            const sql = `
                INSERT INTO phien_hoi_thoai (Ma_nguoi_dung, Session_token, Chu_de, Bat_dau) 
                VALUES (?, ?, ?, NOW())
            `;
            const [result] = await execute(sql, [maNguoiDung, sessionToken, jsonChuDe]);
            return result.insertId;
        }catch(error){
            throw new Error('Lỗi tạo phiên hội thoại: ' + error.message);
        }
    }

    // 2. Lấy lịch sử tin nhắn theo đúng Ma_hoi_thoai
    static async getHistory(maHoiThoai) {
        const sql = `
            SELECT Vai_tro, Noi_dung 
            FROM tin_nhan_hoi_thoai 
            WHERE Ma_hoi_thoai = ? 
            ORDER BY Ngay_tao ASC
        `;
        const [rows] = await execute(sql, [maHoiThoai]);
        return rows;
    }

    // 3. Lưu một tin nhắn mới (User hoặc Chatbot)
    static async saveMessage(maHoiThoai, vaiTro, noiDung, doiTuong = null) {
        // Doi_tuong yêu cầu kiểm tra json_valid nên phải chuyển đổi chu đáo nếu có dữ liệu
        const jsonDoiTuong = doiTuong ? JSON.stringify(doiTuong) : null;
        
        const sql = `
            INSERT INTO tin_nhan_hoi_thoai (Ma_hoi_thoai, Vai_tro, Noi_dung, Doi_tuong, Ngay_tao) 
            VALUES (?, ?, ?, ?, NOW())
        `;
        await execute(sql, [maHoiThoai, vaiTro, noiDung, jsonDoiTuong]);
    }

    // 4. Tìm kiếm bác sĩ cho tính năng gọi hàm (Function Calling)
    static async findDoctorBySpecialty(specialtyName) {
        const sql = `
            SELECT b.Ho_ten, c.Ten_chuyen_khoa 
            FROM bac_si b 
            JOIN chuyen_khoa c ON b.Ma_chuyen_khoa = c.Ma_chuyen_khoa 
            WHERE c.Ten_chuyen_khoa LIKE ? 
            LIMIT 3
        `;
        const [doctors] = await execute(sql, [`%${specialtyName}%`]);
        return doctors;
    }
}