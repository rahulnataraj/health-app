import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_app_mobile/core/services/api_service.dart';
import 'package:health_app_mobile/features/auth/models/user_model.dart';
import 'package:health_app_mobile/features/auth/repository/auth_repository.dart';

// ── Singleton Providers ─────────────────────────────────────────────────────

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(baseUrl: 'https://health-app-o8wh.onrender.com');
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthRepository(apiService);
});

// ── Auth State ──────────────────────────────────────────────────────────────

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AsyncValue.loading()) {
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    try {
      final isLoggedIn = await _repo.isLoggedIn();
      if (isLoggedIn) {
        // Fetch real user profile from /auth/me
        final user = await _repo.getUserProfile();
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      // Token expired or network issue — treat as logged out
      await _repo.logout();
      state = const AsyncValue.data(null);
    }
  }

  Future<void> signup(String username, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repo.signup(username, email, password);
      // Auto-login after successful signup
      await login(email, password);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repo.login(email, password);
      // Now fetch full profile with patient_id
      final fullUser = await _repo.getUserProfile();
      state = AsyncValue.data(fullUser);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _repo.logout();
    state = const AsyncValue.data(null);
  }
}
