class PatientModel {
  final String id;
  final String name;
  final int age;
  final String doctorId;
  final String familyUserId;
  final String? medicalCondition;
  final String? admissionDate;

  PatientModel({
    required this.id,
    required this.name,
    required this.age,
    required this.doctorId,
    required this.familyUserId,
    this.medicalCondition,
    this.admissionDate,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['\$id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      doctorId: json['doctorId'] as String,
      familyUserId: json['familyUserId'] as String,
      medicalCondition: json['medicalCondition'] as String?,
      admissionDate: json['admissionDate'] as String?,
    );
  }
}
