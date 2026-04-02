import 'package:event_manager_app/core/network/api_client.dart';
import 'package:event_manager_app/features/events/models/session_model.dart';
import 'package:event_manager_app/roles/organizer/models/organizer_session_create_request.dart';

class OrganizerSessionService {
  final ApiClient _apiClient;

  OrganizerSessionService(this._apiClient);

  Future<SessionModel> createSession(
      OrganizerSessionCreateRequest request,
      ) async {
    final response = await _apiClient.post(
      '/api/v1/sessions/',
      body: request.toJson(),
    );

    return SessionModel.fromJson(response);
  }
}