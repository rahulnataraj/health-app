import 'package:health_app_mobile/core/services/api_service.dart';
import 'package:health_app_mobile/features/alerts/models/alert_model.dart';

class AlertsRepository {
  final ApiService _apiService;

  AlertsRepository(this._apiService);

  /// Fetch alerts for a patient from the backend
  Future<List<AlertModel>> getAlerts(String patientId) async {
    final response = await _apiService.get('/api/v1/alerts/$patientId');

    if (response is List) {
      return response.map((json) => AlertModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
