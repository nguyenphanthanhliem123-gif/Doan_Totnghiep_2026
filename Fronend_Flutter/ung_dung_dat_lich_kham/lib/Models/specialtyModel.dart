class SpecialtyModel {
  final int id;
  final String name;
  final String description;
  final String? image;

  SpecialtyModel({
    required this.id,
    required this.name,
    required this.description,
    this.image,
  });

  factory SpecialtyModel.fromJson(Map<String, dynamic> json) {
    return SpecialtyModel(
      id: json['Ma_chuyen_khoa'] ?? 0,
      name: json['Ten_chuyen_khoa'] ?? 'Chưa có tên',
      description: json['Mo_ta'] ?? '',
      image: json['Icon'],
    );
  }
}