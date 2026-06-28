class ComplaintModel {
  final int id;
  final String reporterType;
  final int reporterId;
  final String reportedType;
  final int reportedId;
  final String reason;
  final String status;
  final String? resolutionNote;
  final int? resolvedBy;
  final String createdAt;
  final String? resolvedAt;
  final String reporterName;
  final String reporterEmail;
  final String reportedName;
  final String reportedEmail;
  final int? reportedStatus;

  ComplaintModel({
    required this.id,
    required this.reporterType,
    required this.reporterId,
    required this.reportedType,
    required this.reportedId,
    required this.reason,
    required this.status,
    this.resolutionNote,
    this.resolvedBy,
    required this.createdAt,
    this.resolvedAt,
    required this.reporterName,
    required this.reporterEmail,
    required this.reportedName,
    required this.reportedEmail,
    this.reportedStatus,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'],
      reporterType: json['reporter_type'] ?? '',
      reporterId: json['reporter_id'] ?? 0,
      reportedType: json['target_type'] ?? '',
      reportedId: json['target_id'] ?? 0,
      reason: json['content'] ?? '',
      status: json['status'] ?? 'open',
      resolutionNote: json['resolution_note'],
      resolvedBy: json['resolved_by'],
      createdAt: json['created_at'] ?? '',
      resolvedAt: json['resolved_at'],
      reporterName: json['reporter_name'] ?? 'Không rõ',
      reporterEmail: json['reporter_email'] ?? '',
      reportedName: json['reported_name'] ?? 'Không rõ',
      reportedEmail: json['reported_email'] ?? '',
      reportedStatus: json['reported_status'],
    );
  }
}