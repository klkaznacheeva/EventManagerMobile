import 'package:event_manager_app/core/config/api_config.dart';

class ProfileModel {
  final String id;
  final String firstName;
  final String? secondName;
  final String? lastName;
  final String email;
  final String? phone;
  final String? birthDate;
  final bool isSystem;
  final String? avatarUrl;

  ProfileModel({
    required this.id,
    required this.firstName,
    this.secondName,
    this.lastName,
    required this.email,
    this.phone,
    this.birthDate,
    required this.isSystem,
    this.avatarUrl,
  });

  String get fullName {
    final parts = <String>[
      firstName,
      if (secondName != null && secondName!.isNotEmpty) secondName!,
      if (lastName != null && lastName!.isNotEmpty) lastName!,
    ];

    return parts.join(' ').trim();
  }

  static String? _normalizeAvatarUrl(dynamic rawValue) {
    if (rawValue == null) return null;

    final value = rawValue.toString().trim();
    if (value.isEmpty) return null;

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value.replaceFirst('localhost', '10.0.2.2');
    }

    final baseUrl = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;

    if (value.startsWith('/')) {
      return '$baseUrl$value';
    }

    return '$baseUrl/$value';
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'].toString(),
      firstName: json['first_name']?.toString() ?? '',
      secondName: json['second_name']?.toString(),
      lastName: json['last_name']?.toString(),
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      birthDate: json['birth_date']?.toString(),
      isSystem: json['is_system'] ?? false,
      avatarUrl: _normalizeAvatarUrl(json['avatar_url']),
    );
  }
}