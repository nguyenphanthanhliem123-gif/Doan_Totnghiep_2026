// Model cho từng Dịch vụ của bác sĩ
class DoctorServiceModel {
  final int id;
  final String name;
  final double price;

  DoctorServiceModel({
    required this.id,
    required this.name,
    required this.price,
  });

  factory DoctorServiceModel.fromJson(Map<String, dynamic> json) {
    return DoctorServiceModel(
      id: json['Ma_dich_vu'],
      name: json['Ten_dich_vu'],
      // Chuyển đổi dữ liệu kiểu decimal từ MySQL sang double của Dart
      price: double.tryParse(json['Gia_tien'].toString()) ?? 0.0, 
    );
  }
}

// Model cho từng Khung giờ của bác sĩ
class DoctorTimeSlotModel {
  final int id;
  final String time;
  final String status;

  DoctorTimeSlotModel({required this.id, required this.time, required this.status});

  factory DoctorTimeSlotModel.fromJson(Map<String, dynamic> json) {
    return DoctorTimeSlotModel(
      id: json['id'],
      time: json['time'].toString().substring(0, 5),
      status: json['status'],
    );
  }
}

// Model cho từng ngày
class DoctorScheduleModel {
  final String date; // Ví dụ: "2026-06-12"
  final List<DoctorTimeSlotModel> slots;

  DoctorScheduleModel({required this.date, required this.slots});

  factory DoctorScheduleModel.fromJson(Map<String, dynamic> json) {
    var slotList = json['slots'] as List? ?? [];
    List<DoctorTimeSlotModel> parsedSlots = slotList.map((i) => DoctorTimeSlotModel.fromJson(i)).toList();
    return DoctorScheduleModel(date: json['date'], slots: parsedSlots);
  }
}

class DoctorDetailModel {
  final int id;
  final String fullName;
  final String? avatar;
  final String? degree;
  final int? yearsOfExperience;
  final String? description;
  final String? specialtyName;
  final String? clinicName;
  final String? clinicAddress;
  
  // Thêm biến chứa danh sách dịch vụ
  final List<DoctorServiceModel> services; 

  // Thêm biến chứa danh sách lịch làm việc
  final List<DoctorScheduleModel> schedules;

  DoctorDetailModel({
    required this.id,
    required this.fullName,
    this.avatar,
    this.degree,
    this.yearsOfExperience,
    this.description,
    this.specialtyName,
    this.clinicName,
    this.clinicAddress,
    required this.services,
    required this.schedules,
  });

  factory DoctorDetailModel.fromJson(Map<String, dynamic> json) {
    // Ép kiểu mảng JSON từ Node.js thành List<DoctorServiceModel>
    var serviceList = json['dich_vu'] as List? ?? [];
    List<DoctorServiceModel> parsedServices = serviceList.map((i) => DoctorServiceModel.fromJson(i)).toList();

    var scheduleList = json['lich_lam_viec'] as List? ?? [];
    List<DoctorScheduleModel> parsedSchedules = scheduleList.map((i) => DoctorScheduleModel.fromJson(i)).toList();

    return DoctorDetailModel(
      id: json['Ma_bac_si'],
      fullName: json['Ho_ten'] ?? 'Chưa cập nhật tên',
      avatar: json['Anh_dai_dien'],
      degree: json['Hoc_vi'],
      yearsOfExperience: json['Nam_kinh_nghiem'],
      description: json['Mo_ta_ban_than'],
      specialtyName: json['Ten_chuyen_khoa'],
      clinicName: json['Ten_phong_kham'],
      clinicAddress: json['Dia_chi'],
      services: parsedServices, // Gán vào model
      schedules: parsedSchedules, // Gán vào model
    );
  }
}