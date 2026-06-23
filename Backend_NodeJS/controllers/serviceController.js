import doctorModel from "../models/doctorModel.js";
import ServiceModel from "../models/serviceModel.js";

export default class ServiceController{
    static async createService (req,res){
        try{
            const userId = req.Ma_nguoi_dung;

            const { serviceName, specId, price } = req.body;

            if(!serviceName || !specId || !price) return res.status(400).json({
                succeeded: false,
                message: "Thiếu thông tin dịch vụ"
            });

            const doctorDetail = await doctorModel.getDoctorDetailByUserID(userId);

            await ServiceModel.createService(serviceName, specId, doctorDetail.Ma_bac_si, price);
            return res.status(200).json({
                succeeded: true
            });
        }catch(error){
            return res.status(500).json({
                succeeded: false,
                message: error.message
            });
        }
    }

    static async updateService(req,res){
        try{
            const { serviceId } = req.params;

            const { serviceName, specId, price } = req.body;

            if(!serviceId) return res.status(400).json({
                succeeded: false,
                message: "Thiếu id dịch vụ"
            });
            const numericServiceId = parseInt(serviceId, 10);

            await ServiceModel.updateService(numericServiceId, serviceName, specId, price);

            return res.status(200).json({
                succeeded: true
            });
        }catch(error){
            return res.status(500).json({
                succeeded: false,
                message: error.message
            });
        }
    }

    static async deleteService(req,res){
        try{
            const { serviceId } = req.params;

            if(!serviceId) return res.status(400).json({
                succeeded: false,
                message: "Thiếu id dịch vụ"
            });

            await ServiceModel.deleteService(serviceId);

            return res.status(200).json({
                succeeded: true
            });
        }catch(error){
            return res.status(500).json({
                succeeded: false,
                message: error.message
            });
        }
    }
}