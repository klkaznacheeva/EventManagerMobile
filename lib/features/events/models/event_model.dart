import 'package:event_manager_app/features/events/models/session_model.dart';

class EventModel {
  final String id;
  final String title;
  final String? description;
  final String? location;

  final String status;
  final String? statusLabel;

  final int participantsCount;
  final bool isParticipant;

  final String startDate;
  final String endDate;

  final String? categoryId;
  final String? categoryName;

  final String? organizerName;
  final String? organizerEmail;

  final String createdAt;
  final String? updatedAt;

  final String? bannerUrl;
  final List<SessionModel> sessions;

  EventModel({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.status,
    this.statusLabel,
    required this.participantsCount,
    required this.isParticipant,
    required this.startDate,
    required this.endDate,
    this.categoryId,
    this.categoryName,
    this.organizerName,
    this.organizerEmail,
    required this.createdAt,
    this.updatedAt,
    this.bannerUrl,
    this.sessions = const [],
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final organizer = json['organizer'] as Map<String, dynamic>?;
    final sessionsJson = json['sessions'];

    final firstName = organizer?['first_name']?.toString();
    final lastName = organizer?['last_name']?.toString();

    String? organizerName;
    if (firstName != null && firstName.isNotEmpty) {
      organizerName = firstName;
      if (lastName != null && lastName.isNotEmpty) {
        organizerName = '$firstName $lastName';
      }
    }

    return EventModel(
      id: json['id'].toString(),
      title: json['title'].toString(),
      description: json['description']?.toString(),
      location: json['location']?.toString(),
      status: json['status'].toString(),
      statusLabel: json['status_label']?.toString(),
      participantsCount: json['participants_count'] ?? 0,
      isParticipant: json['is_participant'] ?? false,
      startDate: json['start_date'].toString(),
      endDate: json['end_date'].toString(),
      categoryId: category?['id']?.toString(),
      categoryName: category?['name']?.toString(),
      organizerName: organizerName,
      organizerEmail: organizer?['email']?.toString(),
      createdAt: json['created_at'].toString(),
      updatedAt: json['updated_at']?.toString(),
      bannerUrl: json['banner_url']?.toString(),
      sessions: sessionsJson is List
          ? sessionsJson
          .map(
            (item) => SessionModel.fromJson(item as Map<String, dynamic>),
      )
          .toList()
          : const [],
    );
  }
}