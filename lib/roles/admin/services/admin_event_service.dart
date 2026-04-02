import 'package:event_manager_app/core/network/api_client.dart';
import 'package:event_manager_app/features/events/models/event_model.dart';

class AdminEventService {
  final ApiClient _apiClient;

  AdminEventService(this._apiClient);

  Future<List<EventModel>> getPendingEvents() async {
    final response = await _apiClient.get('/api/v1/events/?status=pending');
    final items = response['items'];

    if (items is List) {
      return items
          .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  Future<void> markReviewed(String eventId) async {
    await _apiClient.post('/api/v1/events/$eventId/reviewed');
  }

  Future<void> markNeedsEdit({
    required String eventId,
    required String reason,
  }) async {
    await _apiClient.post(
      '/api/v1/events/$eventId/needs-edit',
      body: {
        'reason': reason,
      },
    );
  }
}