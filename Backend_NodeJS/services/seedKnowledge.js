// file: seedKnowledge.js
import ChromaService from "./chromaService.js";

async function seed() {
    console.log("⏳ Đang dọn dẹp và khởi tạo dữ liệu COLLECTION CHUYÊN KHOA MỚI...");

    // =========================================================================
    // 1. CHUYÊN KHOA: Nội tổng quát
    // =========================================================================
    const noiTongQuat = `Chuyên khoa: Nội tổng quát

    Mô tả:
    Khám và điều trị các bệnh lý nội khoa thông thường khi triệu chứng chưa rõ nguyên nhân hoặc liên quan nhiều cơ quan.

    Các triệu chứng thường gặp:
    - Sốt
    - Mệt mỏi
    - Chóng mặt
    - Đau đầu nhẹ
    - Suy nhược
    - Sụt cân
    - Chán ăn
    - Mất ngủ
    - Đau nhức toàn thân
    - Khó chịu không rõ nguyên nhân

    Các bệnh thường khám:
    - Cảm cúm
    - Viêm họng
    - Sốt siêu vi
    - Thiếu máu
    - Tăng huyết áp
    - Đái tháo đường
    - Rối loạn chuyển hóa

    Ưu tiên:
    Đây là chuyên khoa mặc định nếu triệu chứng chưa đủ rõ để phân loại.`;

    await ChromaService.addDataToCollection(
        "specialty_knowledge_v1", 
        "specialty_general_internal_001", 
        noiTongQuat, 
        { loai: "Chuyen_Khoa", ten: "Nội tổng quát" }
    );

    // =========================================================================
    // 2. CHUYÊN KHOA: Nhi Khoa
    // =========================================================================
    const nhiKhoa = `Chuyên khoa: Nhi Khoa

    Mô tả:
    Chuyên khoa chăm sóc sức khỏe toàn diện, chẩn đoán và điều trị tất cả các bệnh lý dành riêng cho trẻ sơ sinh, trẻ nhỏ và thiếu niên dưới 16 tuổi.

    Các triệu chứng thường gặp:
    - Trẻ bị sốt cao, co giật do sốt
    - Ho khò khè, khó thở, thở rít, thở nhanh ở trẻ nhỏ
    - Chán ăn, bỏ bú, lười ăn, sụt cân hoặc đứng cân
    - Quấy khóc liên tục không rõ nguyên nhân ở trẻ sơ sinh
    - Nôn trớ, bộc phát tiêu chảy, phân có nhầy hoặc máu
    - Phát ban, nổi mẩn đỏ, mụn nước trên da (sởi, thủy đậu)

    Các bệnh thường khám:
    - Viêm tiểu phế quản, viêm phổi trẻ em, viêm tai giữa
    - Sốt siêu vi, cúm mùa, tay chân miệng, sốt xuất huyết ở trẻ
    - Rối loạn tiêu hóa, suy dinh dưỡng, còi xương, chậm lớn
    - Tư vấn dinh dưỡng và tiêm chủng định kỳ cho trẻ

    Ưu tiên:
    Hệ thống bắt buộc chọn chuyên khoa này cho mọi bệnh nhân có độ tuổi dưới 16 tuổi, bất kể triệu chứng mô tả là gì.`;

    await ChromaService.addDataToCollection(
        "specialty_knowledge_v1", 
        "specialty_pediatrics_001", 
        nhiKhoa, 
        { loai: "Chuyen_Khoa", ten: "Nhi Khoa" }
    );

    // =========================================================================
    // 3. CHUYÊN KHOA: Tim Mạch
    // =========================================================================
    const timMach = `Chuyên khoa: Tim Mạch

    Mô tả:
    Thăm khám, tầm soát và điều trị chuyên sâu nội khoa các bệnh lý liên quan đến cơ tim, van tim, nhịp tim và hệ thống mạch máu toàn thân.

    Các triệu chứng thường gặp:
    - Đau thắt ngực, cảm giác có vật nặng đè nén lên lồng ngực kéo dài
    - Khó thở khi gắng sức, hụt hơi hoặc khó thở khi nằm thấp đầu
    - Hồi hộp, lo âu, đánh trống ngực liên tục, hẫng nhịp tim
    - Nhịp tim đập nhanh hoặc chậm bất thường
    - Choáng váng, xây xẩm mặt mày, ngất xỉu đột ngột
    - Đau nhức đầu vùng chẩm (sau gáy) kèm tăng huyết áp

    Các bệnh thường khám:
    - Tăng huyết áp mãn tính, cơn tăng huyết áp cấp
    - Bệnh cơ tim thiếu máu cục bộ (thiếu máu cơ tim), xơ vữa động mạch
    - Rối loạn nhịp tim (tim đập nhanh, ngoại tâm thu)
    - Suy tim giai đoạn nhẹ và trung bình, bệnh van tim

    Ưu tiên:
    Đặc biệt ưu tiên khi triệu chứng liên quan đến cảm giác đau/đè nén vùng ngực trái, loạn nhịp tim hoặc biến động chỉ số huyết áp.`;

    await ChromaService.addDataToCollection(
        "specialty_knowledge_v1", 
        "specialty_cardiovascular_001", 
        timMach, 
        { loai: "Chuyen_Khoa", ten: "Tim Mạch" }
    );

    // =========================================================================
    // 4. CHUYÊN KHOA: Răng hàm mặt
    // =========================================================================
    const rangHamMat = `Chuyên khoa: Răng hàm mặt

    Mô tả:
    Khám, điều trị và phục hình các bệnh lý liên quan đến răng, lợi (nướu), xương hàm và các cấu trúc trong khoang miệng.

    Các triệu chứng thường gặp:
    - Đau nhức răng dữ dội, buốt răng khi ăn đồ nóng/lạnh
    - Chảy máu chân răng khi đánh răng hoặc tự nhiên
    - Nướu (lợi) sưng đỏ, có mủ, viêm loét miệng (nhiệt miệng) lâu ngày
    - Hôi miệng kéo dài không rõ nguyên nhân
    - Đau vùng khớp thái dương hàm, kẹt hàm, tiếng kêu khục khục khi nhai
    - Lệch răng, mất răng, răng lung lay

    Các bệnh thường khám:
    - Sâu răng, viêm tủy răng cấp và mãn tính
    - Viêm nướu, viêm nha chu, áp xe quanh chóp răng
    - Răng khôn mọc lệch, mọc ngầm gây đau nhức, sưng nề mặt
    - Rối loạn khớp thái dương hàm

    Ưu tiên:
    Ưu tiên tuyệt đối khi người bệnh gặp bất kỳ tổn thương hoặc đau đớn nào khu trú trong khoang miệng, răng và cơ hàm.`;

    await ChromaService.addDataToCollection(
        "specialty_knowledge_v1", 
        "specialty_dental_001", 
        rangHamMat, 
        { loai: "Chuyen_Khoa", ten: "Răng hàm mặt" }
    );

    // =========================================================================
    // 5. CHUYÊN KHOA: Da liễu
    // =========================================================================
    const daLieu = `Chuyên khoa: Da liễu

    Mô tả:
    Chẩn đoán và điều trị các bệnh lý ảnh hưởng đến bề mặt da, niêm mạc, lông, tóc, móng và các bệnh lây truyền qua đường tình dục.

    Các triệu chứng thường gặp:
    - Ngứa da dữ dội, nổi mẩn đỏ, mề đay, sẩn ngứa toàn thân hoặc khu trú
    - Da khô bong tróc, nứt nẻ, chảy dịch, đóng vảy tiết
    - Nổi mụn nước, bọng nước, mụn mủ, mụn trứng cá nặng
    - Thay đổi sắc tố da (nám, tàn nhang, đốm trắng bất thường)
    - Rụng tóc nhiều, da đầu nhiều gàu bong tróc vảy, móng tay giòn dễ gãy
    - Xuất hiện nốt ruồi lạ phát triển nhanh, ngứa hoặc chảy máu

    Các bệnh thường khám:
    - Viêm da cơ địa, viêm da tiếp xúc dị ứng, chàm (Eczema)
    - Vảy nến, á sừng, tổ đỉa, mề đay mãn tính
    - Nhiễm trùng da do vi khuẩn, nấm da (hắc lào, lang ben), zona thần kinh
    - Mụn trứng cá, viêm nang lông, thủy đậu, sạm da
    - Các bệnh lây qua đường tình dục (STDs): Lậu, giang mai, sùi mào gà

    Ưu tiên:
    Lựa chọn hàng đầu cho các tổn thương hiển thị rõ trên bề mặt da, biểu bì móng, các vấn đề về tóc và da đầu.`;

    await ChromaService.addDataToCollection(
        "specialty_knowledge_v1", 
        "specialty_dermatology_001", 
        daLieu, 
        { loai: "Chuyen_Khoa", ten: "Da liễu" }
    );

    // =========================================================================
    // 6. CHUYÊN KHOA: Mắt
    // =========================================================================
    const mat = `Chuyên khoa: Mắt

    Mô tả:
    Chuyên khoa sâu thăm khám, đo khúc xạ, chẩn đoán và điều trị các tổn thương cấu trúc nhãn cầu và rối loạn chức năng thị giác.

    Các triệu chứng thường gặp:
    - Nhìn mờ đột ngột hoặc mờ tiến triển, suy giảm thị lực
    - Mắt đỏ, đau nhức lồi mắt hoặc đau sâu trong hốc mắt
    - Chảy nước mắt liên tục, mắt tiết nhiều ghèn (dịch rỉ mắt)
    - Ngứa mắt, rát mắt, cảm giác cộm như có cát/dị vật trong mắt
    - Nhìn một thành hai (song thị), sợ ánh sáng mạnh
    - Mỏi mắt khi nhìn màn hình máy tính, điện thoại lâu

    Các bệnh thường khám:
    - Viêm kết mạc (đau mắt đỏ), viêm giác mạc, viêm bờ mi
    - Tật khúc xạ: Cận thị, viễn thị, loạn thị, lão thị
    - Đục thủy tinh thể (cườm khô), Glaucoma (cườm nước/tăng nhãn áp)
    - Khô mắt mãn tính, mộng thịt, tổn thương võng mạc do đái tháo đường

    Ưu tiên:
    Ưu tiên tuyệt đối khi khách hàng có khiếu nại về tầm nhìn (thị lực) hoặc các triệu chứng sưng đau khó chịu tại mắt.`;

    await ChromaService.addDataToCollection(
        "specialty_knowledge_v1", 
        "specialty_ophthalmology_001", 
        mat, 
        { loai: "Chuyen_Khoa", ten: "Mắt" }
    );

    // =========================================================================
    // 7. CHUYÊN KHOA: Tai mũi họng
    // =========================================================================
    const taiMuiHong = `Chuyên khoa: Tai mũi họng

    Mô tả:
    Khám và điều trị các bệnh lý cấp và mãn tính liên quan đến hệ thống tai, mũi, các xoang mặt, họng và cấu trúc vùng cổ.

    Các triệu chứng thường gặp:
    - Đau rát họng, ho khan hoặc ho có đờm lâu ngày, nuốt vướng, nuốt đau
    - Nghẹt mũi một hoặc hai bên, sổ mũi, chảy nước mũi trong hoặc xanh/vàng
    - Đau nhức vùng trán, vùng má hoặc giữa hai mắt (đau xoang)
    - Đau tai, ù tai, nghe kém, có dịch hoặc mủ chảy ra từ lỗ tai
    - Khản tiếng, mất giọng, hôi miệng do viêm amidan có mủ

    Các bệnh thường khám:
    - Viêm họng cấp/mãn tính, viêm amidan cấp hoặc quá phát gây sốt
    - Viêm mũi dị ứng thời tiết, viêm xoang cấp và mãn tính
    - Viêm tai giữa cấp tính, viêm tai ngoài, thủng màng nhĩ
    - Viêm thanh quản gây khản tiếng

    Ưu tiên:
    Ưu tiên lựa chọn khi các triệu chứng khu trú rõ rệt ở vùng tai, mũi, họng và đường hô hấp trên.`;

    await ChromaService.addDataToCollection(
        "specialty_knowledge_v1", 
        "specialty_ent_001", 
        taiMuiHong, 
        { loai: "Chuyen_Khoa", ten: "Tai mũi họng" }
    );

    // =========================================================================
    // 8. CHUYÊN KHOA: Thần Kinh
    // =========================================================================
    const thanKinh = `Chuyên khoa: Thần Kinh

    Mô tả:
    Chuyên khoa sâu chẩn đoán và điều trị nội khoa các tổn thương ảnh hưởng đến hệ thần kinh trung ương (não bộ, tủy sống) và hệ thần kinh ngoại biên.

    Các triệu chứng thường gặp:
    - Đau đầu dữ dội, đau nửa đầu (Migraine) thành cơn kèm buồn nôn
    - Đau nhói căng nặng như vòng kim cô siết chặt đầu hoặc nhức gáy
    - Chóng mặt kéo dài, hoa mắt, quay cuồng mất thăng bằng khi đổi tư thế
    - Tê bì, tê rần tay chân, tê nửa người hoặc mất cảm giác cục bộ
    - Run tay chân, co giật cơ, yếu cơ, liệt vận động nhẹ
    - Rối loạn giấc ngủ, mất ngủ mãn tính, suy giảm trí nhớ trầm trọng

    Các bệnh thường khám:
    - Đau nửa đầu Migraine, rối loạn tiền đình, đau đầu do căng thẳng
    - Suy nhược thần kinh, mất ngủ kéo dài không rõ nguyên nhân
    - Đau dây thần kinh tọa, hội chứng ống cổ tay, viêm đa dây thần kinh
    - Hỗ trợ theo dõi nội khoa và phục hồi sau tai biến mạch máu não (đột quỵ)

    Ưu tiên:
    Ưu tiên khi người bệnh bị đau đầu mức độ từ trung bình đến dữ dội, chóng mặt tiền đình hoặc tê bì khu trú ở các nhóm cơ ngoại biên.`;

    await ChromaService.addDataToCollection(
        "specialty_knowledge_v1", 
        "specialty_neurology_001", 
        thanKinh, 
        { loai: "Chuyen_Khoa", ten: "Thần Kinh" }
    );

    // =========================================================================
    // 9. CHUYÊN KHOA: Sản Phụ Khoa
    // =========================================================================
    const sanPhuKhoa = `Chuyên khoa: Sản Phụ Khoa

    Mô tả:
    Chuyên khoa chăm sóc sức khỏe sinh sản phụ nữ bao gồm quản lý thai nghén, sinh nở (Sản khoa) và điều trị các bệnh lý cơ quan sinh dục nữ (Phụ khoa).

    Các triệu chứng thường gặp:
    - Chậm kinh, trễ kinh, thử que 2 vạch nghi ngờ mang thai
    - Rối loạn chu kỳ kinh nguyệt (kinh sớm, trễ kinh, rong kinh kéo dài)
    - Đau bụng kinh dữ dội (thống kinh), đau âm ỉ vùng chậu dưới
    - Khí hư (huyết trắng) bất thường: màu xanh, vàng, đục, vón cục như bã đậu
    - Ngứa ngáy, đau rát âm đạo, đau khi quan hệ tình dục
    - Triệu chứng ốm nghén, nôn trớ ở phụ nữ mang thai

    Các bệnh thường khám:
    - Khám thai định kỳ, siêu âm thai, theo dõi quản lý thai nghén
    - Viêm âm đạo, viêm lộ tuyến cổ tử cung, viêm phần phụ
    - U xơ tử cung, u nang buồng trứng, hội chứng buồng trứng đa nang (PCOS)
    - Tư vấn tiền hôn nhân, kế hoạch hóa gia đình, tầm soát ung thư cổ tử cung

    Ưu tiên:
    Ưu tiên mặc định cho các đối tượng khách hàng nữ gặp vấn đề liên quan trực tiếp đến thai sản hoặc cơ quan sinh sản nữ giới.`;

    await ChromaService.addDataToCollection(
        "specialty_knowledge_v1", 
        "specialty_obgyn_001", 
        sanPhuKhoa, 
        { loai: "Chuyen_Khoa", ten: "Sản Phụ Khoa" }
    );

    // =========================================================================
    // 10. CHUYÊN KHOA: Hô hấp
    // =========================================================================
    const hoHap = `Chuyên khoa: Hô hấp

    Mô tả:
    Chẩn đoán và điều trị chuyên sâu các bệnh lý thuộc đường hô hấp dưới bao gồm khí quản, phế quản, nhu mô phổi và màng phổi.

    Các triệu chứng thường gặp:
    - Ho mãn tính kéo dài trên 3 tuần, ho khạc đờm đặc màu đục, xanh hoặc vàng
    - Khó thở, thở khò khè, nghe có tiếng rít ở ngực khi thở, hụt hơi khi đi lại
    - Đau tức ngực hoặc đau nhói vùng ngực khi ho hoặc khi hít thở sâu
    - Ho ra máu (dù chỉ là vệt máu nhỏ lẫn trong đờm)
    - Sốt kèm theo lạnh run, vã mồ hôi và ho dữ dội

    Các bệnh thường khám:
    - Hen phế quản (Suyễn) ở người lớn
    - Bệnh phổi tắc nghẽn mãn tính (COPD) do hút thuốc lá/làm việc độc hại
    - Viêm phế quản cấp và mãn tính, viêm phổi nhiễm khuẩn
    - Giãn phế quản, tầm soát lao phổi hoặc tràn dịch màng phổi nhẹ

    Ưu tiên:
    Ưu tiên cao khi triệu chứng tập trung ở đường hô hấp dưới, đặc biệt là ho kéo dài kèm khó thở nặng, tức ngực (khác với Tai Mũi Họng ở hô hấp trên).`;

    await ChromaService.addDataToCollection(
        "specialty_knowledge_v1", 
        "specialty_respiratory_001", 
        hoHap, 
        { loai: "Chuyen_Khoa", ten: "Hô hấp" }
    );

    // =========================================================================
    // 11. CHUYÊN KHOA: Tiêu hóa
    // =========================================================================
    const tieuHoa = `Chuyên khoa: Tiêu hóa

    Mô tả:
    Chẩn đoán và điều trị các bệnh lý liên quan đến ống tiêu hóa (thực quản, dạ dày, ruột) và các cơ quan phụ trợ (gan, mật, tụy).

    Các triệu chứng thường gặp:
    - Đau bụng âm ỉ hoặc quặn thắt từng cơn vùng thượng vị (trên rốn) hoặc quanh rốn
    - Ợ hơi, ợ chua, trào ngược thức ăn hoặc dịch vị lên cổ họng, nóng rát ngực
    - Buồn nôn, nôn mửa ra thức ăn hoặc dịch dạ dày màu vàng xanh
    - Đầy bụng, chướng hơi, khó tiêu, bụng óc ách sau khi ăn
    - Tiêu chảy (đi ngoài phân lỏng nhiều lần), táo bón lâu ngày, đi ngoài phân đen hoặc có máu

    Các bệnh thường khám:
    - Viêm loét dạ dày - tá tràng, nhiễm vi khuẩn HP (Helicobacter Pylori)
    - Hội chứng trào ngược dạ dày thực quản (GERD)
    - Hội chứng ruột kích thích (IBS), viêm đại tràng cấp và mãn tính
    - Rối loạn tiêu hóa, ngộ độc thức ăn, viêm gan cấp tính nhẹ

    Ưu tiên:
    Ưu tiên cao nhất khi các triệu chứng tập trung hoàn toàn ở vùng bụng và liên quan trực tiếp đến đường ăn uống, tiêu hóa, bài tiết.`;

    await ChromaService.addDataToCollection(
        "specialty_knowledge_v1", 
        "specialty_gastrointestinal_001", 
        tieuHoa, 
        { loai: "Chuyen_Khoa", ten: "Tiêu hóa" }
    );

    // =========================================================================
    // 12. CHUYÊN KHOA: Nội tiết
    // =========================================================================
    const noiTiet = `Chuyên khoa: Nội tiết

    Mô tả:
    Điều trị chuyên sâu các bệnh lý sinh ra do rối loạn chức năng của các tuyến nội tiết và hệ thống hormone trong cơ thể.

    Các triệu chứng thường gặp:
    - Uống nhiều nước, nhanh khát nước và đi tiểu rất nhiều lần (đặc biệt là ban đêm)
    - Sụt cân nhanh chóng không rõ lý do hoặc tăng cân mất kiểm soát
    - Run tay, vã mồ hôi nhiều, hồi hộp trống ngực, sợ nóng, mắt hơi lồi
    - Mệt mỏi rã rời, ngủ gà ngủ gật, sợ lạnh, da khô, mạch chậm
    - Xuất hiện khối u vùng cổ (bướu cổ), nuốt hơi nghẹn nhẹ
    - Rối loạn mỡ máu qua xét nghiệm

    Các bệnh thường khám:
    - Đái tháo đường (Tiểu đường) Typ 1, Typ 2 và tiểu đường thai kỳ
    - Các bệnh lý tuyến giáp: Cường giáp (Basedow), suy giáp, bướu nhân tuyến giáp
    - Rối loạn chuyển hóa Lipid (mỡ máu cao), rối loạn acid uric
    - Suy tuyến thượng thận, rối loạn hormone tuyến yên

    Ưu tiên:
    Ưu tiên lựa chọn khi bệnh nhân có các dấu hiệu rối loạn chuyển hóa rõ ràng như khát-tiểu nhiều, bướu cổ hoặc biến động cân nặng bất thường.`;

    await ChromaService.addDataToCollection(
        "specialty_knowledge_v1", 
        "specialty_endocrinology_001", 
        noiTiet, 
        { loai: "Chuyen_Khoa", ten: "Nội tiết" }
    );

    // =========================================================================
    // 13. CHUYÊN KHOA: Cơ xương khớp
    // =========================================================================
    const coXuongKhop = `Chuyên khoa: Cơ xương khớp

    Mô tả:
    Thăm khám và điều trị nội khoa các bệnh lý thuộc hệ thống cơ, xương, khớp và các mô liên kết phần mềm xung quanh khớp.

    Các triệu chứng thường gặp:
    - Đau nhức các khớp (ngón tay, cổ tay, khớp gối, cổ chân, khớp háng)
    - Khớp có biểu hiện sưng to, nóng hoặc đỏ dữ dội, đau tăng khi chạm vào
    - Cứng khớp vào buổi sáng sau khi ngủ dậy, mất vài chục phút mới vận động bình thường được
    - Đau mỏi âm ỉ vùng cột sống thắt lưng hoặc vùng vai gáy kéo dài
    - Hạn chế vận động, nghe tiếng kêu lục cục, lạo xạo ở khớp khi di chuyển

    Các bệnh thường khám:
    - Thoái hóa khớp gối, thoái hóa cột sống cổ/thắt lưng
    - Bệnh Gout (Gút) cấp và mãn tính gây sưng đau ngón chân cái
    - Viêm khớp dạng thấp, viêm quanh khớp vai
    - Thoát vị đĩa đệm cột sống (giai đoạn điều trị nội khoa bảo tồn)
    - Loãng xương ở người cao tuổi hoặc phụ nữ mãn kinh

    Ưu tiên:
    Lựa chọn hàng đầu cho các cơn đau có tính chất cơ học khu trú tại hệ thống xương khớp, cản trở việc vận động di chuyển.`;

    await ChromaService.addDataToCollection(
        "specialty_knowledge_v1", 
        "specialty_orthopedics_001", 
        coXuongKhop, 
        { loai: "Chuyen_Khoa", ten: "Cơ xương khớp" }
    );

    // =========================================================================
    // 14. CHUYÊN KHOA: Thận - Tiết niệu
    // =========================================================================
    const thanTietNieu = `Chuyên khoa: Thận - Tiết niệu

    Mô tả:
    Chẩn đoán và điều trị nội khoa các bệnh lý của hệ thống bài tiết nước tiểu bao gồm thận, niệu quản, bàng quang và niệu đạo.

    Các triệu chứng thường gặp:
    - Đau buốt, đau rát khi đi tiểu, tiểu rắt (tiểu nhiều lần nhưng ra rất ít nước tiểu)
    - Tiểu đêm nhiều lần, tiểu không tự chủ, dòng nước tiểu yếu hoặc ngắt quãng
    - Nước tiểu thay đổi màu sắc: đục, có mủ, có máu (nước tiểu màu hồng/đỏ) hoặc có nhiều bọt lâu tan
    - Đau âm ỉ hoặc đau quặn dữ dội vùng hố chậu, vùng thắt lưng lan xuống bẹn (đau quặn thận)
    - Phù nề mặt, mi mắt hoặc phù hai chân vào buổi sáng

    Các bệnh thường khám:
    - Nhiễm trùng đường tiết niệu (viêm bàng quang, viêm niệu đạo)
    - Sỏi thận, sỏi niệu quản, sỏi bàng quang kích thước nhỏ điều trị nội khoa
    - Hội chứng thận hư, viêm cầu thận cấp/mãn tính
    - Suy thận cấp hoặc hỗ trợ quản lý suy thận mạn tính giai đoạn đầu

    Ưu tiên:
    Ưu tiên hàng đầu cho các rối loạn chức năng bài tiết nước tiểu, tiểu buốt, tiểu máu hoặc đau quặn vùng hông lưng dưới.`;

    await ChromaService.addDataToCollection(
        "specialty_knowledge_v1", 
        "specialty_urology_001", 
        thanTietNieu, 
        { loai: "Chuyen_Khoa", ten: "Thận - Tiết niệu" }
    );

    // =========================================================================
    // 15. CHUYÊN KHOA: Ung bướu
    // =========================================================================
    const ungBuou = `Chuyên khoa: Ung bướu

    Mô tả:
    Khám, tầm soát sớm, chẩn đoán bản chất (lành tính/ác tính) và tư vấn hướng điều trị các khối u, hạch bất thường trên cơ thể.

    Các triệu chứng thường gặp:
    - Tự sờ thấy khối u hoặc cục hạch cứng, không đau hoặc đau ít phát triển nhanh ở vú, cổ, nách, bẹn
    - Sụt cân nhanh chóng không rõ nguyên nhân (giảm >5% trọng lượng cơ thể trong 1-2 tháng)
    - Mệt mỏi kéo dài, kiệt sức không thuyên giảm dù đã nghỉ ngơi
    - Vết loét trên da hoặc trong miệng lâu lành (quá 2 tuần)
    - Thay đổi hình dạng, màu sắc hoặc kích thước của nốt ruồi có sẵn trên da
    - Khàn tiếng hoặc ho kéo dài nhiều tháng không đỡ khi dùng thuốc thường

    Các bệnh thường khám:
    - Tầm soát sớm các bệnh ung thư phổ biến: Ung thư vú, ung thư cổ tử cung, ung thư phổi, ung thư đại trực tràng, ung thư giáp
    - Khám và theo dõi các khối u lành tính: u mỡ, u bao hoạt dịch, u xơ tuyến vú, nang lành tính
    - Theo dõi định kỳ sau điều trị ung thư

    Ưu tiên:
    Ưu tiên khi người bệnh chủ động yêu cầu tầm soát ung thư hoặc phát hiện các khối u, hạch lạ phát triển bất thường trên cơ thể.`;

    await ChromaService.addDataToCollection(
        "specialty_knowledge_v1", 
        "specialty_oncology_001", 
        ungBuou, 
        { loai: "Chuyen_Khoa", center: "Ung bướu" }
    );

    // =========================================================================
    // 16. CHUYÊN KHOA: Tâm thần
    // =========================================================================
    const tamThan = `Chuyên khoa: Tâm thần

    Mô tả:
    Chẩn đoán, tư vấn và điều trị y khoa các rối loạn về mặt cảm xúc, tâm lý, hành vi và các bất ổn tinh thần.

    Các triệu chứng thường gặp:
    - Khóc lóc, buồn bã, chán nản kéo dài, mất hết hứng thú với cuộc sống
    - Lo âu quá mức, bồn chồn, tim đập nhanh, hoảng loạn vô cớ trước những việc nhỏ
    - Mất ngủ kinh niên, trằn trọc không ngủ được hoặc thức dậy quá sớm kèm suy nghĩ tiêu cực
    - Thay đổi tâm trạng đột ngột (lúc cực kỳ hưng phấn vui vẻ, lúc lại suy sụp trầm uất)
    - Nghe thấy tiếng nói vô hình (ảo thanh) hoặc nhìn thấy điều không có thật (ảo giác)
    - Nghi ngờ có người hại mình (hoang tưởng), có ý nghĩ tự làm tổn thương bản thân

    Các bệnh thường khám:
    - Trầm cảm ở các mức độ, rối loạn lo âu lan tỏa, rối loạn hoảng sợ
    - Rối loạn giấc ngủ do áp lực, stress nặng từ công việc và cuộc sống
    - Rối loạn tiền mãn kinh gây thay đổi tâm sinh lý, rối loạn lưỡng cực
    - Suy nhược tâm thần, các hội chứng tâm lý tuổi dậy thì hoặc sau sinh

    Ưu tiên:
    Ưu tiên khi bệnh nhân gặp các biểu hiện bất ổn rõ rệt về mặt cảm xúc, tâm lý kéo dài hoặc mất ngủ mãn tính có yếu tố stress kích thích (phân biệt với Nội thần kinh vốn thiên về tổn thương thực thể).`;

    await ChromaService.addDataToCollection(
        "specialty_knowledge_v1", 
        "specialty_psychiatry_001", 
        tamThan, 
        { loai: "Chuyen_Khoa", ten: "Tâm thần" }
    );

    // =========================================================================
    // 17. CHUYÊN KHOA: Y học cổ truyền
    // =========================================================================
    const yHocCoTruyen = `Chuyên khoa: Y học cổ truyền

    Mô tả:
    Khám và điều trị kết hợp giữa y học dân tộc và y học hiện đại bằng cách sử dụng thuốc thảo dược, châm cứu, bấm huyệt, xoa bóp.

    Các triệu chứng thường gặp:
    - Đau nhức xương khớp mãn tính ở người già, đau mỏi vai gáy do ngồi lâu
    - Cơ thể suy nhược nhẹ, ăn uống kém ngon miệng, ngủ không sâu giấc
    - Hay bị bốc hỏa, đổ mồ hôi trộm vào ban đêm
    - Di chứng liệt hoặc yếu cơ nhẹ sau tai biến đã qua giai đoạn nguy hiểm
    - Mong muốn điều trị bệnh bằng các phương pháp tự nhiên, không dùng thuốc tây

    Các bệnh thường khám:
    - Viêm khớp, thoái hóa khớp, đau thần kinh tọa điều trị bằng châm cứu/bấm huyệt
    - Suy nhược cơ thể, mất ngủ cơ năng, rối loạn chức năng tiêu hóa nhẹ
    - Phục hồi chức năng vận động bằng phương pháp y học cổ truyền sau chấn thương

    Ưu tiên:
    Ưu tiên cho đối tượng bệnh nhân mắc bệnh mãn tính, người cao tuổi hoặc người có nhu cầu điều trị bằng phương pháp châm cứu, bấm huyệt, thuốc nam/thuốc bắc.`;

    await ChromaService.addDataToCollection(
        "specialty_knowledge_v1", 
        "specialty_traditional_medicine_001", 
        yHocCoTruyen, 
        { loai: "Chuyen_Khoa", ten: "Y học cổ truyền" }
    );

    // =========================================================================
    // 18. CHUYÊN KHOA: Phục hồi chức năng
    // =========================================================================
    const phucHoiChucNang = `Chuyên khoa: Phục hồi chức năng

    Mô tả:
    Áp dụng các bài tập vật lý trị liệu, vận động trị liệu nhằm phục hồi lại khả năng vận động, ngôn ngữ và chức năng cơ thể bị suy giảm do chấn thương hoặc tai biến.

    Các triệu chứng thường gặp:
    - Yếu hoặc liệt nửa người, liệt tay chân sau đột quỵ não
    - Cứng khớp, teo cơ sau một thời gian dài bất động (bó bột, nằm lâu trên giường bệnh)
    - Khó khăn trong việc đi lại, đứng lên ngồi xuống hoặc cầm nắm đồ vật sau chấn thương, phẫu thuật
    - Đau lưng, đau cổ gáy cấp tính gây hạn chế tầm vận động của cột sống
    - Nói ngọng, khó nuốt, mất ngôn ngữ nhẹ sau tổn thương não

    Các bệnh thường khám:
    - Vật lý trị liệu phục hồi sau tai biến mạch máu não hoặc chấn thương sọ não
    - Phục hồi chức năng sau phẫu thuật thay khớp (khớp gối, khớp háng), dây chằng gối
    - Điều trị bảo tồn thoát vị đĩa đệm, vẹo cột sống bằng máy kéo giãn và bài tập vận động

    Ưu tiên:
    Ưu tiên tuyệt đối khi người bệnh có nhu cầu tập luyện vật lý trị liệu, phục hồi vận động sau khi đã qua giai đoạn điều trị bệnh lý cấp tính.`;

    await ChromaService.addDataToCollection(
        "specialty_knowledge_v1", 
        "specialty_rehabilitation_001", 
        phucHoiChucNang, 
        { loai: "Chuyen_Khoa", ten: "Phục hồi chức năng" }
    );

    // =========================================================================
    // 19. CHUYÊN KHOA: Dị ứng - Miễn dịch
    // =========================================================================
    const diUngMienDich = `Chuyên khoa: Dị ứng - Miễn dịch

    Mô tả:
    Chẩn đoán và quản lý các phản ứng quá mẫn của cơ thể (dị ứng) và các bệnh lý tự miễn hệ thống do hệ miễn dịch tấn công chính cơ thể.

    Các triệu chứng thường gặp:
    - Nổi ban đỏ, mề đay dị ứng cấp tính dữ dội sau khi ăn hải sản, uống thuốc hoặc tiếp xúc hóa chất
    - Hắt hơi liên tục, chảy nước mũi trong, ngứa mũi ngứa mắt dữ dội theo mùa hoặc khi gặp bụi hoa
    - Sưng phù môi, phù mắt, phù mặt (phù mạch) đi kèm ngứa ngáy
    - Đau nhức nhiều khớp kèm sốt kéo dài và ban đỏ hình cánh bướm ở mặt
    - Phản ứng nặng, khó thở, tụt huyết áp sau khi bị côn trùng đốt hoặc tiêm thuốc (nghi sốc phản vệ)

    Các bệnh thường khám:
    - Viêm mũi dị ứng, hen phế quản do dị ứng dị nguyên (bụi nhà, lông chó mèo)
    - Mề đay mãn tính vô căn, dị ứng thức ăn, dị ứng thuốc
    - Các bệnh tự miễn: Lupus ban đỏ hệ thống, xơ cứng bì, viêm khớp tự miễn

    Ưu tiên:
    Ưu tiên lựa chọn khi người bệnh có các phản ứng dị ứng bộc phát rõ ràng với các dị nguyên ngoại lai hoặc nghi ngờ mắc bệnh tự miễn hệ thống.`;

    await ChromaService.addDataToCollection(
        "specialty_knowledge_v1", 
        "specialty_allergy_immunology_001", 
        diUngMienDich, 
        { loai: "Chuyen_Khoa", ten: "Dị ứng - Miễn dịch" }
    );

    // =========================================================================
    // 20. CHUYÊN KHOA: Lão khoa
    // =========================================================================
    const laoKhoa = `Chuyên khoa: Lão khoa

    Mô tả:
    Chuyên khoa đặc thù thăm khám và quản lý sức khỏe toàn diện cho người cao tuổi (từ 60 hoặc 65 tuổi trở lên), đặc biệt là nhóm đối tượng mắc nhiều bệnh lý mãn tính cùng một lúc.

    Các triệu chứng thường gặp:
    - Người già bị suy nhược, ăn uống kém hẳn, sụt cân, hay bị ngã hoặc đi đứng loạng choạng
    - Lú lẫn, hay quên, đi lạc đường, không nhận ra người thân, thay đổi tính cách (suy giảm trí tuệ tuổi già)
    - Mất ngủ kinh niên kéo dài, cơ thể mệt mỏi rã rời không có sức sống
    - Đau nhức cơ thể ê ẩm kết hợp khó thở nhẹ và rối loạn tiểu tiện ở người già
    - Đang sử dụng quá nhiều loại thuốc uống mỗi ngày dẫn đến tác dụng phụ chéo

    Các bệnh thường khám:
    - Hội chứng sa sút trí tuệ ở người cao tuổi (Alzheimer)
    - Điều trị và quản lý kết hợp đa bệnh lý: Tăng huyết áp + Đái tháo đường + Thoái hóa khớp + Suy thận nhẹ trên cùng một bệnh nhân lớn tuổi
    - Hội chứng suy giảm chức năng, loãng xương nặng và trầm cảm tuổi già

    Ưu tiên:
    Ưu tiên lựa chọn cho mọi bệnh nhân trên 65 tuổi có tình trạng sức khỏe phức tạp, mắc nhiều bệnh nội khoa mãn tính đan xen cần bác sĩ điều phối phác đồ thuốc tổng thể.`;

    await ChromaService.addDataToCollection(
        "specialty_knowledge_v1", 
        "specialty_geriatrics_001", 
        laoKhoa, 
        { loai: "Chuyen_Khoa", ten: "Lão khoa" }
    );

    console.log("✅ Đã nạp thành công dữ liệu chuyên khoa mới vào Collection: specialty_knowledge_v1!");
}

seed().catch(err => console.error("❌ Lỗi khi nạp dữ liệu:", err));