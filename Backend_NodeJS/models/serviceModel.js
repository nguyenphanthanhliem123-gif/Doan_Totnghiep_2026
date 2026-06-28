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

    static async createMasterService(name, specId, defaultPrice) {
        try {
            const sql = `INSERT INTO danh_muc_dich_vu (Ten_dich_vu, Ma_chuyen_khoa, Gia_mac_dinh) VALUES (?, ?, ?)`;
            return await execute(sql, [name, specId, defaultPrice]);
        } catch (error) {
            throw new Error("Lỗi khi tạo dịch vụ mẫu: " + error.message);
        }
    }

    static async getAllMasterServices() {
        try {
            const sql = `SELECT * FROM danh_muc_dich_vu ORDER BY id DESC`;
            const [rows] = await execute(sql);
            return rows;
        } catch (error) {
            throw new Error("Lỗi khi lấy danh sách dịch vụ mẫu: " + error.message);
        }
    }

    static async deleteMasterService(id) {
        try {
            const sql = `DELETE FROM danh_muc_dich_vu WHERE id = ?`;
            return await execute(sql, [id]);
        } catch (error) {
            throw new Error("Lỗi khi xóa dịch vụ mẫu: " + error.message);
        }
    }

    // --- CHO BÁC SĨ ---

    // Lấy các dịch vụ gốc thuộc chuyên khoa của bác sĩ mà bác sĩ CHƯA chọn
    static async getAvailableMasterServices(specId, doctorId) {
        try {
            const sql = `
                SELECT * FROM danh_muc_dich_vu 
                WHERE Ma_chuyen_khoa = ? 
                AND id NOT IN (
                    SELECT IFNULL(Ma_dv_goc, 0) FROM dich_vu WHERE Ma_bac_si = ?
                )
            `;
            const [rows] = await execute(sql, [specId, doctorId]);
            console.log(rows);
            return rows;
        } catch (error) {
            throw new Error("Lỗi khi lấy danh sách dịch vụ gốc khả dụng: " + error.message);
        }
    }

    // Bác sĩ chọn dịch vụ gốc và lưu vào bảng dịch vụ cũ kèm giá tùy chỉnh
    static async addDoctorService(doctorId, masterServiceId, customPrice) {
        try {
            // Lấy thông tin dịch vụ gốc trước để copy Tên và Mã chuyên khoa
            const [master] = await execute(`SELECT * FROM danh_muc_dich_vu WHERE id = ?`, [masterServiceId]);
            if (!master || master.length === 0) {
                throw new Error("Dịch vụ gốc không tồn tại");
            }
            
            const { Ten_dich_vu, Ma_chuyen_khoa } = master[0];

            const sql = `
                INSERT INTO dich_vu (Ten_dich_vu, Gia_tien, Ma_chuyen_khoa, Ma_bac_si, Ma_dv_goc) 
                VALUES (?, ?, ?, ?, ?)
            `;
            return await execute(sql, [Ten_dich_vu, customPrice, Ma_chuyen_khoa, doctorId, masterServiceId]);
        } catch (error) {
            throw new Error("Lỗi khi bác sĩ thêm dịch vụ cấu hình: " + error.message);
        }
    }

    // Lấy danh sách dịch vụ hiện tại của Bác sĩ (Bảng cũ)
    static async getDoctorServices(doctorId) {
        try {
            console.log("Đang lấy dịch vụ cho bác sĩ ID:", doctorId);
            const sql = `SELECT * FROM dich_vu WHERE Ma_bac_si = ?`;
            const [rows] = await execute(sql, [doctorId]);
            return rows;
        } catch (error) {
            throw new Error("Lỗi khi lấy danh sách dịch vụ của bác sĩ: " + error.message);
        }
    }

    // Bác sĩ xóa dịch vụ khỏi danh sách của mình
    static async deleteDoctorService(serviceId, doctorId) {
        try {
            const sql = `DELETE FROM dich_vu WHERE Ma_dich_vu = ? AND Ma_bac_si = ?`;
            return await execute(sql, [serviceId, doctorId]);
        } catch (error) {
            throw new Error("Lỗi khi gỡ dịch vụ của bác sĩ: " + error.message);
        }
    }

    static async getMasterServices(searchTerm = '', specialtyId = '') {
        try {
            let sql = `
                SELECT d.*, c.Ten_chuyen_khoa 
                FROM danh_muc_dich_vu d
                LEFT JOIN chuyen_khoa c ON d.Ma_chuyen_khoa = c.Ma_chuyen_khoa
                WHERE 1=1
            `;
            let params = [];

            if (searchTerm) {
                sql += ` AND d.Ten_dich_vu LIKE ?`;
                params.push(`%${searchTerm}%`);
            }
            
            if (specialtyId) {
                sql += ` AND d.Ma_chuyen_khoa = ?`;
                params.push(specialtyId);
            }

            sql += ` ORDER BY d.Created_at DESC`;
            
            const [rows] = await execute(sql, params);
            return rows;
        } catch (error) {
            throw new Error("Lỗi lấy danh sách dịch vụ: " + error.message);
        }
    }

    static async createMasterService(name, specId, defaultPrice) {
        try {
            const sql = `INSERT INTO danh_muc_dich_vu (Ten_dich_vu, Ma_chuyen_khoa, Gia_mac_dinh, Created_at) VALUES (?, ?, ?, NOW())`;
            const [result] = await execute(sql, [name, specId, defaultPrice]);
            return result.insertId;
        } catch (error) {
            throw new Error("Lỗi thêm dịch vụ gốc: " + error.message);
        }
    }

    static async updateMasterService(id, name, specId, defaultPrice) {
        try {
            const sql = `UPDATE danh_muc_dich_vu SET Ten_dich_vu = ?, Ma_chuyen_khoa = ?, Gia_mac_dinh = ? WHERE id = ?`;
            return await execute(sql, [name, specId, defaultPrice, id]);
        } catch (error) {
            throw new Error("Lỗi cập nhật dịch vụ gốc: " + error.message);
        }
    }

    static async deleteMasterService(id) {
        try {
            // LƯU Ý: Nếu DB có khóa ngoại ràng buộc bác sĩ đang dùng dịch vụ này, cần cân nhắc dùng "Soft Delete" (ẩn đi) thay vì xóa cứng.
            const sql = `DELETE FROM danh_muc_dich_vu WHERE id = ?`;
            return await execute(sql, [id]);
        } catch (error) {
            throw new Error("Lỗi xóa dịch vụ gốc: " + error.message);
        }
    }
}