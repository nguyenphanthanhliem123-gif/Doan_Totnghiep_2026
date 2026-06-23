import { execute } from "../config/db.js";

export default class ServiceModel{
    static async createService(serviceName, specId, doctorId, price){
        try{
            const sql = `
                INSERT INTO dich_vu (Ten_dich_vu, Ma_chuyen_khoa, Ma_bac_si, Gia_tien) VALUES (?, ?, ?, ?);
            `;

            const [result] = await execute(sql, [serviceName, specId, doctorId, price]);

            return result.insertId;
        }catch(error){
            throw new Error("Lỗi thêm dịch vụ: " + error.message);
        }
    }

    // Thêm tham số `id` để xác định bản ghi nào cần cập nhật (RẤT QUAN TRỌNG)
    static async updateService(id, serviceName, specId, price) {
        try {
            let updates = []; // Mảng chứa các đoạn gán: ["Ten_dich_vu = ?", "Gia_tien = ?"]
            let params = [];  // Mảng chứa giá trị truyền vào tương ứng

            if (serviceName != null) {
                updates.push("Ten_dich_vu = ?");
                params.push(serviceName);
            }

            if (specId != null) {
                updates.push("Ma_chuyen_khoa = ?");
                params.push(specId);
            }

            if (price != null) {
                updates.push("Gia_tien = ?");
                params.push(price);
            }

            // Trường hợp người dùng gọi API nhưng không truyền bất kỳ trường nào để sửa
            if (updates.length === 0) {
                return { succeeded: false, message: "Không có dữ liệu nào được thay đổi" };
            }

            // Tự động nối các phần tử bằng dấu phẩy thông qua hàm .join(', ')
            // Kết quả ví dụ: UPDATE dich_vu SET Ten_dich_vu = ?, Gia_tien = ? WHERE Ma_dich_vu = ?
            const sql = `
                UPDATE dich_vu 
                SET ${updates.join(', ')} 
                WHERE Ma_dich_vu = ?
            `;

            // Đẩy id của dịch vụ vào cuối mảng tham số ứng với dấu ? của WHERE
            params.push(id);

            
            const [result] = await execute(sql, params);
            return result;

        } catch (error) {
            throw new Error("Lỗi cập nhật dịch vụ: " + error.message);
        }
    }

    static async deleteService(serviceId){
        try{
            const [result] = await execute(`
                    DELETE FROM dich_vu WHERE Ma_dich_vu = ?
                `,[serviceId]);

            return result.affectedRows;
        }catch(error){
            throw new Error("Lỗi xóa dịch vụ: " + error.message)
        }
    }
}