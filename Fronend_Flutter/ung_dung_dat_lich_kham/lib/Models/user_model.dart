class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatar;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatar
  });

  factory UserModel.fromJson(Map<String, dynamic> json){
    return UserModel(
      id: json['Ma_nguoi_dung'], 
      fullName: json['Ten_nguoi_dung'], 
      email: json['Email'], 
      phone: json['Dien_thoai'],  
      avatar: json['Anh_dai_dien']
    );
  }
}