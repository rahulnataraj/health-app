import 'package:health_app_mobile/core/services/api_service.dart';
import 'package:health_app_mobile/features/vitals/models/vital_model.dart';

class VitalsRepository {
  final ApiService _apiService;

  VitalsRepository(this._apiService);

  /// Fetch vitals history for a patient from the backend
  Future<List<VitalModel>> getVitalsHistory(String patientId, {int limit = 100}) async {
    final response = await _apiService.get('/api/v1/patients/$patientId/vitals?limit=$limit');

    if (response is List) {
      return response.map((json) => VitalModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
