import { GoogleGenerativeAI } from "@google/generative-ai";
import { v4 as uuidv4 } from 'uuid';
import ChatModel from "../models/chatModel.js";

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY, { apiVersion: 'v1beta' });

const tools = [{
    functionDeclarations: [
        {
            name: "findDoctorBySpecialty",
            description: "Tìm kiếm danh sách bác sĩ theo tên chuyên khoa.",
            parameters: {
                type: "OBJECT",
                properties: {
                    specialtyName: { type: "STRING", description: "Tên chuyên khoa" }
                },
                required: ["specialtyName"],
            },
        }
    ],
}];

const geminiModel = genAI.getGenerativeModel(
    { 
        model: "gemini-2.0-flash", 
        tools: tools 
    },
);

export default class ChatService {
    static async processChat(message, maHoiThoai, maNguoiDung, chuDeText) {
        let currentMaHoiThoai = maHoiThoai;
        let sessionToken = null;

        // Bước 1: Tạo phiên mới nếu client chưa truyền Ma_hoi_thoai lên
        if (!currentMaHoiThoai) {
            sessionToken = uuidv4(); // Thỏa mãn VARCHAR(64)
            // Lấy 5-6 từ đầu của tin nhắn làm chủ đề nếu client không gửi chuđe
            const shortTheme = chuDeText || (message.split(" ").slice(0, 5).join(" ") + "...");
            currentMaHoiThoai = await ChatModel.createSession(maNguoiDung, sessionToken, shortTheme);
        }

        // Bước 2: Lấy lịch sử và chuyển đổi định dạng thích hợp cho Gemini
        const dbRows = await ChatModel.getHistory(currentMaHoiThoai);
        const geminiHistory = dbRows.map(row => ({
            // Đổi 'chatbot' trong DB thành 'model' của Gemini
            role: row.Vai_tro === 'chatbot' ? 'model' : 'user', 
            parts: [{ text: row.Noi_dung }]
        }));

        // Bước 3: Khởi tạo luồng chat với Gemini cùng lịch sử vừa map
        const chat = geminiModel.startChat({ history: geminiHistory });

        // Bước 4: Lưu tin nhắn của Người dùng vào cơ sở dữ liệu
        await ChatModel.saveMessage(currentMaHoiThoai, 'user', message);

        // Bước 5: Đẩy tin nhắn tới AI xử lý
        let result = await chat.sendMessage(message);
        let response = result.response;

        // Bước 6: Xử lý kích hoạt Function Calling
        let entitiesExtracted = null; // Biến tạm lưu dữ liệu cho cột Doi_tuong nếu cần
        if (response.functionCalls && response.functionCalls.length > 0) {
            const call = response.functionCalls[0];
            let apiResponse = {};

            if (call.name === "findDoctorBySpecialty") {
                const specName = call.args.specialtyName;
                const doctors = await ChatModel.findDoctorBySpecialty(specName);
                
                apiResponse = { doctors: doctors.length > 0 ? doctors : "Không tìm thấy" };
                // Trích xuất thông tin thực thể để chuẩn bị lưu vào trường Doi_tuong của DB
                entitiesExtracted = { chuyen_khoa_tim_kiem: specName, so_luong_tim_thay: doctors.length };
            }

            // Gửi dữ liệu kết quả truy vấn ngược lại cho AI để tổng hợp văn bản tự nhiên
            result = await chat.sendMessage([{
                functionResponse: { name: call.name, response: apiResponse }
            }]);
            response = result.response;
        }

        const aiTextResponse = response.text();

        // Bước 7: Lưu câu trả lời từ chatbot vào cơ sở dữ liệu
        await ChatModel.saveMessage(currentMaHoiThoai, 'chatbot', aiTextResponse, entitiesExtracted);

        // Bước 8: Trả dữ liệu sạch về cho Controller
        return { 
            maHoiThoai: currentMaHoiThoai, 
            sessionToken: sessionToken, 
            text: aiTextResponse 
        };
    }
}