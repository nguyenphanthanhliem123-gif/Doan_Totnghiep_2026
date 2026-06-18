import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:intl/intl.dart';

class CalendarUtils {
  // Biến hàm thành static để có thể gọi trực tiếp mà không cần khởi tạo class
  static void addToCalendar(BuildContext context, dynamic appointment) async {
    String location = 'Phòng khám Đa khoa Tâm Anh'; 
    if (appointment.type == 'online') {
      location = 'Khám trực tuyến (Video Call)';
    } else {
      try {
        location = appointment.clinicAddress ?? appointment.clinicName ?? 'Tại phòng khám';
      } catch (e) {
        location = 'Tại phòng khám'; 
      }
    }

    if (kIsWeb) {
      // Logic dành cho trình duyệt Web
      final DateFormat formatter = DateFormat("yyyyMMdd'T'HHmmss'Z'");
      final String start = formatter.format(appointment.startTime.toUtc());
      final String end = formatter.format(appointment.endTime.toUtc());

      final String title = Uri.encodeComponent('Lịch khám bệnh - BS. ${appointment.doctorName}');
      final String details = Uri.encodeComponent('Mã đặt lịch: ${appointment.bookingCode}\n\nVui lòng đến trước 15 phút để làm thủ tục.');
      final String loc = Uri.encodeComponent(location);

      final String googleCalendarUrl = 'https://calendar.google.com/calendar/render?action=TEMPLATE&text=$title&dates=$start/$end&details=$details&location=$loc';

      if (await canLaunchUrl(Uri.parse(googleCalendarUrl))) {
        await launchUrl(Uri.parse(googleCalendarUrl), mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể mở Google Calendar.')));
        }
      }
    } else {
      // Logic dành cho App Mobile
      final Event event = Event(
        title: 'Lịch khám bệnh - BS. ${appointment.doctorName}',
        description: 'Mã đặt lịch: ${appointment.bookingCode}',
        location: location,
        startDate: appointment.startTime,
        endDate: appointment.endTime,
        iosParams: const IOSParams(reminder: Duration(hours: 2)),
        androidParams: const AndroidParams(emailInvites: []),
      );

      Add2Calendar.addEvent2Cal(event).then((success) {
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã mở ứng dụng Lịch! Hãy bấm Lưu nhé.'), backgroundColor: Colors.green),
          );
        }
      });
    }
  }
}