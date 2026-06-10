class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String? avatar;
  final int? gender;
  final String? address;
  final DateTime? dob;


  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatar,
    this.gender,
    this.address,
    this.dob
  });

  factory UserModel.fromJson(Map<String, dynamic> json){
    return UserModel(
      id: json['Ma_nguoi_dung'], 
      fullName: json['Ten_nguoi_dung'] ?? '', 
      email: json['Email'],   
      avatar: json['Anh_dai_dien'],
      gender: json['Gioi_tinh'] ?? 1,
      address: json['Dia_chi'] ?? '',
      dob: json['Ngay_sinh'] != null ? DateTime.parse(json['Ngay_sinh']) : DateTime.now(),
    );
  }
}