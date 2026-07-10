class WeeklyScheduleItem {
  final int thu;         // 2 -> 7
  final String buoi;      // 'sang', 'chieu', 'toi'
  final String gioBatDau; // "08:00"
  final String gioKetThuc;// "12:00"
  final String trangThai; // 'lam' hoặc 'nghi'

  WeeklyScheduleItem({
    required this.thu,
    required this.buoi,
    required this.gioBatDau,
    required this.gioKetThuc,
    required this.trangThai,
  });

  Map<String, dynamic> toJson() => {
    'thu': thu,
    'buoi': buoi,
    'gio_bat_dau': gioBatDau,
    'gio_ket_thuc': gioKetThuc,
    'trang_thai': trangThai,
  };
}

class DoctorScheduleConfigModel {
  final int slotTime;
  final int breakTime;
  final List<WeeklyScheduleItem> weeklySchedule;

  DoctorScheduleConfigModel({
    required this.slotTime,
    required this.breakTime,
    required this.weeklySchedule,
  });

  Map<String, dynamic> toJson() => {
    'slotTime': slotTime,
    'breakTime': breakTime,
    'weeklySchedule': weeklySchedule.map((e) => e.toJson()).toList(),
  };
}