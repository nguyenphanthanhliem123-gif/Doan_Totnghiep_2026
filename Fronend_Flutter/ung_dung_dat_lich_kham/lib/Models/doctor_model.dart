class DoctorModel {
  final int id;
  final String name;
  final String specialtyName;
  final String? avatar;
  final String? degree; // Học vị (Thạc sĩ, Tiến sĩ...)
  final int experienceYears;
  final String? ratingSummary; // Tóm tắt đánh giá (Ví dụ: "Thân thiện, chuyên môn cao")
  final int? specialtyId;
  final String? description;

  DoctorModel({
    required this.id,
    required this.name,
    required this.specialtyName,
    this.avatar,
    this.degree,
    required this.experienceYears,
    this.ratingSummary,
    required this.specialtyId,
    this.description,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['Ma_bac_si'] ?? 0,
      name: json['Ten_bac_si'] ?? 'Chưa cập nhật',
      specialtyName: json['Ten_chuyen_khoa'] ?? 'Chưa rõ khoa',
      avatar: json['Anh_dai_dien'],
      degree: json['Hoc_vi'],
      experienceYears: json['Nam_kinh_nghiem'] ?? 0,
      ratingSummary: json['Tom_tat_danh_gia'],
      specialtyId: json['Ma_chuyen_khoa'] ?? 0,
      description: json['Mo_ta_ban_than'] ?? '',
    );
  }
}