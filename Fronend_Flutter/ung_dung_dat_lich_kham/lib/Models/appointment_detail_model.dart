class AppointmentDetailModel {
  final int id;
  final String bookingCode;
  final int doctorId;
  final String type; // online, offline
  final String status;
  final String? note;
  final DateTime startTime;
  final DateTime endTime;
  
  final String doctorName;
  final String? doctorAvatar;
  // Lưu ý: Học vị và Chuyên khoa có thể null nếu API chưa join bảng này
  final String? doctorDegree; 
  final String? specialty;

  final String serviceName;
  final String clinicName;
  final String clinicAddress;
  
  final double totalPrice;
  final String paymentMethod;
  final String paymentStatus;
  
  final String patientName;
  final String relation;

  AppointmentDetailModel({
    required this.id,
    required this.bookingCode,
    required this.doctorId,
    required this.type,
    required this.status,
    this.note,
    required this.startTime,
    required this.endTime,
    required this.doctorName,
    this.doctorAvatar,
    this.doctorDegree,
    this.specialty,
    required this.serviceName,
    required this.clinicName,
    required this.clinicAddress,
    required this.totalPrice,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.patientName,
    required this.relation,
  });

  factory AppointmentDetailModel.fromJson(Map<String, dynamic> json) {
    return AppointmentDetailModel(
      id: json['Ma_lich_hen'] ?? 0,
      bookingCode: json['Ma_booking'] ?? '',
      doctorId: json['Ma_bac_si'] ?? 0,
      type: json['Hinh_thuc'] ?? 'offline',
      status: json['Trang_thai_lich_hen'] ?? 'pending',
      note: json['Ghi_chu'] ?? 'Không có ghi chú.',
      startTime: DateTime.parse(json['Thoi_gian_Bdau']).toLocal(),
      endTime: DateTime.parse(json['Thoi_gian_Kthuc']).toLocal(),
      doctorName: json['Ten_bac_si'] ?? 'Bác sĩ',
      doctorAvatar: json['Anh_bac_si'],
      doctorDegree: json['Hoc_vi'], // Có thể null
      specialty: json['Ten_chuyen_khoa'], // Có thể null
      serviceName: json['Ten_dich_vu'] ?? 'Chưa cập nhật',
      clinicName: json['Ten_phong_kham'] ?? 'Phòng khám',
      clinicAddress: json['Dia_chi_phong_kham'] ?? 'Chưa cập nhật địa chỉ',
      totalPrice: double.tryParse(json['Tong_tien'].toString()) ?? 0.0,
      paymentMethod: json['Phuong_thuc_thanh_toan'] ?? 'cash',
      paymentStatus: json['Trang_thai_thanh_toan'] ?? 'pending',
      patientName: json['Ten_nguoi_kham'] ?? '',
      relation: json['Moi_quan_he'] ?? 'Bản thân',
    );
  }
}