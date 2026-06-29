import ChatService from "../services/chatService.js";

export default class ChatController {
    static async handleChat(req, res) {
        try {
            // Khớp chính xác các thuộc tính được gửi từ Body Client
            const { message, maHoiThoai, maNguoiDung, chuDe } = req.body; 

            // Kiểm tra tính hợp lệ dữ liệu
            if (!message || !maNguoiDung) {
                return res.status(400).json({ 
                    success: false, 
                    message: "Yêu cầu cung cấp đầy đủ thông tin 'message' và 'maNguoiDung'." 
                });
            }

            // Chuyển tiếp luồng xử lý thông minh xuống tầng Service
            const result = await ChatService.processChat(message, maHoiThoai, maNguoiDung, chuDe);

            // Trả về kết quả JSON thống nhất
            return res.status(200).json({ 
                success: true, 
                maHoiThoai: result.maHoiThoai,
                sessionToken: result.sessionToken, // Sẽ có giá trị chuỗi UUID khi tạo phiên mới, ngược lại là null
                text: result.text 
            });

        } catch (error) {
            console.error("Lỗi xảy ra tại ChatController:", error);
            return res.status(500).json({ 
                success: false, 
                message: "Hệ thống gặp sự cố trong quá trình xử lý hội thoại." 
            });
        }
    }
}