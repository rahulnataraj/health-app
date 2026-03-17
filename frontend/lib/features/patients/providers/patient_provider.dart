import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_app_mobile/features/auth/providers/auth_provider.dart';
import 'package:health_app_mobile/features/patients/models/patient_model.dart';
import 'package:health_app_mobile/features/patients/repository/patient_repository.dart';

// ── Repository Provider ─────────────────────────────────────────────────────

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PatientRepository(apiService);
});

// ── Patient Info Provider ───────────────────────────────────────────────────

final patientProvider =
    FutureProvider.family<PatientModel, String>((ref, patientId) async {
  final repo = ref.watch(patientRepositoryProvider);
  return repo.getPatient(patientId);
});
