class HearingModel {
  final int id;
  final int caseId;
  final String caseNumber;
  final DateTime hearingDate;
  final String hearingTime;
  final String venue;
  final String? notes;
  final String status;

  HearingModel({
    required this.id,
    required this.caseId,
    required this.caseNumber,
    required this.hearingDate,
    required this.hearingTime,
    required this.venue,
    this.notes,
    required this.status,
  });

  factory HearingModel.fromJson(Map<String, dynamic> json) {
    return HearingModel(
      id: json['id'],
      caseId: json['case_id'],
      caseNumber: json['case_number'] ?? '',
      hearingDate: DateTime.parse(json['hearing_date']),
      hearingTime: json['hearing_time'],
      venue: json['venue'],
      notes: json['notes'],
      status: json['status'],
    );
  }
}
