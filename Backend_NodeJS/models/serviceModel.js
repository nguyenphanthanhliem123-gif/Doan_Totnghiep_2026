import { beginTransaction, commitTransaction, execute, rollbackTransaction } from "../config/db.js";

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
            const sql = `SELECT * FROM danh_muc_dich_vu WHERE Trang_thai = 1 ORDER BY id DESC`;
            const [rows] = await execute(sql);
            return rows;
        } catch (error) {
            throw new Error("Lỗi khi lấy danh sách dịch vụ mẫu: " + error.message);
        }
    }

    static async deleteMasterService(id) {
        try {
            const sql = `UPDATE danh_muc_dich_vu SET Trang_thai = 0 WHERE id = ?`;
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
                AND Trang_thai = 1
                AND id NOT IN (
                    SELECT IFNULL(Ma_dv_goc, 0) FROM dich_vu WHERE Ma_bac_si = ? AND Trang_thai = 1
                )
            `;
            const [rows] = await execute(sql, [specId, doctorId]);
            console.log(rows);
            return rows;
        } catch (error) {
            throw new Error("Lỗi khi lấy danh sách dịch vụ gốc khả dụng: " + error.message);
        }
    }

    // Bác sĩ chọn dịch vụ gốc và lưu vào bảng dịch vụ cũ với GIÁ MẶC ĐỊNH
    static async addDoctorService(doctorId, masterServiceId) {
        try {
            // Lấy thông tin dịch vụ gốc
            const [master] = await execute(`SELECT * FROM danh_muc_dich_vu WHERE id = ?`, [masterServiceId]);
            if (!master || master.length === 0) {
                throw new Error("Dịch vụ gốc không tồn tại");
            }
            
            const { Ten_dich_vu, Ma_chuyen_khoa, Gia_mac_dinh } = master[0];

            const sql = `
                INSERT INTO dich_vu (Ten_dich_vu, Gia_tien, Ma_chuyen_khoa, Ma_bac_si, Ma_dv_goc) 
                VALUES (?, ?, ?, ?, ?)
            `;
            // Lưu Gia_mac_dinh vào cột Gia_tien
            return await execute(sql, [Ten_dich_vu, Gia_mac_dinh, Ma_chuyen_khoa, doctorId, masterServiceId]);
        } catch (error) {
            throw new Error("Lỗi khi bác sĩ thêm dịch vụ: " + error.message);
        }
    }

    // Lấy danh sách dịch vụ hiện tại của Bác sĩ (Bảng cũ)
    static async getDoctorServices(doctorId) {
        try {
            console.log("Đang lấy dịch vụ cho bác sĩ ID:", doctorId);
            const sql = `SELECT * FROM dich_vu WHERE Ma_bac_si = ? AND Trang_thai = 1`;
            const [rows] = await execute(sql, [doctorId]);
            return rows;
        } catch (error) {
            throw new Error("Lỗi khi lấy danh sách dịch vụ của bác sĩ: " + error.message);
        }
    }

    // Bác sĩ xóa dịch vụ khỏi danh sách của mình
    static async deleteDoctorService(serviceId, doctorId) {
        try {
            const sql = `UPDATE dich_vu SET Trang_thai = 0 WHERE Ma_dich_vu = ? AND Ma_bac_si = ?`;
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
                WHERE 1=1 AND d.Trang_thai = 1
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
        let conn = await beginTransaction();
        try {
            // Step 1: Kiểm tra trạng thái hiện tại của dịch vụ gốc
            const [masterService] = await conn.execute(
                `SELECT Trang_thai FROM danh_muc_dich_vu WHERE id = ?`, 
                [id]
            );

            if (masterService.length === 0) {
                throw new Error("SERVICE_NOT_FOUND"); // Lỗi không tìm thấy dịch vụ gốc
            }

            if (masterService[0].Trang_thai === 0) {
                // Trạng thái đã bằng 0, không cần thay đổi hay cập nhật gì thêm
                await commitTransaction(conn);
                return {
                    succeeded: true,
                    message: "Dịch vụ gốc đã ở trạng thái ngưng hoạt động trước đó."
                };
            }

            // Step 2: Kiểm tra xem có bác sĩ nào đang đăng ký dịch vụ này ở trạng thái hoạt động (Trang_thai = 1) không
            const [activeDoctors] = await conn.execute(
                `SELECT COUNT(*) as active_count FROM dich_vu WHERE Ma_dv_goc = ? AND Trang_thai = 1`,
                [id]
            );

            if (activeDoctors[0].active_count > 0) {
                // Có bác sĩ đang hoạt động sử dụng dịch vụ này -> Chặn xóa!
                throw new Error("ACTIVE_DOCTORS_EXIST");
            }

            // Step 3: Đạt điều kiện xóa (Không có bác sĩ nào dùng, hoặc tất cả bác sĩ dùng đều đã ở Trang_thai = 0)
            // Cập nhật Trạng_thai = 0 cho dịch vụ gốc
            const sqlMaster = `UPDATE danh_muc_dich_vu SET Trang_thai = 0 WHERE id = ?`;
            await conn.execute(sqlMaster, [id]);

            // Cập nhật đồng bộ toàn bộ dịch vụ của bác sĩ (cho những bản ghi có thể vẫn ở trạng thái khác)
            const sqlDoctorService = `UPDATE dich_vu SET Trang_thai = 0 WHERE Ma_dv_goc = ?`;
            await conn.execute(sqlDoctorService, [id]);

            await commitTransaction(conn);
            return {
                succeeded: true,
                message: "Đã xóa dịch vụ gốc và ẩn toàn bộ dịch vụ liên quan của các bác sĩ thành công."
            };
        } catch (error) {
            await rollbackTransaction(conn);
            throw error; // Quăng lỗi nguyên bản ra ngoài để Controller xử lý
        }
    }
}