import { GoogleGenerativeAI } from '@google/generative-ai';
import { execute } from "../config/db.js";
import { v4 as uuidv4 } from 'uuid'; // Import thư viện tạo ID ngẫu nhiên

// 1. Lưu danh sách Key vào mảng: Quản lý nhiều API key để tránh lỗi giới hạn
const API_KEYS = [
    process.env.GEMINI_API_KEY_1,
    process.env.GEMINI_API_KEY_2,
    process.env.GEMINI_API_KEY_3,
    process.env.GEMINI_API_KEY_4
].filter(Boolean); 

let currentKeyIndex = 0;

// Bù đúng 7 tiếng (7 * 60 phút * 60 giây * 1000 mili-giây) để ra giờ Việt Nam
const vnTime = new Date(new Date().getTime() + 7 * 60 * 60 * 1000).toISOString().split('T')[0];

// 2. Hàm động để lấy Model: Tự khởi tạo AI với cấu hình cho trước
function getActiveModel() {
    const genAI = new GoogleGenerativeAI(API_KEYS[currentKeyIndex]);
    return genAI.getGenerativeModel({ 
        model: "gemini-2.5-flash",
        // System Instruction: Thiết lập vai trò "cố định" cho AI
        systemInstruction: `Bạn là trợ lý AI ảo của App Hẹn Đặt Lịch Khám MedCare.
        Nhiệm vụ: Trả lời ngắn gọn, lịch sự về quy trình khám.
        1. Giấy tờ: CMND/CCCD, BHYT, sổ khám cũ.
        2. Thời gian: 15-30 phút (thêm 1-2 tiếng nếu xét nghiệm).
        3. Chi phí ban đầu: 150.000 VNĐ.
        4. Gửi xe: Xe máy miễn phí trước cửa, ô tô 30k ở ngã tư cách 50m.
        5. Giờ làm việc: 08:00 - 21:00 (T2-CN).`,
        // Định nghĩa công cụ để AI biết khi nào cần tìm bác sĩ hoặc tìm khung giờ trống
        tools: [{
            functionDeclarations: [
                {
                    name: "search_doctors",
                    description: "Dùng để tìm bác sĩ. Trả về danh sách bác sĩ.",
                    parameters: {
                        type: "OBJECT",
                        properties: {
                            specialty: { type: "STRING", description: "Tên chuyên khoa (VD: Nội khoa)" }
                        },
                        required: ["specialty"]
                    }
                },

                {
                    name: "search_doctor_available_slots",
                    description: "Dùng khi người dùng muốn tìm bác sĩ có lịch trống, hoặc hỏi xem một chuyên khoa nào đó còn khung giờ trống nào không.",
                    parameters: {
                        type: "OBJECT",
                        properties: {
                            specialty: { type: "STRING", description: "Tên chuyên khoa cần tìm lịch trống (VD: Răng Hàm Mặt, Nội tổng quát)" },
                            target_date: { type: "STRING", description: "Ngày khám người dùng muốn định dạng YYYY-MM-DD. Lưu ý: Hôm nay là " + vnTime },
                            time_of_day: { type: "STRING", description: "Buổi khám: 'morning' (sáng), 'afternoon' (chiều), 'evening' (tối). Để trống nếu không nhắc đến." }
                        },
                        required: ["specialty"]
                    }
                },

                {
                    name: "check_doctor_schedule",
                    description: "Dùng để kiểm tra lịch khám còn trống của một bác sĩ cụ thể khi người dùng nhắc trực tiếp tên bác sĩ.",
                    parameters: {
                        type: "OBJECT",
                        properties: {
                            doctor_name: { type: "STRING", description: "Tên bác sĩ (VD: Nguyễn Văn Alery, Alery)" }
                        },
                        required: ["doctor_name"]
                    }
                }
            ]
        }]
    });
}

export default class chatbotController {
    static async askQuestion(req, res) {
        try {
            // Lấy thông tin từ request của người dùng
            const { message, userId = 1, session_token: reqSessionToken } = req.body; 
            if (!message) return res.status(400).json({ success: false, message: "Vui lòng nhập câu hỏi." });

            let session_token = reqSessionToken;
            let chatHistoryText = "";

            // PHẦN 1 & 2: XỬ LÝ SESSION & TRÍ NHỚ (Lấy lịch sử từ DB để AI nhớ bối cảnh)
            if (session_token) {
                // Nếu đã có session, truy vấn lịch sử 10 tin nhắn gần nhất
                try {
                    const sqlGetHistory = `
                        SELECT tn.Vai_tro, tn.Noi_dung 
                        FROM tin_nhan_hoi_thoai tn
                        JOIN phien_hoi_thoai ph ON tn.Ma_hoi_thoai = ph.Ma_hoi_thoai
                        WHERE ph.Session_token = ?
                        ORDER BY tn.Ngay_tao ASC
                        LIMIT 10
                    `;
                    const [historyRows] = await execute(sqlGetHistory, [session_token]);
                    
                    if (historyRows && historyRows.length > 0) {
                        chatHistoryText = "--- Lịch sử trò chuyện trước đó ---\n";
                        historyRows.forEach(row => {
                            const sender = row.Vai_tro === 'user' ? 'Bệnh nhân' : 'AI';
                            chatHistoryText += `${sender}: ${row.Noi_dung}\n`;
                        });
                        chatHistoryText += "-----------------------------------\n\n";
                        console.log("Đã tải lịch sử chat thành công!");
                    }
                } catch (err) {
                    console.error("Lỗi lấy lịch sử chat:", err);
                }
            } else {
                // Nếu chưa có session, tạo phiên mới và lưu vào bảng phiên hội thoại
                session_token = uuidv4();
                try {
                    const sqlCreateSession = `INSERT INTO phien_hoi_thoai (Ma_nguoi_dung, Chu_de, Session_token, Bat_dau) VALUES (?, ?, ?, NOW())`;
                    await execute(sqlCreateSession, [userId, JSON.stringify(message), session_token]);
                    console.log("Đã tạo Session mới:", session_token);
                } catch (dbError) {
                    console.error("Lỗi tạo DB Session:", dbError);
                }
            }

            // Gộp lịch sử vào câu hỏi hiện tại để tạo ngữ cảnh hoàn chỉnh
            const finalMessageToAI = chatHistoryText + "Câu hỏi hiện tại của Bệnh nhân: " + message;

            // PHẦN: CƠ CHẾ ĐỔI KEY TỰ ĐỘNG (Xử lý khi vượt hạn mức API)
            let result;
            let attempts = 0;
            const maxAttempts = API_KEYS.length; 

            while (attempts < maxAttempts) {
                try {
                    const currentModel = getActiveModel();
                    result = await currentModel.generateContent(finalMessageToAI);
                    break; 
                } catch (aiError) {
                    // Nếu lỗi do hạn mức (429/403), chuyển sang key tiếp theo
                    if (aiError.message && (aiError.message.includes('429') || aiError.message.includes('403'))) {
                        console.log(`Key thứ ${currentKeyIndex + 1} gặp lỗi. Đang chuyển sang Key tiếp theo...`);
                        
                        currentKeyIndex = (currentKeyIndex + 1) % API_KEYS.length;
                        attempts++;
                    } else {
                        throw aiError;
                    }
                }
            }

            if (!result) {
                return res.status(500).json({ success: false, message: "Tất cả API Key đều đã hết hạn mức. Vui lòng thử lại vào ngày mai!" });
            }
            
            // LƯỚI AN TOÀN: Kiểm tra AI có gọi hàm tìm bác sĩ hay không
            let call = null;
            if (result.response.functionCalls) {
                const calls = typeof result.response.functionCalls === 'function' 
                              ? result.response.functionCalls() 
                              : result.response.functionCalls;
                if (calls && calls.length > 0) {
                    call = calls[0];
                }
            }

            // XỬ LÝ KHI CÓ GỌI HÀM TÌM BÁC SĨ THEO CHUYÊN KHOA
            if (call && call.name === "search_doctors") {
                console.log("AI ĐÃ NHẬN DIỆN HÀM:", call.args.specialty);
                
                const doctors = await chatbotController.handleSearchDoctors(call.args.specialty);
                
                const prompt = `Dựa vào danh sách bác sĩ sau: ${JSON.stringify(doctors)}. 
                Hãy trả lời thân thiện, liệt kê rõ tên, học vị và 
                điểm đánh giá của từng bác sĩ, sau đó mời họ đặt lịch.`;
                
                let finalResult = await chatbotController.handleAIRequestWithRotation(prompt);
                if (!finalResult) return res.status(500).json({ success: false, message: "Hệ thống AI quá tải." });

                await chatbotController.saveMessagesToDB(session_token, message, finalResult.response.text());
                
                return res.status(200).json({ success: true, reply: finalResult.response.text(), session_token });
            }

            // XỬ LÝ KHI GỌI HÀM: TÌM BÁC SĨ THEO CHUYÊN KHOA KÈM LỊCH TRỐNG
            if (call && call.name === "search_doctor_available_slots") {
                console.log("AI ĐÃ NHẬN DIỆN HÀM TÌM LỊCH TRỐNG KHOA:", call.args.specialty);
                
                // Gọi hàm lấy cả bác sĩ và lịch trống từ database
                const slots = await chatbotController.handleSearchAvailableSlots(call.args.specialty, call.args.target_date, call.args.time_of_day);
                
                const prompt = `Dựa vào danh sách lịch khám còn trống sau đây của chuyên khoa: ${JSON.stringify(slots)}.
                Hãy trả lời thân thiện, liệt kê rõ tên bác sĩ, học vị, 
                điểm đánh giá và các khung giờ (Thời gian bắt đầu đến kết thúc) 
                còn trống tương ứng để bệnh nhân lựa chọn.`;
                
                let finalResult = await chatbotController.handleAIRequestWithRotation(prompt);
                if (!finalResult) return res.status(500).json({ success: false, message: "Hệ thống AI quá tải." });

                await chatbotController.saveMessagesToDB(session_token, message, finalResult.response.text());
                
                return res.status(200).json({ success: true, reply: finalResult.response.text(), session_token });
            }

            // XỬ LÝ KHI GỌI HÀM: TÌM LỊCH TRỐNG THEO TÊN BÁC SĨ
            if (call && call.name === "check_doctor_schedule") {
                console.log("AI ĐÃ NHẬN DIỆN HÀM KIỂM TRA LỊCH BÁC SĨ:", call.args.doctor_name);
                
                const slots = await chatbotController.handleCheckDoctorSchedule(call.args.doctor_name);
                
                const prompt = `Dựa vào dữ liệu lịch trống sau đây của bác sĩ: ${JSON.stringify(slots)}.
                Nếu có lịch: Hãy trả lời thân thiện, thông báo tên bác sĩ, 
                chuyên khoa, và các khung giờ còn trống.
                Nếu trống rỗng ([]): Hãy xin lỗi và báo rằng bác sĩ này hiện tại
                đã kín lịch hoặc không có lịch khám trong hệ thống.`;
                
                let finalResult = await chatbotController.handleAIRequestWithRotation(prompt);
                if (!finalResult) return res.status(500).json({ success: false, message: "Hệ thống AI quá tải." });

                await chatbotController.saveMessagesToDB(session_token, message, finalResult.response.text());
                
                return res.status(200).json({ success: true, reply: finalResult.response.text(), session_token });
            }

            // XỬ LÝ MẶC ĐỊNH: Trả lời không cần gọi hàm và lưu lịch sử
            const replyText = result.response.text();
            await chatbotController.saveMessagesToDB(session_token, message, replyText);

            return res.status(200).json({ success: true, reply: replyText, session_token });

        } catch (error) {
            console.error("LỖI AI:", error);
            return res.status(500).json({ success: false, message: "AI đang bận.", error: error.message });
        }
    }

    // HÀM BỔ TRỢ: Tách luồng xoay Key lần 2 ra ngoài giúp code sạch gọn hơn
    static async handleAIRequestWithRotation(prompt) {
        let finalResult;
        let finalAttempts = 0;
        while (finalAttempts < API_KEYS.length) {
            try {
                const currentModel = getActiveModel();
                finalResult = await currentModel.generateContent(prompt);
                return finalResult;
            } catch (aiError) {
                if (aiError.message && (aiError.message.includes('429') || aiError.message.includes('403'))) {
                    console.log(`Key thứ ${currentKeyIndex + 1} lỗi ở bước tổng hợp. Đang chuyển Key...`);
                    currentKeyIndex = (currentKeyIndex + 1) % API_KEYS.length;
                    finalAttempts++;
                } else { throw aiError; }
            }
        }
        return null;
    }

    // HÀM BỔ TRỢ: Lưu tin nhắn hội thoại vào DB
    static async saveMessagesToDB(session_token, userMsg, botMsg) {
        try {
            const sqlSaveMessage = `INSERT INTO tin_nhan_hoi_thoai (Ma_hoi_thoai, Vai_tro, Noi_dung) VALUES ((SELECT Ma_hoi_thoai FROM phien_hoi_thoai WHERE Session_token = ? LIMIT 1), ?, ?)`;
            await execute(sqlSaveMessage, [session_token, 'user', userMsg]);
            await execute(sqlSaveMessage, [session_token, 'chatbot', botMsg]);
            console.log("Đã lưu lịch sử 2 tin nhắn vào DB thành công!");
        } catch (msgError) { console.error("Lỗi lưu tin nhắn vào DB:", msgError); }
    }

    // HÀM BỔ TRỢ: Truy vấn SQL tìm bác sĩ theo chuyên khoa
    static async handleSearchDoctors(specialty) {
        try {
            console.log("Đang truy vấn Database thật tìm bác sĩ khoa:", specialty);
            const query = `
                SELECT bs.Ma_bac_si, nd.Ten_nguoi_dung AS ten_bac_si, ck.Ten_chuyen_khoa, bs.Hoc_vi, AVG(dg.So_sao) AS diem_danh_gia
                FROM bac_si bs
                JOIN nguoi_dung nd ON bs.Ma_nguoi_dung = nd.Ma_nguoi_dung
                JOIN chuyen_khoa ck ON bs.Ma_chuyen_khoa = ck.Ma_chuyen_khoa
                LEFT JOIN danh_gia dg ON bs.Ma_bac_si = dg.Ma_bac_si
                WHERE ck.Ten_chuyen_khoa LIKE ?
                GROUP BY bs.Ma_bac_si ORDER BY diem_danh_gia DESC LIMIT 5;
            `;
            const [rows] = await execute(query, [`%${specialty}%`]);
            return rows;
        } catch (error) { console.error("Lỗi truy vấn SQL tìm bác sĩ:", error); return []; }
    }

    // HÀM BỔ TRỢ: Truy vấn SQL tìm bác sĩ theo chuyên khoa kèm khung giờ TRỐNG ('available')
    static async handleSearchAvailableSlots(specialty, targetDate = null, timeOfDay = null) {
        try {
            console.log(`Đang tìm lịch trống - Khoa: ${specialty}, Ngày: ${targetDate}, Buổi: ${timeOfDay}`);
            
            // Câu lệnh JOIN kết hợp tìm thông tin bác sĩ, điểm đánh giá và lịch khám còn trống
            let query = `
                SELECT 
                    bs.Ma_bac_si, nd.Ten_nguoi_dung AS ten_bac_si, ck.Ten_chuyen_khoa, bs.Hoc_vi,
                    AVG(dg.So_sao) AS diem_danh_gia, kg.Ma_khung_gio,
                    DATE_FORMAT(kg.Thoi_gian_Bdau, '%Y-%m-%d %H:%i') AS start_time,
                    DATE_FORMAT(kg.Thoi_gian_Kthuc, '%H:%i') AS end_time
                FROM khung_gio_kham kg
                JOIN bac_si bs ON kg.Ma_bac_si = bs.Ma_bac_si
                JOIN nguoi_dung nd ON bs.Ma_nguoi_dung = nd.Ma_nguoi_dung
                JOIN chuyen_khoa ck ON bs.Ma_chuyen_khoa = ck.Ma_chuyen_khoa
                LEFT JOIN danh_gia dg ON bs.Ma_bac_si = dg.Ma_bac_si
                WHERE ck.Ten_chuyen_khoa LIKE ? AND kg.Trang_thai = 'available'
            `;
            
            let params = [`%${specialty}%`];

            // Nếu AI bóc tách được người dùng có yêu cầu ngày cụ thể
            if (targetDate) {
                query += ` AND DATE(kg.Thoi_gian_Bdau) = ?`;
                params.push(targetDate);
            }
            
            // Nếu AI bóc tách được buổi sáng/chiều/tối
            if (timeOfDay === 'morning') {
                query += ` AND HOUR(kg.Thoi_gian_Bdau) < 12`;
            } else if (timeOfDay === 'afternoon') {
                query += ` AND HOUR(kg.Thoi_gian_Bdau) >= 12 AND HOUR(kg.Thoi_gian_Bdau) < 17`;
            } else if (timeOfDay === 'evening') {
                query += ` AND HOUR(kg.Thoi_gian_Bdau) >= 17`;
            }

            query += `
                GROUP BY kg.Ma_khung_gio, bs.Ma_bac_si
                ORDER BY diem_danh_gia DESC, kg.Thoi_gian_Bdau ASC
                LIMIT 15;
            `;
            
            const [rows] = await execute(query, params);
            return rows;
        } catch (error) {
            console.error("Lỗi SQL lịch trống:", error);
            return [];
        }
    }

    // HÀM BỔ TRỢ: Truy vấn SQL tìm lịch trống theo TÊN BÁC SĨ
    static async handleCheckDoctorSchedule(doctorName) {
        try {
            console.log("Đang truy vấn Database tìm lịch của bác sĩ:", doctorName);
            
            // Dùng LIKE trên cột Ten_nguoi_dung thay vì Ten_chuyen_khoa
            const query = `
                SELECT 
                    bs.Ma_bac_si,
                    nd.Ten_nguoi_dung AS ten_bac_si,
                    ck.Ten_chuyen_khoa,
                    kg.Ma_khung_gio,
                    DATE_FORMAT(kg.Thoi_gian_Bdau, '%Y-%m-%d %H:%i') AS start_time,
                    DATE_FORMAT(kg.Thoi_gian_Kthuc, '%H:%i') AS end_time
                FROM khung_gio_kham kg
                JOIN bac_si bs ON kg.Ma_bac_si = bs.Ma_bac_si
                JOIN nguoi_dung nd ON bs.Ma_nguoi_dung = nd.Ma_nguoi_dung
                JOIN chuyen_khoa ck ON bs.Ma_chuyen_khoa = ck.Ma_chuyen_khoa
                WHERE nd.Ten_nguoi_dung LIKE ? AND kg.Trang_thai = 'available'
                ORDER BY kg.Thoi_gian_Bdau ASC
                LIMIT 10;
            `;
            
            // Tìm kiếm tương đối để dù user gõ "Alery" hay "Nguyễn Văn Alery" đều ra
            const [rows] = await execute(query, [`%${doctorName}%`]);
            return rows;
        } catch (error) {
            console.error("Lỗi truy vấn SQL lịch bác sĩ:", error);
            return [];
        }
    }
}