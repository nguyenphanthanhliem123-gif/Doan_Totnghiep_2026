class PaymentModel {
  int maThanhToan;
  int maLichHen;
  String maGiaoDich;
  String maLichHenChu;
  double gia;
  String phuongThuc;
  String trangThai;
  DateTime thoiGianGiaoDich;

  PaymentModel({
    required this.maThanhToan,
    required this.maLichHen,
    required this.gia,
    required this.maGiaoDich,
    required this.maLichHenChu,
    required this.phuongThuc,
    required this.thoiGianGiaoDich,
    required this.trangThai,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      maThanhToan: json['paymentId'] as int,
      maLichHen: json['scheduleId'] as int,
      maGiaoDich: json['transactionId'] ?? '',
      maLichHenChu: json['bookingCode'] ?? '',
      // Ép kiểu an toàn đề phòng API trả về int hoặc chuỗi
      gia: double.tryParse(json['amount'].toString()) ?? 0.0,
      phuongThuc: json['method'] ?? '',
      trangThai: json['status'] ?? '',
      // Parse từ chuỗi ISO-8601 sang DateTime, fallback về thời điểm hiện tại nếu null/lỗi
      thoiGianGiaoDich: json['transactionDate'] != null 
          ? DateTime.parse(json['transactionDate']) 
          : DateTime.now(),
    );
  }
}