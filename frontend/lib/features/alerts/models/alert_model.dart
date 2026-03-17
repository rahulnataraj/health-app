class AlertModel {
  final String id;
  final String patientId;
  final String message;
  final String severity; // 'critical', 'warning', 'info'
  final int? pulseRate;
  final DateTime createdAt;
  final bool isRead;

  AlertModel({
    required this.id,
    required this.patientId,
    required this.message,
    required this.severity,
    this.pulseRate,
    required this.createdAt,
    this.isRead = false,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['\$id'] as String,
      patientId: json['patientId'] as String,
      message: json['message'] as String,
      severity: json['severity'] as String? ?? 'info',
      pulseRate: json['pulseRate'] as int?,
      createdAt: DateTime.parse(json['\$createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}
