// Backend_NodeJS/controllers/chatbotController.js
import { GoogleGenerativeAI } from '@google/generative-ai';
import { v4 as uuidv4 } from 'uuid';
import ChatbotModel from '../models/chatbotModel.js';

// MẢNG API KEY: Dùng để dự phòng khi 1 key bị hết hạn mức 20 request/ngày
const API_KEYS = [
    process.env.GEMINI_API_KEY_1,
    process.env.GEMINI_API_KEY_2,
    process.env.GEMINI_API_KEY_3,
    process.env.GEMINI_API_KEY_4,
    process.env.GEMINI_API_KEY_5
].filter(Boolean);

let currentKeyIndex = 0;

// Bù đúng 7 tiếng để đồng bộ hoàn toàn với múi giờ thực tế Việt Nam
const vnTime = new Date(new Date().getTime() + 7 * 60 * 60 * 1000).toISOString().split('T')[0];

// HÀM KHỞI TẠO AI: Cấu hình nhân cách (System Instruction) và bộ Công cụ (Tools) cho bot
function getActiveModel() {
    const genAI = new GoogleGenerativeAI(API_KEYS[currentKeyIndex]);
    return genAI.getGenerativeModel({ 

        // Cài đặt vai trò và kiến thức nền cho chatbot
        model: "gemini-2.5-flash",
        systemInstruction: `Bạn là trợ lý AI ảo của App Hẹn Đặt Lịch Khám MedCare.
        Nhiệm vụ: Trả lời ngắn gọn, lịch sự về quy trình khám.
        1. Giấy tờ: CMND/CCCD, BHYT, sổ khám cũ.
        2. Thời gian: 15-30 phút (thêm 1-2 tiếng nếu xét nghiệm).
        3. Chi phí ban đầu: 150.000 VNĐ.
        4. Gửi xe: Xe máy miễn phí trước cửa, ô tô 30k ở ngã tư cách 50m.
        5. Giờ làm việc: 08:00 - 21:00 (T2-CN).`,

        // Dạy cho AI biết khi nào thì cần gọi hàm (Function Calling)
        tools: [{
            functionDeclarations: [
                // TOOL: TÌM KIẾM BÁC SĨ
                {
                    name: "search_doctors",
                    description: "Dùng để tìm bác sĩ. Trả về danh sách bác sĩ.",
                    parameters: {
                        type: "OBJECT",
                        properties: { specialty: { type: "STRING", description: "Tên chuyên khoa (VD: Nội khoa)" } },
                        required: ["specialty"]
                    }
                },
                // TOOL: TÌM LỊCH TRỐNG THEO CHUYÊN KHOA
                {
                    name: "search_doctor_available_slots",
                    description: "Dùng khi người dùng muốn tìm bác sĩ có lịch trống theo chuyên khoa kèm thời gian mong muốn.",
                    parameters: {
                        type: "OBJECT",
                        properties: {
                            specialty: { type: "STRING", description: "Tên chuyên khoa cần tìm lịch trống" },
                            target_date: { type: "STRING", description: "Ngày khám định dạng YYYY-MM-DD. Hôm nay là " + vnTime },
                            time_of_day: { type: "STRING", description: "Buổi khám: 'morning' (sáng), 'afternoon' (chiều), 'evening' (tối)." }
                        },
                        required: ["specialty"]
                    }
                },
                // TOOL: KIẾM TRA LỊCH TRỐNG CỦA BÁC SĨ
                {
                    name: "check_doctor_schedule",
                    description: "Dùng để kiểm tra lịch khám còn trống của một bác sĩ cụ thể khi nhắc tên đích danh bác sĩ.",
                    parameters: {
                        type: "OBJECT",
                        properties: { doctor_name: { type: "STRING", description: "Tên bác sĩ" } },
                        required: ["doctor_name"]
                    }
                },
                // TOOL: TRA CỨU THÔNG TIN BÁC SĨ
                {
                    name: "get_doctor_profile",
                    description: "Dùng để tra cứu BẤT KỲ thông tin nào của bác sĩ (địa chỉ phòng khám, nơi làm việc, giá tiền dịch vụ, kinh nghiệm, học vị, đánh giá bệnh nhân) khi người dùng nhắc tên đích danh.",
                    parameters: {
                        type: "OBJECT",
                        properties: {
                            doctor_name: { type: "STRING", description: "Tên bác sĩ cần tra cứu thông tin (VD: Nguyễn Văn Alery)" }
                        },
                        required: ["doctor_name"]
                    }
                },
                // TOOL: ĐẶT LỊCH NHANH CÓ CHUYÊN KHOA
                {
                    name: "shortcut_book_with_specialty",
                    description: "Dùng khi người dùng muốn ĐẶT LỊCH NHANH/SỚM NHẤT và có nói rõ tên chuyên khoa (VD: 'Đặt lịch bác sĩ nội khoa sớm nhất', 'Tìm lịch khoa nhi sớm nhất').",
                    parameters: {
                        type: "OBJECT",
                        properties: { specialty: { type: "STRING", description: "Tên chuyên khoa (VD: Nội tổng quát)" } },
                        required: ["specialty"]
                    }
                },
                // TOOL: ĐẶT LỊCH NHANH KHÔNG CẦN KHOA
                {
                    name: "shortcut_book_any_specialty",
                    description: "Dùng khi người dùng muốn khám SỚM NHẤT có thể nhưng KHÔNG nhắc đến chuyên khoa nào (VD: 'Đặt cho tôi lịch sớm nhất', 'Sắp xếp lịch khám ngay').",
                    parameters: { type: "OBJECT", properties: {} }
                },
                // TOOL: XÁC NHẬN CHỐT LỊCH
                {
                    name: "confirm_and_book_appointment",
                    description: "Dùng để CHỐT ĐẶT LỊCH THẬT. Nếu trong lịch sử chat người dùng CÓ CHỈ ĐỊNH DỊCH VỤ (VD: Khám nội soi, Khám nhiều lần), AI BẮT BUỘC phải trích xuất mã dịch vụ và giá tiền đó truyền vào đây.",
                    parameters: {
                        type: "OBJECT",
                        properties: {
                            ma_khung_gio: { type: "INTEGER" },
                            ma_bac_si: { type: "INTEGER" },
                            ma_dich_vu: { type: "INTEGER", description: "Mã dịch vụ (Ma_dich_vu) nếu người dùng có nhắc đến. Để trống nếu không nhắc." },
                            gia_tien: { type: "NUMBER", description: "Giá tiền của dịch vụ đó. Để 0 nếu không có." }
                        },
                        required: ["ma_khung_gio", "ma_bac_si"]
                    }
                }
            ]
        }]
    });
}

// Lớp chatbotController: Đảm nhận vai trò (Controller) điều phối API
export default class chatbotController {
    static async askQuestion(req, res) {
        try {
            // 1. Nhận câu hỏi từ Mobile App (Flutter) gửi lên
            const { message, userId = 1, session_token: reqSessionToken } = req.body; 
            if (!message) return res.status(400).json({ success: false, message: "Vui lòng nhập câu hỏi." });

            let session_token = reqSessionToken;
            let chatHistoryText = "";

            // 2. XỬ LÝ TRÍ NHỚ (NGỮ CẢNH HỘI THOẠI)
            if (session_token) {
                // Người dùng đã chat rồi -> Gọi Model lấy lịch sử cũ
                try {
                    const historyRows = await ChatbotModel.getChatHistory(session_token);
                    if (historyRows && historyRows.length > 0) {
                        chatHistoryText = "--- Lịch sử trò chuyện trước đó ---\n";
                        historyRows.forEach(row => {
                            chatHistoryText += `${row.Vai_tro === 'user' ? 'Bệnh nhân' : 'AI'}: ${row.Noi_dung}\n`;
                        });
                        chatHistoryText += "-----------------------------------\n\n";
                        console.log("Đã tải lịch sử chat thành công!");
                    }
                } catch (err) { console.error("Lỗi lấy lịch sử chat:", err); }
            } else {
                // Người dùng mới chưa chat -> Gọi Model tạo phiên chat mới
                session_token = uuidv4();
                try {
                    await ChatbotModel.createSession(userId, session_token, message);
                    console.log("Đã tạo Session mới:", session_token);
                } catch (dbError) { console.error("Lỗi tạo DB Session:", dbError); }
            }

            // Gộp lịch sử và câu hỏi mới thành 1 khối để nạp cho AI
            const finalMessageToAI = chatHistoryText + "Câu hỏi hiện tại của Bệnh nhân: " + message;

            // 3. GỌI AI PHÂN TÍCH CÂU HỎI (Vòng 1 có cơ chế bảo vệ Key)
            let result;
            let attempts = 0;
            while (attempts < API_KEYS.length) {
                try {
                    result = await getActiveModel().generateContent(finalMessageToAI);
                    break; // Thành công -> Thoát vòng lặp
                } catch (aiError) {
                    // Nếu lỗi do hết hạn mức, tự động nhảy sang Key tiếp theo
                    if (aiError.message && (aiError.message.includes('429') || aiError.message.includes('403') || aiError.message.includes('503') || aiError.message.includes('500'))) {
                        console.log(`Key thứ ${currentKeyIndex + 1} gặp lỗi. Đang chuyển Key...`);
                        currentKeyIndex = (currentKeyIndex + 1) % API_KEYS.length;
                        attempts++;
                    } else { throw aiError; }
                }
            }

            if (!result) return res.status(500).json({ success: false, message: "Hạn mức API cạn kiệt." });
            
            // 4. KIỂM TRA XEM AI CÓ MUỐN GỌI HÀM NÀO KHÔNG?
            let call = null;
            if (result.response.functionCalls) {
                const calls = typeof result.response.functionCalls === 'function' ? result.response.functionCalls() : result.response.functionCalls;
                if (calls && calls.length > 0) call = calls[0];
            }

            // 5. XỬ LÝ NẾU CÓ FUNCTION CALLING (AI yêu cầu tìm dữ liệu)
            if (call) {
                let dbData = [];
                let prompt = "";

                // Gọi hàm tương ứng dưới tầng Model tùy theo lệnh của AI
                if (call.name === "search_doctors") {
                    console.log("AI GỌI HÀM: search_doctors ->", call.args.specialty);
                    dbData = await ChatbotModel.searchDoctors(call.args.specialty);
                    prompt = `Dựa vào danh sách bác sĩ sau: ${JSON.stringify(dbData)}. 
                    Hãy liệt kê rõ tên, học vị và điểm đánh giá của từng bác sĩ, sau đó mời đặt lịch.`;
                } 
                else if (call.name === "search_doctor_available_slots") {
                    console.log("AI GỌI HÀM: search_doctor_available_slots ->", call.args.specialty);
                    dbData = await ChatbotModel.searchAvailableSlots(call.args.specialty, call.args.target_date, call.args.time_of_day);
                prompt = `Dựa vào danh sách lịch khám còn trống sau đây của 
                chuyên khoa ${call.args.specialty}: ${JSON.stringify(dbData)}.
                - Nếu có lịch trống: Hãy đóng vai trợ lý ảo MedCare, trả lời thân thiện,
                liệt kê rõ tên bác sĩ, học vị, điểm đánh giá và các khung giờ trống để bệnh nhân lựa chọn.
                - Nếu danh sách trống rỗng ([]): Hãy trả lời lịch sự với bệnh nhân rằng
                 hiện tại khoa này đã kín lịch hoặc chưa có lịch khám vào thời gian yêu cầu,
                và gợi ý họ chọn một ngày khác hoặc chuyên khoa khác.`;
                } 

                else if (call.name === "check_doctor_schedule") {
                    console.log("AI GỌI HÀM: check_doctor_schedule ->", call.args.doctor_name);
                    dbData = await ChatbotModel.checkDoctorSchedule(call.args.doctor_name);
                    prompt = `Dựa vào lịch trống của bác sĩ: ${JSON.stringify(dbData)}. 
                    Nếu trống rỗng ([]), báo bác sĩ đã kín lịch. Ngược lại, thông báo rõ các giờ trống.`;
                }

                else if (call.name === "get_doctor_profile") {
                    console.log("AI GỌI HÀM: get_doctor_profile ->", call.args.doctor_name);
                    dbData = await ChatbotModel.getDoctorProfile(call.args.doctor_name);
                    
                    prompt = `Người dùng vừa hỏi câu này: "${message}"
                    Dựa vào hồ sơ bác sĩ sau: ${JSON.stringify(dbData)}. 
                    - Nếu có dữ liệu: Hãy đóng vai lễ tân MedCare, TRẢ LỜI ĐÚNG TRỌNG TÂM
                    câu hỏi của người dùng. Chỉ trích xuất thông tin người dùng cần 
                    (ví dụ: họ hỏi giá thì chỉ báo giá, hỏi địa chỉ thì chỉ báo địa chỉ). 
                    Có thể khen ngợi ngắn gọn thái độ của bác sĩ nếu phù hợp. 
                    KHÔNG liệt kê dài dòng những thông tin người dùng không hỏi.
                    - Nếu trống rỗng ([]): Xin lỗi và báo không tìm thấy thông tin bác sĩ này.`;
                }
                
                else if (call.name === "shortcut_book_with_specialty") {
                    console.log("AI GỌI HÀM: Đặt lịch sớm nhất CÓ Khoa ->", call.args.specialty);
                    dbData = await ChatbotModel.findEarliestSlotWithSpecialty(call.args.specialty);
                    
                    prompt = `Dựa vào kết quả lịch trống sớm nhất: ${JSON.stringify(dbData)}. 
                    - Nếu có lịch ([] không rỗng): Hãy thông báo đây là lịch sớm nhất của chuyên khoa ${call.args.specialty}, nêu rõ giờ khám, tên bác sĩ (Kèm mã ma_khung_gio và ma_bac_si ẩn trong câu trả lời để hệ thống ghi nhớ) và HỎI người dùng có ĐỒNG Ý đặt lịch này không.
                    - Nếu trống ([]): Xin lỗi và báo chuyên khoa này hiện đã hết lịch khả dụng.`;
                }

                else if (call.name === "shortcut_book_any_specialty") {
                    console.log("AI GỌI HÀM: Đặt lịch sớm nhất KHÔNG Khoa");
                    dbData = await ChatbotModel.findEarliestSlotAnySpecialty();
                    
                    prompt = `Dựa vào kết quả lịch trống sớm nhất toàn hệ thống: ${JSON.stringify(dbData)}. 
                    - Nếu có lịch ([] không rỗng): Thông báo đây là khung giờ sớm nhất hiện có, 
                    nêu rõ chuyên khoa, giờ khám, tên bác sĩ (Kèm mã ma_khung_gio và ma_bac_si 
                    ẩn trong câu để hệ thống nhớ) và HỎI người dùng có ĐỒNG Ý đặt lịch không.
                    - Nếu trống ([]): Xin lỗi và báo toàn bộ phòng khám đã kín lịch.`;
                }

                else if (call.name === "confirm_and_book_appointment") {
                    const maDichVu = call.args.ma_dich_vu || null;
                    const giaTien = call.args.gia_tien || 0;
                    console.log(`AI CHỐT LỊCH -> Giờ: ${call.args.ma_khung_gio}, Bác sĩ: ${call.args.ma_bac_si}, Dịch vụ: ${maDichVu}, Tiền: ${giaTien}`);
                    
                    try {
                        const bookingCode = await ChatbotModel.createNewAppointment(userId, call.args.ma_khung_gio, call.args.ma_bac_si);
                        prompt = `Hệ thống vừa đặt lịch thành công với Mã Booking là: ${bookingCode}. 
                        Hãy vào vai lễ tân, chúc mừng bệnh nhân đã đặt lịch thành công, 
                        nhắc lại mã Booking và dặn họ đến trước 15 phút để làm thủ tục.
                        - Nếu có giá tiền (gia_tien > 0): Hãy báo tổng chi phí 
                        là ${giaTien} VNĐ và dặn bệnh nhân thanh toán tại quầy.
                        - Nếu giá tiền = 0: Hãy dặn chi phí sẽ tính sau khi bác sĩ tư vấn.`;
                    } catch (error) {
                        prompt = `Hãy xin lỗi bệnh nhân một cách lịch sự, 
                        thông báo rằng khung giờ này vừa có người khác đặt 
                        hoặc hệ thống đang bận, vui lòng chọn một khung giờ khác.`;
                    }
                }

                // 6. GỌI AI LẦN 2: Nhờ AI tổng hợp Data thô thành câu trả lời tự nhiên
                let finalResult = await chatbotController.handleAIRequestWithRotation(prompt);
                if (!finalResult) return res.status(500).json({ success: false, message: "Hệ thống AI bận." });

                const replyText = finalResult.response.text();

                // 7. LƯU LỊCH SỬ CHAT VÀO DATABASE
                await ChatbotModel.saveMessage(session_token, 'user', message);
                await ChatbotModel.saveMessage(session_token, 'chatbot', replyText);

                // Trả kết quả về cho Flutter App
                return res.status(200).json({ success: true, reply: replyText, session_token });
            }

            // 8. XỬ LÝ NẾU KHÔNG GỌI HÀM (Chỉ hỏi đáp thông thường về chi phí, giờ làm...)
            const replyText = result.response.text();
            await ChatbotModel.saveMessage(session_token, 'user', message);
            await ChatbotModel.saveMessage(session_token, 'chatbot', replyText);

            return res.status(200).json({ success: true, reply: replyText, session_token });

        } catch (error) {
            console.error("LỖI HỆ THỐNG:", error);
            return res.status(500).json({ success: false, message: "Hệ thống lỗi.", error: error.message });
        }
    }

    // HÀM BỔ TRỢ: Rút gọn luồng xoay vòng Key lần 2 (Gọi ở bước 6)
    static async handleAIRequestWithRotation(prompt) {
        let finalAttempts = 0;
        while (finalAttempts < API_KEYS.length) {
            try {
                return await getActiveModel().generateContent(prompt);
            } catch (aiError) {
                // Gặp lỗi 429 hoặc 403 thì tăng Index để đổi Key
                if (aiError.message && (aiError.message.includes('429') || aiError.message.includes('403') || aiError.message.includes('503') || aiError.message.includes('500'))) {
                    currentKeyIndex = (currentKeyIndex + 1) % API_KEYS.length;
                    finalAttempts++;
                } else { throw aiError; }
            }
        }
        return null; // Nếu thử hết tất cả Key mà vẫn lỗi thì báo tải thất bại
    }
}