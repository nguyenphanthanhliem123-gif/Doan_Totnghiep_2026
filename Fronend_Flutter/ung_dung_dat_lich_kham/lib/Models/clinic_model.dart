class ClinicModel {
  final int id;
  final String name;
  final String? description;
  final String? address;
  final double? lat;
  final double? lng;
  final String? phone;
  final String? website;
  final String? email;
  final List<String> images;

  ClinicModel({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.lat,
    this.lng,
    this.phone,
    this.website,
    this.email,
    required this.images,
  });

  factory ClinicModel.fromJson(Map<String, dynamic> json) {
    // Chuyển mảng JSON thành List<String>
    var imageList = json['danh_sach_anh'] as List? ?? [];
    List<String> parsedImages = imageList.map((i) => i.toString()).toList();

    return ClinicModel(
      id: json['Ma_phong_kham'],
      name: json['Ten_phong_kham'] ?? 'Tên phòng khám trống',
      description: json['Mo_ta_phong_kham'],
      address: json['Vi_tri'] ?? '',
      lat: json['Kinh_do'] != null ? double.tryParse(json['Kinh_do'].toString()) : null,
      lng: json['Vi_do'] != null ? double.tryParse(json['Vi_do'].toString()) : null,
      phone: json['Dien_thoai'] ?? '',
      website: json['Link_trang_web']?? '',
      email: json['Email'] ?? '',
      images: parsedImages,
    );
  }
}