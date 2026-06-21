class NotificationModel {
  int notificationID;
  int userID;
  String type;
  String content;
  DateTime date;
  int status;

  NotificationModel({
    required this.content,
    required this.date,
    required this.notificationID,
    required this.status,
    required this.type,
    required this.userID
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json){
    return NotificationModel(
      content: json['Noi_dung'] ?? '', 
      date: json['Ngay_gui'] != null ? DateTime.parse(json['Ngay_gui']).toLocal() : DateTime.now(),
      notificationID: json['Ma_thong_bao'] ?? 0, 
      status: json['Trang_thai_doc'] ?? 0, 
      type: json['Loai'] ?? '', 
      userID: json['Ma_nguoi_dung'] ?? 0
    );
  }
}