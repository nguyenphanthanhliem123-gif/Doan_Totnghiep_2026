class UserModel {
  final int id;
  final String fullName;
  final String email;
<<<<<<< HEAD
=======
  final String? phone;
>>>>>>> 04190d81da100fd8db7fdb363b326827a2c6e4de
  final String? avatar;
  final int? gender;
  final String? address;
  final DateTime? dob;


  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
<<<<<<< HEAD
    this.avatar,
    this.gender,
    this.address,
    this.dob
=======
    this.phone,
    this.avatar
>>>>>>> 04190d81da100fd8db7fdb363b326827a2c6e4de
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