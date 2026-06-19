import nodemailer from 'nodemailer';
import PDFDocument from 'pdfkit';
import path from 'path';
import { fileURLToPath } from 'url';

// Cấu hình tài khoản gửi Email
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS 
    }
});

export const taoVaGuiHoaDonPDF = async (data) => {
    return new Promise((resolve, reject) => {
        try {
            // Khởi tạo kích thước giấy A4 chuẩn
            const doc = new PDFDocument({ size: 'A4', margin: 50 });
            let buffers = [];
            
            doc.on('data', buffers.push.bind(buffers));
            
            // ==========================================
            // THIẾT KẾ GIAO DIỆN HÓA ĐƠN (VIP PRO)
            // ==========================================
            const __filename = fileURLToPath(import.meta.url);
            const __dirname = path.dirname(__filename);
            
            // 🌟 1. Cấu hình Font chữ (Sửa đường dẫn cho đúng với nơi bạn lưu font)
            // Nếu bạn chưa có file font, hãy tạm thời đổi tên biến này thành 'Helvetica' và 'Helvetica-Bold' (sẽ không gõ được dấu tiếng việt)
            const fontRegular = path.join(__dirname, 'Roboto-Regular.ttf');
            const fontBold = path.join(__dirname, 'Roboto-Bold.ttf');

            // Hàm vẽ đường kẻ ngang chuyên nghiệp
            const generateHr = (y) => {
                doc.strokeColor('#e0e0e0').lineWidth(1).moveTo(50, y).lineTo(545, y).stroke();
            };

            // Định dạng tiền tệ VNĐ
            const formatMoney = (money) => {
                return new Intl.NumberFormat('vi-VN').format(money) + ' đ';
            };

            // 🌟 2. HEADER: Thông tin phòng khám & Tiêu đề Hóa đơn
            doc.fillColor('#005983') // Màu xanh y tế
               .font(fontBold)
               .fontSize(20)
               .text(data.tenPhongKham, 50, 57);
               
            doc.fillColor('#555555')
               .font(fontRegular)
               .fontSize(10)
               .text(data.viTriPhongKham, 50, 80)
               .text('Điện thoại: 1900 1234', 50, 95)
               .text('Email: lienhe@phongkhamabc.com', 50, 110);

            // Chữ HÓA ĐƠN bám sát lề phải
            doc.fillColor('#333333')
               .font(fontBold)
               .fontSize(26)
               .text('BIÊN LAI', 50, 50, { align: 'right' });
            
            doc.font(fontRegular)
               .fontSize(10)
               .text(`Mã GD: ${data.maGiaoDich}`, 50, 85, { align: 'right' })
               .text(`Mã Lịch Hẹn: ${data.maBooking}`, 50, 100, { align: 'right' })
               .text(`Ngày lập: ${new Date().toLocaleDateString('vi-VN')}`, 50, 115, { align: 'right' });

            generateHr(145);

            // 🌟 3. THÔNG TIN KHÁCH HÀNG & DỊCH VỤ (Chia 2 cột)
            doc.fillColor('#333333')
               .font(fontBold)
               .fontSize(12)
               .text('Bệnh nhân:', 50, 170);
               
            doc.font(fontRegular)
               .fontSize(11)
               .text(data.tenBenhNhan, 50, 190)
               .text(data.emailNguoiDung, 50, 205);

            doc.font(fontBold)
               .fontSize(12)
               .text('Phụ trách chuyên môn:', 300, 170);
               
            doc.font(fontRegular)
               .fontSize(11)
               .text(`Bác sĩ: ${data.tenBacSi}`, 300, 190)
               .text(`Dịch vụ: ${data.tenDichVu}`, 300, 205);

            generateHr(240);

            // 🌟 4. BẢNG CHI TIẾT THANH TOÁN (TABLE)
            const tableTop = 270;
            
            // Tiêu đề bảng
            doc.font(fontBold)
               .fontSize(11)
               .fillColor('#005983')
               .text('MÔ TẢ DỊCH VỤ', 50, tableTop)
               .text('SỐ LƯỢNG', 300, tableTop, { width: 90, align: 'center' })
               .text('THÀNH TIỀN', 400, tableTop, { width: 145, align: 'right' });
            
            generateHr(290);

            // Nội dung bảng
            doc.font(fontRegular)
               .fillColor('#333333')
               .text(data.tenDichVu, 50, 305)
               .text('1', 300, 305, { width: 90, align: 'center' })
               .text(formatMoney(data.soTien), 400, 305, { width: 145, align: 'right' });

            generateHr(335);

            // 🌟 5. TỔNG CỘNG
            doc.font(fontBold)
               .fontSize(14)
               .text('TỔNG THANH TOÁN:', 200, 360, { width: 150, align: 'right' })
               .fillColor('#D32F2F') // Chữ màu đỏ nổi bật
               .text(formatMoney(data.soTien), 360, 360, { width: 185, align: 'right' });

            // 🌟 6. FOOTER (Chân trang)
            doc.font(fontRegular)
               .fontSize(10)
               .fillColor('#888888')
               .text('Cảm ơn Quý khách đã tin tưởng và sử dụng dịch vụ!', 50, 720, { align: 'center' })
               .text('Hóa đơn này được tạo tự động từ hệ thống thanh toán VNPay.', 50, 735, { align: 'center' });

            doc.end();

            // ==========================================
            // KẾT THÚC THIẾT KẾ - GỬI EMAIL
            // ==========================================
            doc.on('end', async () => {
                const pdfData = Buffer.concat(buffers);

                const mailOptions = {
                    from: '"Phòng Khám Đa Khoa ABC" <process.env.EMAIL_USER>',
                    to: data.emailNguoiDung,
                    subject: `[Phòng Khám ABC] Biên lai thanh toán thành công - Lịch hẹn ${data.maBooking}`,
                    html: `
                        <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                            <h2 style="color: #005983;">Thanh toán thành công!</h2>
                            <p>Kính chào <b>${data.tenBenhNhan}</b>,</p>
                            <p>Giao dịch thanh toán cho lịch hẹn khám bệnh của bạn đã được ghi nhận thành công.</p>
                            <ul>
                                <li><b>Mã lịch hẹn:</b> ${data.maBooking}</li>
                                <li><b>Bác sĩ phụ trách:</b> ${data.tenBacSi}</li>
                                <li><b>Số tiền đã thanh toán:</b> <span style="color: red; font-weight: bold;">${formatMoney(data.soTien)}</span></li>
                            </ul>
                            <p>Vui lòng xem biên lai chi tiết được đính kèm ở định dạng PDF trong email này.</p>
                            <br>
                            <p>Trân trọng,<br><b>Đội ngũ Phòng Khám Đa Khoa ABC</b></p>
                        </div>
                    `,
                    attachments: [
                        {
                            filename: `BienLai_${data.maBooking}.pdf`,
                            content: pdfData,
                            contentType: 'application/pdf'
                        }
                    ]
                };

                await transporter.sendMail(mailOptions);
                console.log(`✅ Đã gửi hóa đơn PDF (VIP) tới: ${data.emailNguoiDung}`);
                resolve(true);
            });
        } catch (error) {
            console.error("❌ Lỗi khi tạo và gửi hóa đơn PDF:", error);
            reject(error);
        }
    });
};