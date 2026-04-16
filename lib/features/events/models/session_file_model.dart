class SessionFileModel {
  final String fileName;
  final String url;

  SessionFileModel({
    required this.fileName,
    required this.url,
  });

  factory SessionFileModel.fromJson(Map<String, dynamic> json) {
    return SessionFileModel(
      fileName: json['file_name']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }
}