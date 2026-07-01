import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import { ChromaClient } from 'chromadb';
import { GoogleGenerativeAI } from '@google/generative-ai';

// 🌐 SỬA LỖI ENV: Ép Node.js tìm file .env bằng đường dẫn tuyệt đối độc lập
const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(__dirname, '../.env') });

// 🛠️ SỬA CẢNH BÁO PATH DEPRECATED: Chuyển sang dùng host và port chuẩn cấu trúc mới
const chromaClient = new ChromaClient({ host: "localhost", port: 8000 });

// 🧠 FIX LỖI DefaultEmbeddingFunction: Hàm dummy để bypass kiểm tra của ChromaDB
// Vì chúng ta đã tự tính toán Vector bằng Gemini nên hàm này chỉ mang tính chất khai báo thủ tục
const dummyEmbeddingFunction = {
    generate: async (texts) => Array(texts.length).fill([])
};

// Lấy danh sách 3 API Key của bạn từ file .env
const API_KEYS = [
    process.env.GEMINI_API_KEY_1,
    process.env.GEMINI_API_KEY_2,
    process.env.GEMINI_API_KEY_3,
    process.env.GEMINI_API_KEY_4,
    process.env.GEMINI_API_KEY_5,
].filter(Boolean);

let currentKeyIndex = 0;

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// HÀM BỔ TRỢ: Đổi văn bản thuần thành mảng số Vector có chống sập bằng xoay vòng Key
async function getEmbedding(text) {
    if (API_KEYS.length === 0) {
        throw new Error("❌ CẢNH BÁO TỐI NGUY HIỂM: Hệ thống vẫn không thể đọc được file .env của bạn.");
    }

    let attempts = 0;
    while (attempts < API_KEYS.length) {
        try {
            const genAI = new GoogleGenerativeAI(API_KEYS[currentKeyIndex]);
            const embeddingModel = genAI.getGenerativeModel({ model: "gemini-embedding-001" });
            
            const result = await embeddingModel.embedContent(text);
            
            // 🕒 Giãn cách an toàn: Sau khi tạo công thành công 1 cụm, nghỉ 350ms 
            // giúp luồng chạy seed không bị đẩy tốc độ lên quá cao dẫn đến dính 429
            await sleep(350); 
            
            return result.embedding.values; 

        } catch (error) {
            // 🛑 HIỂN THỊ LỖI THẬT: In ra lý do chính xác từ Google (error.message) để dễ debug
            const errMsg = error.message || String(error);
            console.warn(`⚠️ [XỬ LÝ LỖI KEY] API Key số ${currentKeyIndex + 1} thất bại. Chi tiết: ${errMsg}`);
            
            // Nếu dính lỗi 429 hoặc lỗi cạn kiệt tài nguyên tạm thời từ Google
            if (errMsg.includes('429') || errMsg.includes('ResourceExhausted') || errMsg.includes('Quota')) {
                console.log(`⏳ Phát hiện giới hạn tốc độ (429/Quota). Tạm dừng luồng 2 giây để giãn cách trước khi đổi sang Key tiếp theo...`);
                await sleep(2000); // Nghỉ 2 giây nhằm đánh lừa bộ quét spam của Google
            }
            
            currentKeyIndex = (currentKeyIndex + 1) % API_KEYS.length;
            attempts++;
        }
    }
    
    throw new Error(`❌ CẠN KIỆT TOÀN BỘ KEY: Đã thử xoay vòng qua tất cả ${API_KEYS.length} keys nhưng đều bị Google từ chối do spam tốc độ cao hoặc hết sạch quota ngày.`);
}

export default class ChromaService {

    // =========================================================================
    // 1. COLLECTION: medical_knowledge (Tư vấn triệu chứng & Nhóm bệnh)
    // =========================================================================
    static async searchMedicalKnowledge(userSymptom) {
        const collection = await chromaClient.getOrCreateCollection({ 
            name: "medical_knowledge",
            embeddingFunction: dummyEmbeddingFunction // 👈 Ép dùng hàm dummy để sửa lỗi Instantiate
        });
        const queryVector = await getEmbedding(userSymptom);

        const results = await collection.query({
            queryEmbeddings: [queryVector],
            nResults: 1 
        });
        return results.documents[0]; 
    }

    // =========================================================================
    // 2. COLLECTION: drug_database (Cảnh báo dị ứng thuốc)
    // =========================================================================
    static async checkDrugInteraction(drugName, patientAllergyHistory) {
        const collection = await chromaClient.getOrCreateCollection({ 
            name: "drug_database",
            embeddingFunction: dummyEmbeddingFunction
        });
        const queryVector = await getEmbedding(`${drugName} ${patientAllergyHistory}`);

        const results = await collection.query({
            queryEmbeddings: [queryVector],
            nResults: 1
        });
        return results.documents[0];
    }

    // =========================================================================
    // 3. COLLECTION: doctor_profiles_vec (Tìm kiếm semantic bác sĩ)
    // =========================================================================
    static async searchDoctorSemantic(searchQuery) {
        const collection = await chromaClient.getOrCreateCollection({ 
            name: "doctor_profiles_vec",
            embeddingFunction: dummyEmbeddingFunction
        });
        const queryVector = await getEmbedding(searchQuery);

        const results = await collection.query({
            queryEmbeddings: [queryVector],
            nResults: 3 
        });
        
        return results.metadatas[0]; 
    }

    // =========================================================================
    // 4. COLLECTION: aftercare_knowledge (Chatbot after-care)
    // =========================================================================
    static async getAftercareInstructions(diseaseNameOrTreatment) {
        const collection = await chromaClient.getOrCreateCollection({ 
            name: "aftercare_knowledge",
            embeddingFunction: dummyEmbeddingFunction
        });
        const queryVector = await getEmbedding(diseaseNameOrTreatment);

        const results = await collection.query({
            queryEmbeddings: [queryVector],
            nResults: 1 
        });
        return results.documents[0];
    }

    // =========================================================================
    // HÀM BỔ TRỢ: Dùng để nạp dữ liệu y tế (Seed Data) vào ChromaDB khi cần thiết
    // =========================================================================
    static async addDataToCollection(collectionName, id, textContent, metadata = {}) {
        const collection = await chromaClient.getOrCreateCollection({ 
            name: collectionName,
            embeddingFunction: dummyEmbeddingFunction // 👈 Ép dùng hàm dummy để sửa lỗi Instantiate
        });
        const vector = await getEmbedding(textContent);

        await collection.add({
            ids: [id],
            embeddings: [vector],
            metadatas: [metadata],
            documents: [textContent]
        });
        console.log(`[ChromaDB] Đã nạp thành công: ${id}`);
    }
}