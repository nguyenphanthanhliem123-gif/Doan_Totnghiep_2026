import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import { ChromaClient } from 'chromadb';
import { pipeline } from '@xenova/transformers';

// Ép Node.js tìm file .env bằng đường dẫn tuyệt đối độc lập
const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(__dirname, '../.env') });

// Chuyển sang dùng host và port chuẩn cấu trúc mới
const chromaClient = new ChromaClient({ host: "localhost", port: 8000 });

// Hàm dummy để bypass kiểm tra của ChromaDB
const dummyEmbeddingFunction = {
    generate: async (texts) => Array(texts.length).fill([])
};

// Biến toàn cục để lưu trữ model sau khi nạp vào RAM (Singleton Pattern)
let embeddingPipeline = null;

// HÀM TÍNH VECTOR LOCAL: Đổi văn bản thuần thành mảng số Vector (Chạy Offline 100%)
async function getLocalEmbedding(text) {
    try {
        if (!embeddingPipeline) {
            console.log("⏳ Lần đầu khởi chạy: Đang nạp model Embedding Local vào RAM (Khoảng ~120MB)...");
            // Tải bản nén quantized tối ưu tuyệt đối
            embeddingPipeline = await pipeline('feature-extraction', 'Xenova/paraphrase-multilingual-MiniLM-L12-v2');
            console.log("✅ Nạp model Embedding thành công! Sẵn sàng xử lý.");
        }
        
        const output = await embeddingPipeline(text, { pooling: 'mean', normalize: true });
        // Chuyển kết quả từ Tensor thành mảng Array thông thường để nạp vào ChromaDB
        return Array.from(output.data);
    } catch (error) {
        console.error("❌ Lỗi tính toán Embedding Local:", error);
        throw error;
    }
}

export default class ChromaService {

    // =========================================================================
    // 1. COLLECTION: medical_knowledge (Tư vấn triệu chứng & Nhóm bệnh)
    // =========================================================================
    static async searchMedicalKnowledge(userSymptom) {
        const collection = await chromaClient.getOrCreateCollection({ 
            name: "medical_knowledge_v2",
            embeddingFunction: dummyEmbeddingFunction 
        });
        const queryVector = await getLocalEmbedding(userSymptom);

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
            name: "drug_database_v2",
            embeddingFunction: dummyEmbeddingFunction
        });
        const queryVector = await getLocalEmbedding(`${drugName} ${patientAllergyHistory}`);

        const __results = await collection.query({
            queryEmbeddings: [queryVector],
            nResults: 1
        });
        return __results.documents[0];
    }

    // =========================================================================
    // 3. COLLECTION: doctor_profiles_vec (Tìm kiếm semantic bác sĩ)
    // =========================================================================
    static async searchDoctorSemantic(searchQuery) {
        const collection = await chromaClient.getOrCreateCollection({ 
            name: "doctor_profiles_vec_v2",
            embeddingFunction: dummyEmbeddingFunction
        });
        const queryVector = await getLocalEmbedding(searchQuery);

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
            name: "aftercare_knowledge_v2",
            embeddingFunction: dummyEmbeddingFunction
        });
        const queryVector = await getLocalEmbedding(diseaseNameOrTreatment);

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
            embeddingFunction: dummyEmbeddingFunction 
        });
        const vector = await getLocalEmbedding(textContent);

        await collection.add({
            ids: [id],
            embeddings: [vector],
            metadatas: [metadata],
            documents: [textContent]
        });
        console.log(`[ChromaDB] Đã nạp thành công dữ liệu local: ${id}`);
    }
}