import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_app_mobile/features/auth/providers/auth_provider.dart';
import 'package:health_app_mobile/features/vitals/models/vital_model.dart';
import 'package:health_app_mobile/features/vitals/repository/vitals_repository.dart';

// ── Repository Provider ─────────────────────────────────────────────────────

final vitalsRepositoryProvider = Provider<VitalsRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return VitalsRepository(apiService);
});

// ── Vitals History Provider (fetches list for a patient) ────────────────────

final vitalsHistoryProvider =
    FutureProvider.family<List<VitalModel>, String>((ref, patientId) async {
  final repo = ref.watch(vitalsRepositoryProvider);
  return repo.getVitalsHistory(patientId);
});

// ── Latest Vital Provider (derived from history) ────────────────────────────

final latestVitalProvider =
    FutureProvider.family<VitalModel?, String>((ref, patientId) async {
  final vitals = await ref.watch(vitalsHistoryProvider(patientId).future);
  return vitals.isNotEmpty ? vitals.first : null;
});
