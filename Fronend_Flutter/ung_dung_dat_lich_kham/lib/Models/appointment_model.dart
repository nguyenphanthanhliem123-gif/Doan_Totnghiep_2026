class AppointmentModel {
  final int id;
  final String bookingCode;
  final int doctorId;
  final String status;
  final String type;
  final DateTime startTime;
  final DateTime endTime;
  final String doctorName;
  final String? doctorAvatar;
  final int? specialtyId;
  final String? specialtyName;
  final String totalPrice;

  AppointmentModel({
    required this.id,
    required this.bookingCode,
    required this.doctorId,
    required this.status,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.doctorName,
    this.doctorAvatar,
    this.specialtyId,
    this.specialtyName,
    required this.totalPrice,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['Ma_lich_hen'],
      bookingCode: json['Ma_booking'],
      doctorId: json['Ma_bac_si'] ?? 0,
      status: json['Trang_thai_lich_hen'],
      type: json['Hinh_thuc'],
      // toLocal() để chuyển giờ UTC từ database sang giờ Việt Nam trên điện thoại
      startTime: DateTime.parse(json['Thoi_gian_Bdau']).toLocal(),
      endTime: DateTime.parse(json['Thoi_gian_Kthuc']).toLocal(),
      doctorName: json['Ten_bac_si'],
      doctorAvatar: json['Anh_bac_si'],
      specialtyId: json['Ma_chuyen_khoa'] ?? 0,
      specialtyName: json['Ten_chuyen_khoa'] ?? '',
      totalPrice: json['Tong_tien'] ?? '0',
    );
  }
}