import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_app_mobile/features/auth/providers/auth_provider.dart';
import 'package:health_app_mobile/features/alerts/models/alert_model.dart';
import 'package:health_app_mobile/features/alerts/repository/alerts_repository.dart';

// ── Repository Provider ─────────────────────────────────────────────────────

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AlertsRepository(apiService);
});

// ── Alerts List Provider ────────────────────────────────────────────────────

final alertsProvider =
    FutureProvider.family<List<AlertModel>, String>((ref, patientId) async {
  final repo = ref.watch(alertsRepositoryProvider);
  return repo.getAlerts(patientId);
});
