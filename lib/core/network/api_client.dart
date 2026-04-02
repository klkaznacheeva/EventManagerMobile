import 'dart:convert';

import 'package:event_manager_app/core/config/api_config.dart';
import 'package:event_manager_app/core/storage/token_storage.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  final Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
  };

  Future<Map<String, dynamic>> get(
      String endpoint, {
        Map<String, String>? headers,
      }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final token = await TokenStorage.getToken();

    final response = await http.get(
      uri,
      headers: {
        ..._defaultHeaders,
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
        ...?headers,
      },
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
      String endpoint, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final token = await TokenStorage.getToken();

    final response = await http.post(
      uri,
      headers: {
        ..._defaultHeaders,
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
        ...?headers,
      },
      body: jsonEncode(body ?? {}),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(
      String endpoint, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final token = await TokenStorage.getToken();

    final response = await http.put(
      uri,
      headers: {
        ..._defaultHeaders,
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
        ...?headers,
      },
      body: jsonEncode(body ?? {}),
    );

    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    dynamic decodedBody;

    if (response.body.isNotEmpty) {
      try {
        decodedBody = jsonDecode(response.body);
      } catch (_) {
        decodedBody = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decodedBody is Map<String, dynamic>) {
        return decodedBody;
      }

      return {
        'data': decodedBody,
      };
    }

    throw Exception(
      'Ошибка запроса: ${response.statusCode}, ответ: $decodedBody',
    );
  }
}