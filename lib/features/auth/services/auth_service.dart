import 'package:event_manager_app/core/config/api_config.dart';
import 'package:event_manager_app/core/network/api_client.dart';
import 'package:event_manager_app/features/auth/models/auth_response.dart';
import 'package:event_manager_app/features/auth/models/login_request.dart';
import 'package:event_manager_app/features/auth/models/register_request.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<void> register(RegisterRequest request) async {
    await _apiClient.post(
      ApiConfig.register,
      body: request.toJson(),
    );
  }

  Future<AuthResponse> login(LoginRequest request) async {
    final response = await _apiClient.post(
      ApiConfig.login,
      body: request.toJson(),
    );

    return AuthResponse.fromJson(response);
  }
}