class VitalModel {
  final String id;
  final String patientId;
  final int pulseRate;
  final String status; // 'normal', 'warning', 'critical'
  final DateTime? recordedAt;
  final DateTime createdAt;

  VitalModel({
    required this.id,
    required this.patientId,
    required this.pulseRate,
    required this.status,
    this.recordedAt,
    required this.createdAt,
  });

  factory VitalModel.fromJson(Map<String, dynamic> json) {
    return VitalModel(
      id: json['\$id'] as String,
      patientId: json['patientId'] as String,
      pulseRate: json['pulseRate'] as int,
      status: json['status'] as String? ?? 'normal',
      recordedAt: json['recordedAt'] != null
          ? DateTime.tryParse(json['recordedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['\$createdAt'] as String),
    );
  }

  /// Color-coded status for UI
  String get statusLabel {
    switch (status) {
      case 'critical':
        return 'Critical';
      case 'warning':
        return 'Warning';
      default:
        return 'Normal';
    }
  }
}
