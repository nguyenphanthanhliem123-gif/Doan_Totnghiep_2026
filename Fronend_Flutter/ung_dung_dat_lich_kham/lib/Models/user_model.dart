class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String phone;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json){
    return UserModel(
      id: json['Ma_nguoi_dung'], 
      fullName: json['Ten_nguoi_dung'], 
      email: json['Email'], 
      phone: json['Dien_thoai'],  
    );
  }
}