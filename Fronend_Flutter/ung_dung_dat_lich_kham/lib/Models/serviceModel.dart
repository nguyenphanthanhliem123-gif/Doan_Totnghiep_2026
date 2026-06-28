class ServiceModel {
  final int id;
  final String serviceName;
  final int specId;
  final double price;
  final DateTime createAt;

  ServiceModel({
    required this.id,
    required this.createAt,
    required this.price,
    required this.serviceName,
    required this.specId
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json){
    return ServiceModel(
      id: json['id'] ?? 0, 
      createAt: DateTime.parse(json['Created_at']), 
      price: double.parse(json['Gia_mac_dinh'] ?? 0), 
      serviceName: json['Ten_dich_vu'] ?? '', 
      specId: json['Ma_chuyen_khoa'] ?? 0
    );
  }
}

class MyServiceModel {
  final int id;
  final String serviceName;
  final double price;
  final int specId;
  final int doctorId;
  final int? masterServiceId;

  MyServiceModel({
    required this.id,
    required this.serviceName,
    required this.price,
    required this.specId,
    required this.doctorId,
    this.masterServiceId,
  });

  factory MyServiceModel.fromJson(Map<String, dynamic> json) {
    return MyServiceModel(
      id: json['Ma_dich_vu'] ?? 0,
      serviceName: json['Ten_dich_vu'] ?? '',
      // Xử lý an toàn cho kiểu decimal/double từ MySQL
      price: double.tryParse(json['Gia_tien'].toString()) ?? 0.0,
      
      specId: json['Ma_chuyen_khoa'] ?? 0, 
      
      doctorId: json['Ma_bac_si'] ?? 0,
      masterServiceId: json['Ma_dv_goc'],
    );
  }
}