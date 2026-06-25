import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFF00C3C9);
const Color kInputBackgroundColor = Color(0xFFE8F7F8);
const Color kTextColor = Colors.black;
const Color kGreyTextColor = Colors.grey;

const TextStyle kHeaderTextStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white);
const TextStyle kLabelTextStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: kTextColor);
const TextStyle kInputTextStyle = TextStyle(fontSize: 14, color: kTextColor);
const TextStyle kButtonTextStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white);

// ==========================================
// CÁC HẰNG SỐ MỚI THÊM VÀO (ĐỒNG BỘ THEO HOME_SCREEN)
// ==========================================

// 1. Đồng bộ Màu sắc (Colors)
const Color kDarkCyan = Color(0xFF00A8B5); // Dùng cho phần bottom của Gradient
const Color kLightCyanBg1 = Color(0xFFE6F9FA); // Nền cho các item danh mục (Chuyên khoa, Hồ sơ...)
const Color kLightCyanBg2 = Color(0xFFF0F9FA); // Nền cho các icon tròn trên Header
const Color kBorderCyan = Color(0xFFE0F2F4); // Viền cho các icon tròn

// 2. Đồng bộ Khoảng cách (Padding & Margin)
const double kDefaultPadding = 20.0; // Lề chuẩn 2 bên mép màn hình
const double kSpacingSmall = 15.0; // Khoảng cách dọc nhỏ (SizedBox height)
const double kSpacingLarge = 25.0; // Khoảng cách dọc lớn (SizedBox height)

// 3. Đồng bộ Bo góc (Border Radius)
const double kBorderRadiusLarge = 20.0; // Bo góc cho khối lớn (Card lịch hẹn, ô chọn chuyên khoa)
const double kBorderRadiusMedium = 18.0; // Bo góc cho ô ngày tháng (Thanh cuộn 7 ngày)
const double kBorderRadiusSmall = 12.0; // Bo góc cho khối nhỏ (icon thể loại)