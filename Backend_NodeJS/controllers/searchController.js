import SearchModel from "../models/searchModel.js";

export default class searchController{
    static async searchAll(req,res){
        try {
            const keyword = req.query.q || '';
            if (!keyword.trim()) {
                return res.status(200).json({ succeeded: true, data: { doctors: [], specialties: [], clinics: [] } });
            }

            const results = await SearchModel.globalSearch(keyword);
            return res.status(200).json({ succeeded: true, data: results });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }
}