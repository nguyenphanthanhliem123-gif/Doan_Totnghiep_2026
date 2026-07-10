// file: seedKnowledge.js
import ChromaService from "./chromaService.js";

async function seed() {
    console.log("⏳ Đang khởi tạo dữ liệu nhóm bệnh y tế...");

    // =========================================================================
    // 1. NHÓM BỆNH: Nhiễm trùng đường hô hấp cấp tính (Cúm, Viêm họng, Viêm mũi xoang)
    // =========================================================================
    const hoHapCap = `Nhóm bệnh: Nhiễm trùng đường hô hấp cấp tính (Bao gồm Cúm thường, Cúm A/B, Viêm họng cấp, Viêm mũi xoang).
    - Triệu chứng điển hình: Người bệnh thường bị đau đầu âm ỉ, sốt nhẹ từ 1 đến 3 ngày, kèm theo ho khan hoặc ho có đờm, nghẹt mũi, sổ mũi, chảy dịch mũi trong hoặc đặc màu xanh/vàng, rát họng, nuốt vướng, đau mỏi cơ toàn thân ở mức độ nhẹ.
    - Mức độ nguy hiểm: Trung bình. Bệnh có thể tự khỏi sau 5-7 ngày nếu chăm sóc tốt, nhưng dễ biến chứng thành viêm phổi mãn tính hoặc nhiễm trùng sâu ở trẻ em và người cao tuổi.
    - Hướng xử lý: Nghỉ ngơi hoàn toàn tại phòng thoáng khí, uống nhiều nước ấm, súc họng bằng nước muối sinh lý 0.9%. Nếu sốt cao trên 38.5 độ C thì sử dụng thuốc hạ sốt Paracetamol (liều 10-15mg/kg).
    - Khuyến cáo khẩn cấp: Đến ngay cơ sở y tế nếu xuất hiện dấu hiệu khó thở, thở rít, đau tức ngực khi ho hoặc sốt cao liên tục trên 3 ngày không đáp ứng thuốc hạ sốt.`;

    await ChromaService.addDataToCollection("medical_knowledge_v2", "group_respiratory_001", hoHapCap, { loai: "Nhom_Benh", ten: "Nhiễm trùng đường hô hấp cấp tính" });


    // =========================================================================
    // 2. NHÓM BỆNH: Hội chứng đau đầu nội thần kinh (Migraine, Rối loạn tiền đình)
    // =========================================================================
    const thầnKinhNội = `Nhóm bệnh: Hội chứng đau đầu nội thần kinh (Bao gồm Đau nửa đầu Migraine, Rối loạn tiền đình, Đau đầu do căng thẳng).
    - Triệu chứng điển hình: Người bệnh bị đau đầu dữ dội hoặc nhói đau từng cơn vùng thái dương, đau nửa đầu, có cảm giác đầu tê rần hoặc căng nặng như đội mũ chật. Đi kèm triệu chứng chóng mặt, hoa mắt, mất thăng bằng khi đổi tư thế, buồn nôn, nôn mửa, nhạy cảm quá mức với ánh sáng mạnh hoặc tiếng động lớn, mất ngủ, khó tập trung.
    - Mức độ nguy hiểm: Trung bình đến Cao. Ảnh hưởng nghiêm trọng đến năng suất làm việc và chất lượng cuộc sống. Cần đặc biệt phân biệt với các tai biến mạch máu não nguy hiểm.
    - Hướng xử lý: Tránh xa không gian ồn ào và ánh sáng gắt, nằm nghỉ ngơi ở nơi yên tĩnh. Bổ sung các thực phẩm giàu magie, giảm căng thẳng bằng cách thiền hoặc massage nhẹ da đầu. Có thể dùng thuốc giảm đau thông thường dưới hướng dẫn dược sĩ.
    - Khuyến cáo khẩn cấp: Cần đi cấp cứu ngay lập tức nếu đau đầu đột ngột, dữ dội nhất từ trước đến nay, hoặc kèm theo méo miệng, nói ngọng, yếu liệt tay chân một bên cơ thể (dấu hiệu đột quỵ).`;

    await ChromaService.addDataToCollection("medical_knowledge_v2", "group_neurological_001", thầnKinhNội, { loai: "Nhom_Benh", ten: "Hội chứng đau đầu nội thần kinh" });


    // =========================================================================
    // 3. NHÓM BỆNH: Sốt cấp tính do Virus (Sốt siêu vi, Sốt xuất huyết cấp)
    // =========================================================================
    const sotVirus = `Nhóm bệnh: Sốt cấp tính do Virus (Bao gồm Sốt siêu vi trùng, Sốt xuất huyết Dengue giai đoạn đầu).
    - Triệu chứng điển hình: Người bệnh khởi phát bằng triệu chứng sốt cao đột ngột từ 39 đến 40 độ C, uống thuốc hạ sốt chỉ giảm trong thời gian ngắn rồi sốt lại. Kèm theo đau nhức hai hốc mắt dữ dội, đau đầu, mệt mỏi rã rời, đau mỏi các khớp xương và cơ. Giai đoạn sau (từ ngày thứ 3) có thể xuất hiện các chấm xuất huyết đỏ dưới da, chảy máu cam hoặc chảy máu chân răng.
    - Mức độ nguy hiểm: Cao. Sốt xuất huyết có nguy cơ gây biến chứng cô đặc máu, giảm tiểu cầu nghiêm trọng dẫn đến xuất huyết nội tạng hoặc sốc đe dọa tính mạng từ ngày thứ 3 đến ngày thứ 7 của bệnh.
    - Hướng xử lý: Bù nước và điện giải liên tục bằng dung dịch Oresol pha đúng tỷ lệ. Chỉ được dùng Paracetamol để hạ sốt. Tuyệt đối KHÔNG dùng Ibuprofen hoặc Aspirin vì sẽ làm trầm trọng hơn tình trạng xuất huyết.
    - Khuyến cáo khẩn cấp: Nhập viện ngay nếu có các "dấu hiệu cảnh báo" bao gồm: Đau bụng cấp dữ dội vùng gan, nôn ói liên tục trên 3 lần/giờ, lờ đờ, vật vã, hoặc chảy máu chân răng, đi ngoài phân đen.`;

    await ChromaService.addDataToCollection("medical_knowledge_v2", "group_viral_fever_001", sotVirus, { loai: "Nhom_Benh", ten: "Sốt cấp tính do Virus" });


    // =========================================================================
    // 4. NHÓM BỆNH: Rối loạn tiêu hóa và Nhiễm trùng đường ruột (Viêm dạ dày, Ngộ độc)
    // =========================================================================
    const tieuHoa = `Nhóm bệnh: Rối loạn tiêu hóa và Nhiễm trùng đường ruột (Bao gồm Viêm dạ dày ruột cấp, Nhiễm trùng nhiễm độc thức ăn).
    - Triệu chứng điển hình: Người bệnh xuất hiện cơn đau bụng âm ỉ hoặc quặn thắt từng cơn vùng quanh rốn hoặc thượng vị. Đi kèm tiêu chảy (đi ngoài phân lỏng nhiều lần trong ngày), buồn nôn, nôn mửa ra thức ăn hoặc dịch dạ dày, bụng chướng đau, đầy hơi, có thể kèm sốt nhẹ hoặc ớn lạnh do mất nước.
    - Mức độ nguy hiểm: Trung bình. Nguy hiểm nhất là tình trạng mất nước và mất chất điện giải cấp tốc khiến cơ thể kiệt quệ, đặc biệt suy kiệt nhanh ở trẻ nhỏ.
    - Hướng xử lý: Ưu tiên hàng đầu là bù nước bằng Oresol sau mỗi lần đi ngoài hoặc nôn ói. Ăn thức ăn lỏng, dễ tiêu như cháo trắng nấu muối, thịt nạc băm, tránh đồ ăn nhiều dầu mỡ, sữa hoặc nước ngọt có ga. Sử dụng men vi sinh hỗ trợ.
    - Khuyến cáo khẩn cấp: Đi khám ngay nếu đi ngoài ra máu (phân có nhầy máu), sốt cao trên 39 độ, hoặc có biểu hiện mất nước nặng như môi khô khốc, mắt trũng sâu, khát nước dữ dội, không tiểu tiện trong vòng 6 tiếng.`;

    await ChromaService.addDataToCollection("medical_knowledge_v2", "group_digestive_001", tieuHoa, { loai: "Nhom_Benh", ten: "Rối loạn tiêu hóa và Nhiễm trùng đường ruột" });


    // =========================================================================
    // 5. NHÓM BỆNH: Bệnh lý Tim mạch và Cơn tăng huyết áp cấp
    // =========================================================================
    const timMach = `Nhóm bệnh: Bệnh lý Tim mạch và Cơn tăng huyết áp cấp (Bao gồm Cao huyết áp, Thiếu máu cơ tim, Rối loạn nhịp tim).
    - Triệu chứng điển hình: Người bệnh cảm thấy đau thắt ngực, có cảm giác như có vật nặng đè nén lên lồng ngực kéo dài vài phút, đau lan lên cổ, hàm hoặc lan ra cánh tay trái. Đi kèm dấu hiệu khó thở khi gắng sức hoặc khi nằm, hồi hộp đánh trống ngực, nhịp tim đập nhanh không đều, nhức đầu dữ dội vùng chẩm (sau gáy), chóng mặt, nhìn mờ.
    - Mức độ nguy hiểm: Rất cao. Đây là nhóm bệnh lý tối cấp cứu vì nguy cơ dẫn đến Nhồi máu cơ tim cấp hoặc Tai biến mạch máu não gây tử vong hoặc tàn phế vĩnh viễn.
    - Hướng xử lý: Cho người bệnh dừng ngay mọi hoạt động, ngồi hoặc nằm nghỉ ngơi hoàn toàn nơi thoáng mát, nới lỏng quần áo. Tiến hành đo huyết áp ngay lập tức. Nếu có tiền sử bệnh tim, hãy dùng thuốc ngậm dưới lưỡi theo đơn sẵn có của bác sĩ.
    - Khuyến cáo khẩn cấp: Gọi xe cấp cứu 115 ngay nếu cơn đau thắt ngực kéo dài trên 15 phút không thuyên giảm, hoặc khó thở dữ dội, vã mồ hôi lạnh, ngất xỉu.`;

    await ChromaService.addDataToCollection("medical_knowledge_v2", "group_cardio_001", timMach, { loai: "Nhom_Benh", ten: "Bệnh lý Tim mạch và Cơn tăng huyết áp cấp" });


    // =========================================================================
    // 6. NHÓM BỆNH: Bệnh lý Cơ xương khớp cấp và mãn tính (Viêm khớp, Gout cấp)
    // =========================================================================
    const xuongKhop = `Nhóm bệnh: Bệnh lý Cơ xương khớp cấp và mãn tính (Bao gồm Viêm khớp dạng thấp, Cơn Gout cấp tính, Thoái hóa cột sống).
    - Triệu chứng điển hình: Người bệnh bị đau nhức dữ dội ở một hoặc nhiều khớp (đặc biệt là khớp ngón chân cái, khớp gối, cổ tay). Khớp có biểu hiện sưng to, nóng đỏ, đau tăng lên khi chạm vào hoặc khi vận động. Thường bị cứng khớp vào buổi sáng sau khi thức dậy (kéo dài trên 30 phút), đau mỏi âm ỉ vùng cột sống thắt lưng hoặc đau mỏi vai gáy lan xuống tay.
    - Mức độ nguy hiểm: Thấp đến Trung bình. Bệnh ít gây tử vong đột ngột nhưng ảnh hưởng nặng nề đến khả năng vận động, di chuyển và có thể gây biến dạng, dính khớp vĩnh viễn nếu không điều trị đúng cách.
    - Hướng xử lý: Hạn chế di chuyển, để khớp đau được nghỉ ngơi. Cơn gout cấp hoặc sưng viêm nóng đỏ thì nên chườm lạnh để giảm sưng (không chườm nóng). Hạn chế ăn thực phẩm giàu purin như hải sản, thịt đỏ (thịt bò, chó), không uống rượu bia.
    - Khuyến cáo khẩn cấp: Đi khám ngay nếu khớp sưng to kèm sốt cao, rét run (dấu hiệu của Viêm khớp nhiễm khuẩn, cần dùng kháng sinh gấp để tránh hỏng khớp).`;

    await ChromaService.addDataToCollection("medical_knowledge_v2", "group_joints_001", xuongKhop, { loai: "Nhom_Benh", ten: "Bệnh lý Cơ xương khớp" });

    console.log("✅ Đã nạp thành công toàn bộ kho tri thức phân loại nhóm bệnh vào ChromaDB!");
}

seed().catch(err => console.error("❌ Lỗi khi nạp dữ liệu:", err));