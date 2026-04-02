class OrganizerEventCreateRequest {
  final String title;
  final String? description;
  final String categoryId;
  final String startDate;
  final String endDate;
  final String? location;
  final String status;

  OrganizerEventCreateRequest({
    required this.title,
    this.description,
    required this.categoryId,
    required this.startDate,
    required this.endDate,
    this.location,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category_id': categoryId,
      'start_date': startDate,
      'end_date': endDate,
      'location': location,
      'status': status,
    };
  }
}