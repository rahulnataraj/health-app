import 'package:health_app_mobile/core/services/api_service.dart';
import 'package:health_app_mobile/features/auth/models/user_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  final ApiService _apiService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthRepository(this._apiService);

  /// Signup via FastAPI backend
  Future<void> signup(String username, String email, String password) async {
    await _apiService.post('/auth/signup', {
      'username': username,
      'email': email,
      'password': password,
    });
  }

  /// Login via FastAPI backend — stores JWT token and user_id
  Future<UserModel> login(String email, String password) async {
    final response = await _apiService.post('/auth/login', {
      'email': email,
      'password': password,
    });

    final String? token = response['access_token'];
    if (token == null) {
      throw Exception('Token not found in response');
    }

    // Persist credentials
    await _storage.write(key: 'jwt_token', value: token);
    await _storage.write(key: 'user_id', value: response['user_id']);
    if (response['role'] != null) {
      await _storage.write(key: 'role', value: response['role']);
    }

    return UserModel.fromLoginResponse(response);
  }

  /// Fetch full profile including linked patient_id from /auth/me
  Future<UserModel> getUserProfile() async {
    final response = await _apiService.get('/auth/me');
    final user = UserModel.fromMeResponse(response);

    // Cache patient_id for quick access
    if (user.patientId != null) {
      await _storage.write(key: 'patient_id', value: user.patientId!);
    }

    return user;
  }

  /// Get cached patient_id without an API call
  Future<String?> getStoredPatientId() async {
    return await _storage.read(key: 'patient_id');
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }
}
