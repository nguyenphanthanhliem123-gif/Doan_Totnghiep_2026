import { GoogleGenerativeAI } from '@google/generative-ai';
import { v4 as uuidv4 } from 'uuid';
import ChatbotModel from '../models/chatbotModel.js';
import ChromaService from '../services/chromaService.js';

// MẢNG API KEY: Dùng để dự phòng khi 1 key bị hết hạn mức 20 request/ngày 
// Thêm GEMINI_API_KEY ở file .env, mẫu theo file .env.example
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
        // Dữ liệu mẫu
        systemInstruction: `Bạn là trợ lý AI ảo của App Hẹn Đặt Lịch Khám MedCare.
        Nhiệm vụ: Trả lời ngắn gọn, lịch sự về quy trình khám.
        1. Giấy tờ: CMND/CCCD, BHYT, sổ khám cũ.
        2. Thời gian: 15-30 phút (thêm 1-2 tiếng nếu xét nghiệm).
        3. Chi phí ban đầu: 150.000 VNĐ (Khi khách hàng đặt lịch nhanh không nói rõ 
        dịch vụ, hệ thống sẽ tự động đăng ký gói Khám lâm sàng cơ bản 150.000 VNĐ).
        4. Gửi xe: Xe máy miễn phí trước cửa, ô tô 30k ở ngã tư cách 50m.
        5. Giờ làm việc: 08:00 - 21:00 (T2-CN).
        6. HỎI ĐÁP HẬU KHÁM (THUỐC): Khi người dùng hỏi về tác dụng phụ, 
        công dụng hoặc cách uống của một loại thuốc bất kỳ, hãy đóng vai 
        dược sĩ và sử dụng kiến thức y khoa chuyên môn của bạn để trả lời. 
        TUYỆT ĐỐI BẮT BUỘC phải chèn thêm câu cảnh báo: "Lưu ý: Thông tin 
        này chỉ mang tính tham khảo, vui lòng liên hệ trực tiếp bác sĩ 
        điều trị nếu có triệu chứng bất thường." ở cuối câu.
        7. TƯ VẤN TRIỆU CHỨNG & SÀNG LỌC BỆNH: 
        - Khi bệnh nhân mô tả các triệu chứng tự nhiên, bạn BẮT BUỘC phải gọi hàm "suggestSpecialtyBySymptom".
        - Tuyệt đối KHÔNG tự phán đoán hay kết luận vo khi chưa gọi hàm này.

        8. QUY TRÌNH ĐẶT LỊCH (CHỦ ĐỘNG & RÕ RÀNG):
        - LUỒNG 1 (YÊU CẦU SỚM NHẤT/TÌM MỚI): Khi người dùng yêu cầu "đặt lịch sớm nhất", "đổi bác sĩ", "đổi sang giờ khác" -> BỎ QUA TOÀN BỘ MÃ ẨN CŨ, BẮT BUỘC gọi tool 'shortcut_book_earliest' hoặc 'check_doctor_schedule' để lấy dữ liệu mới.
        - LUỒNG 2 (XEM LỊCH & CHỌN GIỜ): 
            + KHI LIỆT KÊ LỊCH: BẮT BUỘC chèn mã ẩn sau mỗi khung giờ: [Mã giờ: X, Mã BS: Y].
            + CHỦ ĐỘNG ĐẶT CÂU HỎI CHỐT sau khi liệt kê lịch.

        9. QUY TẮC CHỐT LỊCH (CỰC KỲ QUAN TRỌNG):
        - CHỈ GỌI tool 'confirm_and_book_appointment' KHI VÀ CHỈ KHI người dùng XÁC NHẬN CHỌN MỘT GIỜ CỤ THỂ từ danh sách bạn VỪA MỚI LIỆT KÊ ở tin nhắn ngay phía trên.
        - Tuyệt đối KHÔNG tái sử dụng các mã ẩn [Mã giờ: X] từ những cuộc hội thoại cũ tít phía trên nếu người dùng thay đổi luồng trò chuyện sang "đặt sớm nhất".
        - Nếu không có dịch vụ nào được chọn, tự truyền {ma_dich_vu: 25, gia_tien: 150000}.`,

        // Dạy cho AI biết khi nào thì cần gọi hàm (Function Calling)
        tools: [{
            functionDeclarations: [
                // ====================================================================================
                // 📍 [HƯỚNG DẪN] - BƯỚC 1: KHAI BÁO CÔNG CỤ (TOOL) CHO AI
                // ====================================================================================

                // TOOL: TÌM KIẾM BÁC SĨ THEO CHUYÊN KHOA
                {
                    name: "search_doctor_by_specialty",
                    description: "Tìm kiếm danh sách bác sĩ theo tên chuyên khoa. Trả về danh sách bác sĩ kèm học vị, điểm đánh giá và mô tả bản thân.",
                    parameters: {
                        type: "OBJECT",
                        properties: { specialtyName: { type: "STRING", description: "Tên chuyên khoa (VD: Nội khoa, Tai Mũi Họng)" } },
                        required: ["specialtyName"]
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
                    description: "Dùng để kiểm tra lịch khám còn trống của một bác sĩ cụ thể.",
                    parameters: {
                        type: "OBJECT",
                        properties: { 
                            doctor_name: { type: "STRING", description: "Tên bác sĩ" },
                            target_date: { type: "STRING", description: "Ngày khám người dùng muốn định dạng YYYY-MM-DD. Hôm nay là " + vnTime }
                        },
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
                // TOOL: ĐẶT LỊCH THẲNG KHI CÓ ĐỦ THÔNG TIN
                {
                    name: "direct_book_specific_time",
                    description: "Dùng khi người dùng ngay từ đầu đã cung cấp ĐẦY ĐỦ Tên bác sĩ + Ngày + Giờ cụ thể. AI không cần biết Mã ID, chỉ cần truyền text.",
                    parameters: {
                        type: "OBJECT",
                        properties: { 
                            doctor_name: { type: "STRING", description: "Tên bác sĩ (VD: Alery)" },
                            target_date: { type: "STRING", description: "Ngày khám định dạng YYYY-MM-DD. Nếu không nhắc ngày, dùng: " + vnTime },
                            target_time: { type: "STRING", description: "Giờ khám định dạng HH:mm (VD: 08:00)" },
                            danh_sach_dich_vu: { 
                                type: "ARRAY", 
                                description: "Danh sách các dịch vụ người dùng chọn. Bỏ trống nếu không chọn dịch vụ nào.",
                                items: {
                                    type: "OBJECT",
                                    properties: {
                                        ma_dich_vu: { type: "INTEGER", description: "Mã dịch vụ tự bốc từ [Mã DV: X]" },
                                        gia_tien: { type: "NUMBER", description: "Giá tiền của dịch vụ đó" }
                                    }
                                }
                            }
                        },
                        required: ["doctor_name", "target_date", "target_time"]
                    }
                },
                // TOOL: ĐẶT LỊCH SỚM NHẤT THEO TÊN BÁC SĨ HOẶC CHUYÊN KHOA
                {
                    name: "shortcut_book_earliest",
                    description: "Dùng khi người dùng muốn ĐẶT LỊCH SỚM NHẤT. Hỗ trợ tìm theo tên bác sĩ HOẶC chuyên khoa.",
                    parameters: {
                        type: "OBJECT",
                        properties: { 
                            doctor_name: { type: "STRING", description: "Tên bác sĩ nếu người dùng nhắc đến (VD: Alery)" },
                            specialty: { type: "STRING", description: "Tên chuyên khoa nếu người dùng nhắc đến (VD: Nội khoa)" }
                        }
                    }
                },
                // TOOL: XÁC NHẬN CHỐT LỊCH
                {
                    name: "confirm_and_book_appointment",
                    description: "Dùng để CHỐT ĐẶT LỊCH THẬT SỰ khi người dùng ra lệnh đặt lịch (VD: 'Đặt lịch khám nội soi sớm nhất', 'Đặt lúc 8h', 'Ok chốt đi'). QUAN TRỌNG: AI phải TỰ ĐỘNG đọc lịch sử chat phía trên để bốc đúng ma_khung_gio và ma_bac_si. Nếu người dùng yêu cầu 'sớm nhất', hãy tự động lấy mã của khung giờ đầu tiên trong danh sách vừa liệt kê. Nếu có dịch vụ (VD: khám nội soi), tự trích xuất ma_dich_vu và gia_tien truyền vào.",
                    parameters: {
                        type: "OBJECT",
                        properties: {
                            ma_khung_gio: { type: "INTEGER", description: "Mã khung giờ (Ma_khung_gio) tự bốc từ lịch sử chat." },
                            ma_bac_si: { type: "INTEGER", description: "Mã bác sĩ (Ma_bac_si) tự bốc từ lịch sử chat." },
                            danh_sach_dich_vu: { 
                                type: "ARRAY", 
                                description: "Danh sách các dịch vụ người dùng chọn. Bỏ trống nếu không chọn dịch vụ nào.",
                                items: {
                                    type: "OBJECT",
                                    properties: {
                                        ma_dich_vu: { type: "INTEGER", description: "Mã dịch vụ tự bốc từ [Mã DV: X]" },
                                        gia_tien: { type: "NUMBER", description: "Giá tiền của dịch vụ đó" }
                                    }
                                }
                            }
                        },
                        required: ["ma_khung_gio", "ma_bac_si"]
                    }
                },
                // TOOL: GỢI Ý CHUYÊN KHOA THEO TRIỆU CHỨNG
                {
                    name: "suggestSpecialtyBySymptom",
                    description: "Gợi ý chuyên khoa y tế phù hợp (Nội, Ngoại, Sản, Nhi, Tai Mũi Họng, Thần kinh...) dựa trên nhóm triệu chứng hoặc bệnh lý mà người dùng mô tả.",
                    parameters: {
                        type: "OBJECT",
                        properties: {
                            symptomKeyword: { 
                                type: "STRING", 
                                description: "Từ khóa chính của triệu chứng hoặc bộ phận bị đau tách ra từ lời kể của người dùng (ví dụ: 'đau đầu', 'ho', 'đau bụng', 'tai')." 
                            }
                        },
                        required: ["symptomKeyword"],
                    },
                },
                // TOOL: TRA CỨU ĐƠN THUỐC CỦA BỆNH NHÂN
                {
                    name: "lookup_my_prescription",
                    description: "Dùng khi người dùng muốn xem lại đơn thuốc của họ, hỏi cách uống thuốc trong đơn, hoặc hỏi về bệnh án gần nhất (VD: 'Đơn thuốc của tôi có những gì?', 'Thuốc bác sĩ kê hôm trước uống sao?').",
                    parameters: { type: "OBJECT", properties: {} }
                },
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
                session_token = uuidv4();
                try {
                    await ChatbotModel.createSession(userId, session_token, message);
                    console.log("Đã tạo Session mới:", session_token);
                } catch (dbError) { console.error("Lỗi tạo DB Session:", dbError); }
            }

            const finalMessageToAI = chatHistoryText + "Câu hỏi hiện tại của Bệnh nhân: " + message;

            // 3. GỌI AI PHÂN TÍCH CÂU HỎI (Vòng 1 có cơ chế bảo vệ Key)
            let result;
            let attempts = 0;
            while (attempts < API_KEYS.length) {
                try {
                    result = await getActiveModel().generateContent(finalMessageToAI);
                    break;
                } catch (aiError) {
                    if (aiError.message && (aiError.message.includes('429') || aiError.message.includes('403') || aiError.message.includes('503') || aiError.message.includes('500'))) {
                        console.log(`[CẢNH BÁO] API Key thứ ${currentKeyIndex + 1} thất bại. Lý do: ${aiError.message}`);
                        console.log(`🔄 Đang chuyển sang API Key tiếp theo...`);
                        currentKeyIndex = (currentKeyIndex + 1) % API_KEYS.length;
                        attempts++;
                    } else { 
                        console.error(`[LỖI NGHIÊM TRỌNG] Quá trình gọi AI vòng 1 gặp sự cố:`, aiError);
                        throw aiError; 
                    }
                }
            }

            if (!result) return res.status(500).json({ success: false, message: "Hạn mức API cạn kiệt." });
            
            // 4. KIỂM TRA XEM AI CÓ MUỐN GỌI HÀM NÀO KHÔNG?
            let call = null;
            if (result.response.functionCalls) {
                const calls = typeof result.response.functionCalls === 'function' ? result.response.functionCalls() : result.response.functionCalls;
                if (calls && calls.length > 0) call = calls[0];
            }

            // 5. XỬ LÝ NẾU CÓ FUNCTION CALLING
            if (call) {
                let dbData = [];
                let prompt = "";

                // ====================================================================================
                // 📍 [HƯỚNG DẪN] - BƯỚC 2: XỬ LÝ LOGIC DATABASE CHO CHỨC NĂNG MỚI
                // ====================================================================================

                // HÀM ĐÃ GỘP: Tìm kiếm bác sĩ theo chuyên khoa
                if (call.name === "search_doctor_by_specialty") {
                    console.log("AI GỌI HÀM: search_doctor_by_specialty ->", call.args.specialtyName);
                    // Đã đổi tên hàm gọi xuống Model cho khớp
                    dbData = await ChatbotModel.searchDoctorsBySpecialty(call.args.specialtyName);

                    prompt = `Người dùng muốn tìm bác sĩ khoa ${call.args.specialtyName}.
                    Dựa vào dữ liệu tìm được: ${JSON.stringify(dbData)}.
                    - Nếu có dữ liệu: Hãy liệt kê họ tên bác sĩ kèm theo học vị, điểm đánh giá và một đoạn tóm tắt ngắn về kinh nghiệm/mô tả bản thân của từng bác sĩ để tăng sự tin tưởng cho bệnh nhân. Trình bày thật chuyên nghiệp, thân thiện và mời đặt lịch.
                    - Nếu rỗng ([]): Hãy báo là không tìm thấy bác sĩ nào thuộc chuyên khoa này.`;
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
                    console.log("AI GỌI HÀM: check_doctor_schedule ->", call.args.doctor_name, "Ngày:", call.args.target_date);
                    dbData = await ChatbotModel.checkDoctorSchedule(call.args.doctor_name, call.args.target_date);

                    prompt = `Người dùng đang hỏi lịch của bác sĩ.
                    Dựa vào dữ liệu lịch trống: ${JSON.stringify(dbData)}.
                    - Nếu có lịch: Hãy liệt kê thân thiện cho bệnh nhân. 
                    QUAN TRỌNG: Ở mỗi khung giờ được liệt kê, bạn BẮT BUỘC
                    phải viết kèm mã ẩn theo cú pháp chính xác là 
                    [Mã giờ: X, Mã BS: Y] ngay phía sau giờ đó để hệ thống ghi nhớ.
                    Ví dụ: * 08:00 - 08:25 [Mã giờ: 1, Mã BS: 13]
                    - Nếu trống rỗng ([]): Hãy xin lỗi và báo rằng 
                    bác sĩ này đã kín lịch vào thời gian yêu cầu.`;
                }

                else if (call.name === "get_doctor_profile") {
                    console.log("AI GỌI HÀM: get_doctor_profile ->", call.args.doctor_name);
                    dbData = await ChatbotModel.getDoctorProfile(call.args.doctor_name);
                    
                    prompt = `Người dùng vừa hỏi câu này: "${message}"
                    Dựa vào hồ sơ bác sĩ sau: ${JSON.stringify(dbData)}. 
                    - Nếu có dữ liệu: Hãy đóng vai lễ tân MedCare, TRẢ LỜI ĐÚNG TRỌNG TÂM
                    câu hỏi của người dùng. Chỉ trích xuất thông tin người dùng cần 
                    (Ví dụ: họ hỏi giá thì chỉ báo giá, hỏi địa chỉ thì chỉ báo địa chỉ). 
                    LƯU Ý ĐẶC BIỆT: Nếu bạn liệt kê danh sách dịch vụ khám, 
                    bạn BẮT BUỘC phải đính kèm thẻ mã ẩn theo cú pháp [Mã DV: X] 
                    ngay sau mỗi tên dịch vụ để hệ thống ghi nhớ.
                    (Ví dụ: Khám nội soi [Mã DV: 23] giá 200.000 VNĐ.) 
                    KHÔNG liệt kê dài dòng những thông tin người dùng không hỏi.
                    
                    - Trường hợp Sai tên bác sĩ (nếu dữ liệu trả về rỗng []): Hãy lịch sự 
                    báo không tìm thấy bác sĩ mang tên "${call.args.doctor_name}". 
                    Sau đó, hãy chủ động dựa vào chuyên khoa được nhắc tới (nếu có) hoặc 
                    đọc lại lịch sử trò chuyện ở trên để gợi ý một vài tên bác sĩ nổi bật 
                    có tên gần giống hoặc cùng chuyên khoa cho bệnh nhân.`;
                }

                else if (call.name === "direct_book_specific_time") {
                    console.log("AI GỌI HÀM: direct_book_specific_time ->", call.args.doctor_name, call.args.target_date, call.args.target_time);
                    
                    // 1. Lấy danh sách dịch vụ AI trích xuất được (nếu có)
                    let danhSachDichVu = call.args.danh_sach_dich_vu || [];

                    // 2. LOGIC MẶC ĐỊNH: Nếu mảng rỗng (khách không nói dịch vụ gì), tự động thêm Khám lâm sàng (Mã 25, 150k)
                    if (danhSachDichVu.length === 0) {
                        danhSachDichVu = [{ ma_dich_vu: 25, gia_tien: 150000 }];
                    }

                    // 3. Backend ngầm dịch Text thành ID
                    const exactSlot = await ChatbotModel.findExactSlotId(call.args.doctor_name, call.args.target_date, call.args.target_time);
                    
                    if (exactSlot) {
                        try {
                            // Tiến hành chốt lịch
                            const bookingCode = await ChatbotModel.createNewAppointment(userId, exactSlot.Ma_khung_gio, exactSlot.Ma_bac_si, danhSachDichVu);
                            
                            // Tính tổng tiền dựa trên mảng dịch vụ cuối cùng
                            const tongChiPhi = danhSachDichVu.reduce((sum, item) => sum + (item.gia_tien || 0), 0);
                            
                            prompt = `Bạn đã tìm thấy khung giờ phù hợp và Backend đã tự động đặt lịch thành công. Mã Booking là: ${bookingCode}.
                            Hãy đóng vai lễ tân báo tin vui, nhắc lại ngày giờ (${call.args.target_time} ngày ${call.args.target_date}) do bác sĩ ${call.args.doctor_name} khám. 
                            Báo tổng chi phí dự kiến là ${tongChiPhi} VNĐ và dặn họ đến trước 15 phút.`;
                        } catch (err) {
                            prompt = `Hệ thống backend báo lỗi khi lưu lịch. Hãy xin lỗi người dùng và báo hệ thống đang bận.`;
                        }
                    } else {
                        // 4. Nếu giờ đó BS không có lịch hoặc đã bị người khác đặt
                        console.log("-> Khung giờ đã kín/không tồn tại. Đang tìm lịch thay thế để gợi ý...");
                        
                        // Chủ động quét DB lấy các giờ còn trống của bác sĩ đó trong cùng ngày
                        const lichGoiY = await ChatbotModel.checkDoctorSchedule(call.args.doctor_name, call.args.target_date);
                        
                        prompt = `Khung giờ ${call.args.target_time} ngày ${call.args.target_date} của bác sĩ ${call.args.doctor_name} hiện không khả dụng hoặc đã có người đặt. 
                        Hãy lịch sự xin lỗi người dùng vì sự bất tiện này.
                        
                        Tiếp theo, hãy dựa vào danh sách các khung giờ còn trống khác trong ngày: ${JSON.stringify(lichGoiY)}.
                        - Nếu có lịch trống khác ([] không rỗng): Hãy chủ động gợi ý các giờ này cho người dùng chọn. ⚠️ NHỚ BẮT BUỘC CHÈN MÃ ẨN [Mã giờ: X, Mã BS: Y] sau mỗi giờ gợi ý để họ có thể chốt.
                        - Nếu rỗng ([]): Hãy báo là bác sĩ đã kín lịch toàn bộ trong ngày hôm đó và gợi ý họ chọn ngày khác hoặc bác sĩ khác.`;
                    }
                }

                else if (call.name === "shortcut_book_earliest") {
                    let dbData = [];
                    // Xét xem người dùng gọi tên BS hay tên khoa
                    if (call.args.doctor_name) {
                        console.log("AI GỌI HÀM: Đặt lịch sớm nhất Bác Sĩ ->", call.args.doctor_name);
                        dbData = await ChatbotModel.findEarliestSlot(call.args.doctor_name, true);
                    } else if (call.args.specialty) {
                        console.log("AI GỌI HÀM: Đặt lịch sớm nhất Chuyên Khoa ->", call.args.specialty);
                        dbData = await ChatbotModel.findEarliestSlot(call.args.specialty, false);
                    } else {
                        // Tránh lỗi nếu AI không bóc được cả 2
                        dbData = [];
                    }
                    
                    prompt = `Dựa vào kết quả lịch trống sớm nhất: ${JSON.stringify(dbData)}. 
                    - Nếu có lịch ([] không rỗng): Hãy thông báo đây là lịch sớm nhất, nêu rõ giờ khám, ngày khám và tên bác sĩ. 
                      ⚠️ QUAN TRỌNG: Bạn BẮT BUỘC phải viết kèm mã ẩn theo cú pháp chính xác là [Mã giờ: X, Mã BS: Y] ở cuối câu. 
                      Sau đó HỎI người dùng có ĐỒNG Ý chốt lịch này không.
                      Ví dụ: Bác sĩ Nguyễn Thị Alery còn lịch trống sớm nhất vào lúc 08:00 - 08:30 ngày 14-07-2026 [Mã giờ: 1, Mã BS: 13]. Bạn có muốn tôi chốt lịch này không?
                      
                    - Trường hợp Hết chỗ (nếu kết quả trả về rỗng []): Hãy xin lỗi và báo rằng hiện tại bác sĩ/chuyên khoa này đã kín lịch.`;
                }

                else if (call.name === "confirm_and_book_appointment") {
                    let maKhungGio = call.args.ma_khung_gio;
                    let maBacSi = call.args.ma_bac_si;
                    let danhSachDichVu = call.args.danh_sach_dich_vu || [];

                    if (danhSachDichVu.length === 0) {
                        danhSachDichVu = [{ ma_dich_vu: 25, gia_tien: 150000 }];
                    }
                    console.log(`AI ĐANG TỰ TRUY CẬP MÃ -> Giờ: ${maKhungGio}, BS: ${maBacSi}, Dịch Vụ:`, JSON.stringify(danhSachDichVu));
                    
                    try {
                        const bookingResult = await ChatbotModel.createNewAppointment(userId, maKhungGio, maBacSi, danhSachDichVu);
                        const tongChiPhi = danhSachDichVu.reduce((sum, item) => sum + (item.gia_tien || 0), 0);

                        prompt = `Hệ thống vừa đặt lịch thành công với Mã Booking là: ${bookingResult.maBooking}. 
                        Hãy báo tin vui cho bệnh nhân.
                        ⚠️ BẮT BUỘC ĐỌC ĐÚNG THỜI GIAN NÀY: Khám vào lúc ${bookingResult.gioKham} ngày ${bookingResult.ngayKham}.
                        Báo tổng chi phí là ${tongChiPhi} VNĐ và dặn họ đến trước 15 phút.`;
                    } catch (error) {
                        console.error("LỖI SQL KHI ĐẶT LỊCH:", error.message);
                        
                        // Truyền thẳng nguyên nhân lỗi cho AI để AI giải thích với khách hàng
                        prompt = `Việc đặt lịch bị thất bại do lỗi hệ thống trả về như sau: "${error.message}". 
                        Hãy giải thích lỗi này một cách lịch sự, thấu hiểu và gợi ý hướng giải quyết cho bệnh nhân (Ví dụ: Chọn một khung giờ khác).`;
                    }
                }
                
                else if (call.name === "suggestSpecialtyBySymptom") {
                    console.log("AI GỌI HÀM: suggestSpecialtyBySymptom -> từ khóa:", call.args.symptomKeyword);
                    
                    // 1. Thực hiện RAG: Lấy kiến thức y khoa chuyên sâu từ kho lưu trữ Vector ChromaDB
                    const medicalFacts = await ChromaService.searchMedicalKnowledge(message);
                    console.log("[RAG ChromaDB Data]:", medicalFacts);
                    
                    // 2. Lấy dữ liệu chuyên khoa ánh xạ từ Database MySQL
                    dbData = await ChatbotModel.suggestSpecialtyBySymptom(call.args.symptomKeyword);
                    
                    // 3. Định hình prompt nâng cao kết hợp cả 2 nguồn tri thức
                    prompt = `Bạn đang đóng vai một Bác sĩ tư vấn sàng lọc thông minh của hệ thống phòng khám MedCare.
                    Người dùng vừa mô tả tình trạng: "${message}" (Từ khóa hệ thống trích xuất: "${call.args.symptomKeyword}").

                    ------------------------------------------
                    KHO KIẾN THỨC Y KHOA ĐƯỢC TRA CỨU TỪ CHROMADB (RAG):
                    ${medicalFacts ? JSON.stringify(medicalFacts) : "Không tìm thấy tài liệu y khoa khớp chính xác hoàn toàn."}

                    DANH SÁCH CHUYÊN KHOA PHÙ HỢP TỪ DATABASE MYSQL:
                    ${JSON.stringify(dbData)}
                    ------------------------------------------

                    QUY TRÌNH TƯ VẤN VÀ PHÂN LOẠI CỦA BÁC SĨ AI (HÃY LÀM THEO CÁC BƯỚC):
                    
                    Bước 1: Đối chiếu & Phân loại nhóm bệnh tạm thời
                    - Dựa vào nội dung "Kho kiến thức y khoa từ ChromaDB", hãy chỉ ra cho bệnh nhân biết họ có khả năng đang thuộc "Nhóm bệnh" nào (Ví dụ: Nhiễm trùng đường hô hấp cấp tính, Cơ xương khớp...). 

                    Bước 2: Hỏi thêm câu hỏi sàng lọc (Nếu dữ liệu thiếu hụt)
                    - Nếu lời kể của bệnh nhân còn ngắn (ví dụ chỉ nói đau đầu, sốt nhẹ 2 ngày giống như hiện tại), hãy đối chiếu với mục "Triệu chứng điển hình" trong cẩm nang vừa tìm được.
                    - Hãy chủ động và ân cần hỏi thêm bệnh nhân xem họ có xuất hiện các triệu chứng vệ tinh khác không để giúp định vị bệnh chính xác hơn (Ví dụ: "Anh/Chị có kèm theo ho, nghẹt mũi, chảy dịch mũi hay đau rát họng nhiều không?").

                    Bước 3: Đưa ra thông tin cảnh báo & Hướng xử lý sơ bộ
                    - Tóm tắt nhanh "Mức độ nguy hiểm" và "Hướng xử lý" tại nhà (uống nhiều nước, súc họng, dùng paracetamol...) dựa vào đúng dữ liệu của cẩm nang ChromaDB mang lại.

                    Bước 4: Định hướng Chuyên khoa
                    - Dựa vào dữ liệu Chuyên khoa từ MySQL để khuyên họ nên đặt lịch hẹn tại chuyên khoa nào (Ví dụ: Khoa Nội tổng quát, Khoa Thần Kinh, Khoa Tai Mũi Họng...). 
                    - Nếu dữ liệu MySQL trống ([]), dựa trên chuyên môn y khoa của bạn để tự gợi ý chuyên khoa phù hợp nhất trong ứng dụng.

                    Phong cách phản hồi: Nhẹ nhàng, thấu hiểu, mang tính chuyên môn cao nhưng dễ hiểu đối với người dân. Sử dụng Markdown, gạch đầu dòng rõ ràng để người bệnh không bị ngợp thông tin.`;
                }

                else if (call.name === "lookup_my_prescription") {
                    console.log("AI GỌI HÀM: lookup_my_prescription -> UserId:", userId);
                    dbData = await ChatbotModel.getRecentPrescription(userId);
                    
                    prompt = `Người dùng vừa hỏi về đơn thuốc của họ.
                    Dựa vào dữ liệu đơn thuốc gần nhất từ Database: ${JSON.stringify(dbData)}.
                    - Nếu có dữ liệu ([] không rỗng): Hãy thông báo ngày khám, 
                    chuẩn đoán bệnh và liệt kê chi tiết các loại thuốc, liều dùng,
                    giờ uống một cách thân thiện. Nếu họ hỏi riêng về 1 loại thuốc 
                    trong danh sách đó, hãy hướng dẫn cách uống loại đó.
                    - Nếu trống rỗng ([]): Hãy xin lỗi và báo rằng hệ thống 
                    không tìm thấy lịch sử đơn thuốc nào gần đây của họ.`;
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

    // HÀM BỔ TRỢ: Rút gọn luồng xoay vòng Key lần 2
    static async handleAIRequestWithRotation(prompt) {
        let finalAttempts = 0;
        while (finalAttempts < API_KEYS.length) {
            try {
                return await getActiveModel().generateContent(prompt);
            } catch (aiError) {
                if (aiError.message && (aiError.message.includes('429') || aiError.message.includes('403') || aiError.message.includes('503') || aiError.message.includes('500'))) {
                    console.log(`[CẢNH BÁO LẦN 2] API Key thứ ${currentKeyIndex + 1} thất bại. Lý do: ${aiError.message}`);
                    console.log(`🔄 Đang chuyển sang API Key tiếp theo...`);
                    currentKeyIndex = (currentKeyIndex + 1) % API_KEYS.length;
                    finalAttempts++;
                } else { 
                    console.error(`[LỖI NGHIÊM TRỌNG] Quá trình gọi AI vòng 2 gặp sự cố:`, aiError);
                    throw aiError; 
                }
            }
        }
        return null; 
    }
}