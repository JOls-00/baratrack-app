class EvidenceModel {
  final int id;
  final int caseId;
  final String originalFilename;
  final String storedFilename;
  final String filePath;
  final String fileType;
  final String? description;
  final DateTime uploadedAt;

  EvidenceModel({
    required this.id,
    required this.caseId,
    required this.originalFilename,
    required this.storedFilename,
    required this.filePath,
    required this.fileType,
    this.description,
    required this.uploadedAt,
  });

  factory EvidenceModel.fromJson(Map<String, dynamic> json) {
    return EvidenceModel(
      id: json['id'],
      caseId: json['case_id'],
      originalFilename: json['original_filename'],
      storedFilename: json['stored_filename'],
      filePath: json['file_path'],
      fileType: json['file_type'],
      description: json['description'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }
}
