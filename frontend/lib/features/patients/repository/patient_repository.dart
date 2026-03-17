import 'package:health_app_mobile/core/services/api_service.dart';
import 'package:health_app_mobile/features/patients/models/patient_model.dart';

class PatientRepository {
  final ApiService _apiService;

  PatientRepository(this._apiService);

  /// Fetch patient details by ID from the backend
  Future<PatientModel> getPatient(String patientId) async {
    final response = await _apiService.get('/api/v1/patients/$patientId');
    return PatientModel.fromJson(response as Map<String, dynamic>);
  }
}
