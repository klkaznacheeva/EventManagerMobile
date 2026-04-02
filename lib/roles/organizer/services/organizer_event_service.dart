import 'package:event_manager_app/core/config/api_config.dart';
import 'package:event_manager_app/core/network/api_client.dart';
import 'package:event_manager_app/features/events/models/event_model.dart';
import 'package:event_manager_app/roles/organizer/models/organizer_event_create_request.dart';

class OrganizerEventService {
  final ApiClient _apiClient;

  OrganizerEventService(this._apiClient);

  Future<EventModel> createEvent(OrganizerEventCreateRequest request) async {
    final response = await _apiClient.post(
      ApiConfig.events,
      body: request.toJson(),
    );

    return EventModel.fromJson(response);
  }

  Future<EventModel> updateEvent({
    required String eventId,
    required OrganizerEventCreateRequest request,
  }) async {
    final response = await _apiClient.put(
      '${ApiConfig.events}$eventId',
      body: request.toJson(),
    );

    return EventModel.fromJson(response);
  }

  Future<EventModel> sendToReview({
    required String eventId,
    required EventModel event,
  }) async {
    final request = OrganizerEventCreateRequest(
      title: event.title,
      description: event.description,
      categoryId: event.categoryId ?? '',
      startDate: event.startDate,
      endDate: event.endDate,
      location: event.location,
      status: 'pending',
    );

    return updateEvent(
      eventId: eventId,
      request: request,
    );
  }

  Future<EventModel> publishEvent({
    required String eventId,
    required EventModel event,
  }) async {
    final request = OrganizerEventCreateRequest(
      title: event.title,
      description: event.description,
      categoryId: event.categoryId ?? '',
      startDate: event.startDate,
      endDate: event.endDate,
      location: event.location,
      status: 'published',
    );

    return updateEvent(
      eventId: eventId,
      request: request,
    );
  }
}