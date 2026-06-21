import reviewModel from '../models/reviewModel.js';
import appointmentModel from '../models/AppointmentModel.js';

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

    // API Tạo đánh giá mới
    static async createReview(req, res) {
        try {
            // Hỗ trợ cả 2 cách đặt tên (Tiếng Việt từ Postman hoặc Tiếng Anh từ Flutter)
            const Ma_lich_hen = req.body.Ma_lich_hen || req.body.appointmentId;
            const So_sao = req.body.So_sao || req.body.rating;
            const Noi_dung = req.body.Noi_dung || req.body.comment;

            console.log(Ma_lich_hen);

            // 1. Kiểm tra dữ liệu đầu vào bắt buộc
            if (!Ma_lich_hen || !So_sao) {
                return res.status(400).json({
                    succeeded: false,
                    message: "Thiếu mã lịch hẹn hoặc số sao đánh giá."
                });
            }

            // 2. Lấy chi tiết lịch hẹn từ DB để lấy chính xác Ma_bac_si và Ma_benh_nhan
            const appointmentDetail = await appointmentModel.getAppointmentDetails(Ma_lich_hen);
            if (!appointmentDetail) {
                return res.status(404).json({
                    succeeded: false,
                    message: "Không tìm thấy thông tin lịch hẹn này."
                });
            }

            // 3. [Bảo mật] Kiểm tra xem người đang đăng nhập có đúng là người đi khám không
            // req.Ma_nguoi_dung lấy từ Middleware xác thực Token (JWT)
            if (req.Ma_nguoi_dung && appointmentDetail.Ma_nguoi_dung !== req.Ma_nguoi_dung) {
                return res.status(403).json({
                    succeeded: false,
                    message: "Bạn không có quyền đánh giá lịch hẹn của người khác."
                });
            }

            // 4. Đóng gói dữ liệu để truyền vào Model
            const reviewData = {
                Ma_lich_hen: Ma_lich_hen,
                So_sao: So_sao,
                Noi_dung: Noi_dung || "",
                Ma_bac_si: appointmentDetail.Ma_bac_si,
                Ma_benh_nhan: appointmentDetail.Ma_benh_nhan
            };

            // 5. Gọi hàm xử lý trong Model (Model đã tự check trạng thái 'done' và check trùng)
            const insertId = await reviewModel.createReview(reviewData);

            // 6. Trả về kết quả thành công cho Client
            return res.status(200).json({
                succeeded: true,
                message: "Cảm ơn bạn đã gửi đánh giá thành công!",
                data: { reviewId: insertId }
            });

        } catch (error) {
            // Khối catch này sẽ bắt trọn các lỗi điều kiện từ Model quăng ra 
            // ví dụ: "Lịch hẹn này chưa hoàn thành." hoặc "Bạn đã đáng giá lần khám này rồi."
            return res.status(500).json({
                succeeded: false,
                message: error.message
            });
        }
    }
}