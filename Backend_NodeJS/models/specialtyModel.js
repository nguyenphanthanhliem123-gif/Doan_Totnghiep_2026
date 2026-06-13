import { execute } from "../config/db.js";

export default class specialtyModel{
    static async getAllSpecialties() {
        try {
            const [rows] = await execute(
                `SELECT Ma_chuyen_khoa, Ten_chuyen_khoa, Mo_ta, Icon 
                FROM chuyen_khoa`
            );
            return rows;
        } catch (error) {
            throw new Error('Lỗi database (specialtyModel.getAllSpecialties): ' + error.message);
        }
    }
}