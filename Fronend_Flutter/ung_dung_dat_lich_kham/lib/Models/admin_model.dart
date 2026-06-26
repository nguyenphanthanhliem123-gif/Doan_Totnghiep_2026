class AdminModel {
  final int id;
  final String email;
  final int isLocked;
  final int failedAttempts;

  AdminModel({
    required this.id,
    required this.email,
    required this.isLocked,
    required this.failedAttempts,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: json['id'],
      email: json['email'] ?? '',
      isLocked: json['is_locked'] ?? 0,
      failedAttempts: json['failed_attempts'] ?? 0,
    );
  }
}