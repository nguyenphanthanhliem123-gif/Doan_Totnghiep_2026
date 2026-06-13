import specialtyModel from "../models/specialtyModel.js";

export default class specialtyController{
    static async getAllSpecialty(req,res){
        try {
            const specialties = await specialtyModel.getAllSpecialties();
            return res.status(200).json({
                succeeded: true,
                specialties: specialties
            });
        } catch (error) {
            return res.status(500).json({
                succeeded: false,
                message: error.message
            });
        }
    }

    
}