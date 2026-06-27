class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String? avatar;
  final int? gender;
  final String? address;
  final DateTime? dob;
  final String? phone;
  String? role;
  int status;


  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatar,
    this.gender,
    this.address,
    this.dob,
    this.phone,
    this.status = 1,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json){
    return UserModel(
      id: json['Ma_nguoi_dung'], 
      fullName: json['Ten_nguoi_dung'] ?? '', 
      email: json['Email'],   
      avatar: json['Anh_dai_dien'],
      gender: json['Gioi_tinh'] ?? 1,
      address: json['Dia_chi'] ?? '',
      phone: json['Dien_thoai'] ?? '',
      dob: json['Ngay_sinh'] != null ? DateTime.parse(json['Ngay_sinh']).toLocal() : DateTime.now(),
      status: json['Trang_thai'] ?? 1,
      role: json['Phan_quyen'] ?? '',
    );
  }
}