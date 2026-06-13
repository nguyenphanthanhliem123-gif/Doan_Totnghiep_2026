import reviewModel from '../models/reviewModel.js';

export default class reviewController {
    // API lấy danh sách đánh giá của bác sĩ theo Ma_bac_si
    static async getReviewsByDoctorId(req, res) {
        try {
            const { doctorId } = req.params;
            if (!doctorId) {
                return res.status(400).json({ succeeded: false, message: "Thiếu mã bác sĩ" });
            }

            const reviews = await reviewModel.getReviewsByDoctorId(doctorId);
            return res.status(200).json({ succeeded: true, data: reviews });
        } catch (error) {
            return res.status(500).json({ succeeded: false, message: error.message });
        }
    }
}