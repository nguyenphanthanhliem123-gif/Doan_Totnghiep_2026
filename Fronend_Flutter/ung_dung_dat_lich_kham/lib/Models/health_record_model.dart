class HealthRecordModel {
  int id;
  String? bloodType;
  int gender;
  String recordName;
  String roll;
  DateTime dob;
  String address;
  String? allergy;
  String? underlyingDisease;

  HealthRecordModel({
    this.bloodType,
    required this.gender,
    required this.address,
    this.allergy,
    required this.dob,
    required this.recordName,
    required this.id,
    required this.roll,
    this.underlyingDisease
  });

  factory HealthRecordModel.fromJson(Map<String, dynamic> json){
    return HealthRecordModel(
      bloodType: json['Nhom_mau'], 
      gender: json['Gioi_tinh'] ?? 1, // Nếu null thì mặc định là 1 (Nam)
      address: json['Dia_chi'] ?? '', // ✅ FIX LỖI Ở ĐÂY: Nếu null thì biến thành chuỗi rỗng
      dob: json['Ngay_sinh'] != null ? DateTime.parse(json['Ngay_sinh']).toLocal() : DateTime.now(), // Nhớ dùng .toLocal()
      recordName: json['Ten_ho_so'] ?? 'Chưa cập nhật', 
      id: json['Ma_benh_nhan'] ?? 0, 
      roll: json['Vai_tro'] ?? '',
      underlyingDisease: json['Benh_nen'],
      allergy: json['Di_ung']
    );
  }
}