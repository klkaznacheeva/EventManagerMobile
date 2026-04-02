import 'dart:convert';
import 'dart:io';

import 'package:event_manager_app/core/config/api_config.dart';
import 'package:event_manager_app/core/network/api_client.dart';
import 'package:event_manager_app/core/storage/token_storage.dart';
import 'package:event_manager_app/features/profile/models/profile_model.dart';
import 'package:http/http.dart' as http;

class ProfileService {
  final ApiClient _apiClient;

  ProfileService(this._apiClient);

  Future<ProfileModel> getProfile() async {
    final response = await _apiClient.get('/api/v1/users/profile');
    return ProfileModel.fromJson(response);
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _apiClient.post(
      '/api/v1/users/change-password',
      body: {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
    );
  }

  Future<String?> uploadAvatar(File file) async {
    final token = await TokenStorage.getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/api/v1/users/upload-avatar'),
    );

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Ошибка загрузки аватара: ${response.statusCode}, ${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    if (data is Map<String, dynamic>) {
      return data['avatar_url']?.toString();
    }

    return null;
  }
}