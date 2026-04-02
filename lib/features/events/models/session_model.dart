class SessionModel {
  final String id;
  final String eventId;
  final String title;
  final String? description;
  final String startDate;
  final String endDate;
  final String? location;
  final String? type;
  final int? ageLimit;
  final String? status;
  final String? statusLabel;
  final String? createdAt;

  SessionModel({
    required this.id,
    required this.eventId,
    required this.title,
    this.description,
    required this.startDate,
    required this.endDate,
    this.location,
    this.type,
    this.ageLimit,
    this.status,
    this.statusLabel,
    this.createdAt,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'].toString(),
      eventId: json['event_id']?.toString() ?? '',
      title: json['title'].toString(),
      description: json['description']?.toString(),
      startDate: json['start_date'].toString(),
      endDate: json['end_date'].toString(),
      location: json['location']?.toString(),
      type: json['type']?.toString(),
      ageLimit: json['age_limit'],
      status: json['status']?.toString(),
      statusLabel: json['status_label']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}