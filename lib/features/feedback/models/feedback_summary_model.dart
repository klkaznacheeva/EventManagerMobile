class RatingBreakdownItemModel {
  final int rating;
  final int count;

  const RatingBreakdownItemModel({
    required this.rating,
    required this.count,
  });

  factory RatingBreakdownItemModel.fromJson(Map<String, dynamic> json) {
    return RatingBreakdownItemModel(
      rating: json['rating'] is int
          ? json['rating'] as int
          : int.tryParse(json['rating'].toString()) ?? 0,
      count: json['count'] is int
          ? json['count'] as int
          : int.tryParse(json['count'].toString()) ?? 0,
    );
  }
}

class FeedbackSummaryModel {
  final String eventId;
  final int totalFeedbacks;
  final double averageRating;
  final List<RatingBreakdownItemModel> breakdown;

  const FeedbackSummaryModel({
    required this.eventId,
    required this.totalFeedbacks,
    required this.averageRating,
    required this.breakdown,
  });

  factory FeedbackSummaryModel.fromJson(Map<String, dynamic> json) {
    final breakdownJson = json['breakdown'];

    return FeedbackSummaryModel(
      eventId: json['event_id'].toString(),
      totalFeedbacks: json['total_feedbacks'] is int
          ? json['total_feedbacks'] as int
          : int.tryParse(json['total_feedbacks'].toString()) ?? 0,
      averageRating: json['average_rating'] is num
          ? (json['average_rating'] as num).toDouble()
          : double.tryParse(json['average_rating'].toString()) ?? 0,
      breakdown: breakdownJson is List
          ? breakdownJson
          .map((item) => RatingBreakdownItemModel.fromJson(
        item as Map<String, dynamic>,
      ))
          .toList()
          : const [],
    );
  }
}