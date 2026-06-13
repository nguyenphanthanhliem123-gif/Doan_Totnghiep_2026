class ReviewModel {
  final int id;
  final int doctorId;
  final String patientName;
  final String? patientAvatar;
  final int rating;
  final String content;
  final String createdAt;

  ReviewModel({
    required this.id,
    required this.doctorId,
    required this.patientName,
    this.patientAvatar,
    required this.rating,
    required this.content,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['Ma_danh_gia'],
      doctorId: json['Ma_bac_si'],
      patientName: json['Ten_benh_nhan'] ?? 'Bệnh nhân ẩn danh',
      patientAvatar: json['Anh_dai_dien'],
      rating: json['So_sao'] ?? 5,
      content: json['Noi_dung'] ?? '',
      createdAt: json['Ngay_tao'] ?? '',
    );
  }
}