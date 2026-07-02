class PaymentAdminModel {
  final int maThanhToan;
  final int? maNguoiDung;
  final String? tenNguoiDung;
  final String phuongThuc;
  final String trangThai;
  final String? maGiaoDich;
  final double tongTien;
  final String thoiDiem;
  final String? maBooking;

  PaymentAdminModel({
    required this.maThanhToan,
    this.maNguoiDung,
    this.tenNguoiDung,
    required this.phuongThuc,
    required this.trangThai,
    this.maGiaoDich,
    required this.tongTien,
    required this.thoiDiem,
    this.maBooking,
  });

  factory PaymentAdminModel.fromJson(Map<String, dynamic> json) {
    return PaymentAdminModel(
      maThanhToan: json['Ma_thanh_toan'],
      maNguoiDung: json['Ma_nguoi_dung'],
      tenNguoiDung: json['Ten_nguoi_dung'] ?? 'Khách',
      phuongThuc: json['Phuong_thuc'] ?? '',
      trangThai: json['Trang_thai_thanh_toan'] ?? 'pending',
      maGiaoDich: json['Ma_giao_dich'],
      tongTien: double.tryParse(json['Tong_tien'].toString()) ?? 0,
      thoiDiem: json['Thoi_diem_thanh_toan'] ?? '',
      maBooking: json['Ma_booking'],
    );
  }
}