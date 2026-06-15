import 'dart:convert';

class DoctorScheduleModel {
  final int? maKhungGio;
  final int? maBacSi;
  final int? maPhongKham;
  final DateTime? thoiGianBdau;
  final DateTime? thoiGianKthuc;
  final dynamic trangThai; // Có thể là int hoặc String tùy DB
  final int? maNguoiDung;
  final int? maChuyenKhoa;
  final String? moTaBanThan;
  final String? hocVi;
  final int? namKinhNghiem;
  final String? tomTatDanhGia;
  final List<String> badgesSentiment; // Chuyển thành mảng String cho dễ dùng
  final String? trangThaiHoatDong;
  final String? tenNguoiDung;
  final String? email;
  final String? dienThoai;
  final String? anhDaiDien;
  final String? tenPhongKham;
  final String? moTaPhongKham;
  final String? viTri;
  final double? kinhDo;
  final double? viDo;
  final String? linkTrangWeb;

  DoctorScheduleModel({
    this.maKhungGio,
    this.maBacSi,
    this.maPhongKham,
    this.thoiGianBdau,
    this.thoiGianKthuc,
    this.trangThai,
    this.maNguoiDung,
    this.maChuyenKhoa,
    this.moTaBanThan,
    this.hocVi,
    this.namKinhNghiem,
    this.tomTatDanhGia,
    required this.badgesSentiment,
    this.trangThaiHoatDong,
    this.tenNguoiDung,
    this.email,
    this.dienThoai,
    this.anhDaiDien,
    this.tenPhongKham,
    this.moTaPhongKham,
    this.viTri,
    this.kinhDo,
    this.viDo,
    this.linkTrangWeb,
  });

  factory DoctorScheduleModel.fromJson(Map<String, dynamic> json) {
    // 🌟 Xử lý bóc tách chuỗi JSON của Badges_sentiment thành List<String>
    List<String> parsedBadges = [];
    if (json['Badges_sentiment'] != null) {
      try {
        var decodedBadges = jsonDecode(json['Badges_sentiment']);
        if (decodedBadges is List) {
          parsedBadges = decodedBadges.map((e) => e.toString()).toList();
        }
      } catch (e) {
        print("Lỗi parse Badges_sentiment: $e");
      }
    }

    return DoctorScheduleModel(
      maKhungGio: json['Ma_khung_gio'] as int?,
      maBacSi: json['Ma_bac_si'] as int?,
      maPhongKham: json['Ma_phong_kham'] as int?,
      thoiGianBdau: json['Thoi_gian_Bdau'] != null ? DateTime.tryParse(json['Thoi_gian_Bdau'].toString()) : null,
      thoiGianKthuc: json['Thoi_gian_Kthuc'] != null ? DateTime.tryParse(json['Thoi_gian_Kthuc'].toString()) : null,
      trangThai: json['Trang_thai'],
      maNguoiDung: json['Ma_nguoi_dung'] as int?,
      maChuyenKhoa: json['Ma_chuyen_khoa'] as int?,
      moTaBanThan: json['Mo_ta_ban_than'] as String?,
      hocVi: json['Hoc_vi'] as String?,
      namKinhNghiem: json['Nam_kinh_nghiem'] as int?,
      tomTatDanhGia: json['Tom_tat_danh_gia'] as String?,
      badgesSentiment: parsedBadges, // Gán mảng đã parse
      trangThaiHoatDong: json['Trang_thai_hoat_dong'] as String?,
      tenNguoiDung: json['Ten_nguoi_dung'] as String?,
      email: json['Email'] as String?,
      dienThoai: json['Dien_thoai'] as String?,
      anhDaiDien: json['Anh_dai_dien'] as String?,
      tenPhongKham: json['Ten_phong_kham'] as String?,
      moTaPhongKham: json['Mo_ta_phong_kham'] as String?,
      viTri: json['Vi_tri'] as String?,
      // 🌟 Ép kiểu String sang Double an toàn cho Tọa độ
      kinhDo: json['Kinh_do'] != null ? double.tryParse(json['Kinh_do'].toString()) : null,
      viDo: json['Vi_do'] != null ? double.tryParse(json['Vi_do'].toString()) : null,
      linkTrangWeb: json['Link_trang_web'] as String?,
    );
  }
}