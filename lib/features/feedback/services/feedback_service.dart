import 'package:event_manager_app/core/network/api_client.dart';
import 'package:event_manager_app/features/feedback/models/feedback_model.dart';
import 'package:event_manager_app/features/feedback/models/feedback_summary_model.dart';

class FeedbackService {
  final ApiClient _apiClient;

  FeedbackService(this._apiClient);

  Future<FeedbackModel?> getMyFeedback(String eventId) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/events/$eventId/feedback/my',
      );
      return FeedbackModel.fromJson(response);
    } catch (e) {
      final message = e.toString();
      if (message.contains('404')) {
        return null;
      }
      rethrow;
    }
  }

  Future<FeedbackModel> createFeedback({
    required String eventId,
    required int rating,
    String? comment,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/events/$eventId/feedback',
      body: {
        'rating': rating,
        'comment': comment?.trim().isEmpty == true ? null : comment?.trim(),
      },
    );

    return FeedbackModel.fromJson(response);
  }

  Future<FeedbackModel> updateFeedback({
    required String eventId,
    required int rating,
    String? comment,
  }) async {
    final response = await _apiClient.put(
      '/api/v1/events/$eventId/feedback',
      body: {
        'rating': rating,
        'comment': comment?.trim().isEmpty == true ? null : comment?.trim(),
      },
    );

    return FeedbackModel.fromJson(response);
  }

  Future<List<FeedbackModel>> getEventFeedbacks(String eventId) async {
    final response = await _apiClient.get(
      '/api/v1/events/$eventId/feedback',
    );

    final items = response['items'];

    if (items is List) {
      return items
          .map((item) => FeedbackModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  Future<FeedbackSummaryModel> getEventFeedbackSummary(String eventId) async {
    final response = await _apiClient.get(
      '/api/v1/events/$eventId/feedback/summary',
    );

    return FeedbackSummaryModel.fromJson(response);
  }
}