import 'package:jitsi_meet_wrapper/jitsi_meet_wrapper.dart';

class JitsiService {
  // Hàm này sẽ được gọi khi người dùng bấm nút "Tham gia"
  static Future<void> joinOnlineConsultation({
    required String bookingCode,
    required String patientName,
    required String patientEmail,
  }) async {
    final serverUrl = "https://meet.ffmuc.net";
    try {
      // 1. Tạo tên phòng ĐỘC NHẤT dựa trên mã lịch hẹn (Không chứa dấu cách, ký tự đặc biệt)
      String roomName = "PhongKhamOnline_$bookingCode";

      // 2. Cấu hình các tùy chọn cho cuộc họp
      var options = JitsiMeetingOptions(
        roomNameOrUrl: roomName,
        //serverUrl: "https://meet.jit.si", // Dùng server miễn phí của Jitsi
        serverUrl: serverUrl,
        subject: "Phòng khám Online - Lịch hẹn $bookingCode",
        userDisplayName: patientName,
        userEmail: patientEmail,
        isAudioMuted: true, // Vào phòng mặc định tắt mic để đỡ ồn
        isVideoMuted: false, // Bật camera ngay khi vào
      );

      // 3. Khởi chạy màn hình gọi Video Jitsi
      await JitsiMeetWrapper.joinMeeting(options: options);
      
    } catch (error) {
      print("Lỗi khi tham gia Jitsi: $error");
    }
  }
}