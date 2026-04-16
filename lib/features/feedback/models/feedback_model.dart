class FeedbackAuthorModel {
  final String id;
  final String firstName;
  final String? lastName;

  const FeedbackAuthorModel({
    required this.id,
    required this.firstName,
    this.lastName,
  });

  String get fullName {
    final parts = <String>[
      firstName,
      if (lastName != null && lastName!.trim().isNotEmpty) lastName!.trim(),
    ];

    return parts.join(' ').trim();
  }

  factory FeedbackAuthorModel.fromJson(Map<String, dynamic> json) {
    return FeedbackAuthorModel(
      id: json['id'].toString(),
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString(),
    );
  }
}

class FeedbackModel {
  final String id;
  final String eventId;
  final String userId;
  final int rating;
  final String? comment;
  final String createdAt;
  final String? updatedAt;
  final FeedbackAuthorModel? author;

  const FeedbackModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.updatedAt,
    this.author,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'].toString(),
      eventId: json['event_id'].toString(),
      userId: json['user_id'].toString(),
      rating: json['rating'] is int
          ? json['rating'] as int
          : int.tryParse(json['rating'].toString()) ?? 0,
      comment: json['comment']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString(),
      author: json['author'] is Map<String, dynamic>
          ? FeedbackAuthorModel.fromJson(json['author'] as Map<String, dynamic>)
          : null,
    );
  }
}