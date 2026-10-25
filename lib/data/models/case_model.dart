import 'package:file_picker/file_picker.dart';
import 'resident_model.dart';

class CaseModel {
  final int id;
  final String caseNumber;
  final int complaintId;
  final String status; // Pending, Under Investigation, Settled, Closed
  final String? remarks;
  final DateTime updatedAt;
  final String? residentRole; // 'Complainant' or 'Respondent'
  final ComplaintModel? complaint;

  CaseModel({
    required this.id,
    required this.caseNumber,
    required this.complaintId,
    required this.status,
    this.remarks,
    required this.updatedAt,
    this.residentRole,
    this.complaint,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json['id'],
      caseNumber: json['case_number'],
      complaintId: json['complaint_id'],
      status: json['status'],
      remarks: json['remarks'],
      updatedAt: DateTime.parse(json['updated_at']),
      residentRole: json['resident_role'],
      complaint: json['complaint'] != null 
          ? ComplaintModel.fromJson(json['complaint']) 
          : null,
    );
  }
}

class ComplaintModel {
  final int id;
  final int? caseId;
  final String? caseNumber;
  final int typeId;
  final String typeName;
  final int complainantId;
  final int? respondentId;
  final String details;
  final String incidentLocation;
  final double? latitude;
  final double? longitude;
  final DateTime incidentDate;
  final String incidentTime;
  final String status;
  final DateTime dateFiled;
  final ResidentModel? complainant;
  final ResidentModel? respondent;
  final List<PlatformFile>? attachments;

  ComplaintModel({
    required this.id,
    this.caseId,
    this.caseNumber,
    required this.typeId,
    required this.typeName,
    required this.complainantId,
    this.respondentId,
    required this.details,
    required this.incidentLocation,
    this.latitude,
    this.longitude,
    required this.incidentDate,
    required this.incidentTime,
    required this.status,
    required this.dateFiled,
    this.complainant,
    this.respondent,
    this.attachments,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'],
      caseId: json['case_id'],
      caseNumber: json['case_number'],
      typeId: json['complaint_type_id'],
      typeName: json['type_name'] ?? '',
      complainantId: json['complainant_id'],
      respondentId: json['respondent_id'] == null ? null : (json['respondent_id'] as num).toInt(),
      details: json['details'],
      incidentLocation: json['location'] ?? '',
      latitude: json['latitude'] == null ? null : double.tryParse(json['latitude'].toString()),
      longitude: json['longitude'] == null ? null : double.tryParse(json['longitude'].toString()),
      incidentDate: DateTime.parse(json['incident_date'] ?? json['date_filed']),
      incidentTime: json['incident_time'] ?? '',
      status: json['status'],
      dateFiled: DateTime.parse(json['date_filed']),
      complainant: json['complainant'] != null ? ResidentModel.fromJson(json['complainant']) : null,
      respondent: json['respondent'] != null ? ResidentModel.fromJson(json['respondent']) : null,
      attachments: null,
    );
  }
}

/// One dot on the admin Incident Map. Carries no names or contact details.
class IncidentPin {
  final int id;
  final double latitude;
  final double longitude;
  final String typeName;
  final String status;
  final String location;
  final DateTime incidentDate;
  final String incidentTime;
  final String? caseNumber;
  final String complainantName;

  const IncidentPin({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.typeName,
    required this.status,
    required this.location,
    required this.incidentDate,
    required this.incidentTime,
    this.caseNumber,
    this.complainantName = '',
  });

  factory IncidentPin.fromJson(Map<String, dynamic> json) => IncidentPin(
        id: (json['id'] as num).toInt(),
        latitude: double.parse(json['latitude'].toString()),
        longitude: double.parse(json['longitude'].toString()),
        typeName: json['type_name']?.toString() ?? 'Other',
        status: json['status']?.toString() ?? 'Pending',
        location: json['location']?.toString() ?? '',
        incidentDate: DateTime.parse(json['incident_date'].toString()),
        incidentTime: json['incident_time']?.toString() ?? '',
        caseNumber: json['case_number']?.toString(),
        complainantName: json['complainant_name']?.toString() ?? '',
      );
}
