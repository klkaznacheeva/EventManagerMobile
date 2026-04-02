class OrganizerSessionCreateRequest {
  final String eventId;
  final String title;
  final String? description;
  final String startDate;
  final String endDate;
  final String? location;
  final String? type;
  final int? ageLimit;
  final String status;

  OrganizerSessionCreateRequest({
    required this.eventId,
    required this.title,
    this.description,
    required this.startDate,
    required this.endDate,
    this.location,
    this.type,
    this.ageLimit,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'title': title,
      'description': description,
      'start_date': startDate,
      'end_date': endDate,
      'location': location,
      'type': type,
      'age_limit': ageLimit,
      'status': status,
    };
  }
}