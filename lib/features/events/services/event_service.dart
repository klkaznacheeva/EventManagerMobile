import 'package:event_manager_app/core/config/api_config.dart';
import 'package:event_manager_app/core/network/api_client.dart';
import 'package:event_manager_app/features/events/models/event_model.dart';
import 'package:event_manager_app/features/events/models/session_model.dart';

class EventService {
  final ApiClient _apiClient;

  EventService(this._apiClient);

  Future<List<EventModel>> getEvents({
    String userMode = 'participant',
  }) async {
    final response = await _apiClient.get(
      ApiConfig.events,
      headers: {
        'X-User-Mode': userMode,
      },
    );

    final items = response['items'];

    if (items is List) {
      return items
          .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  Future<EventModel> getEventById(String eventId) async {
    final response = await _apiClient.get('${ApiConfig.events}$eventId');
    return EventModel.fromJson(response);
  }

  Future<List<SessionModel>> getSessionsByEventId(String eventId) async {
    final response = await _apiClient.get('/api/v1/sessions/event/$eventId');
    final items = response['items'];

    if (items is List) {
      return items
          .map((item) => SessionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  Future<void> joinEvent(String eventId) async {
    await _apiClient.post('${ApiConfig.events}$eventId/join');
  }
}