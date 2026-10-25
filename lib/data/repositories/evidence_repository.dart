import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../../config/app_constants.dart';
import '../../core/network/api_client.dart';

class EvidenceRepository {
  final ApiClient _apiClient;

  EvidenceRepository(this._apiClient);

  Future<void> uploadEvidence({
    int? caseId,
    int? complaintId,
    required PlatformFile file,
    String? description,
  }) async {
    if (caseId == null && complaintId == null) {
      throw ArgumentError('Either caseId or complaintId must be provided.');
    }

    MultipartFile multipartFile;

    if (kIsWeb) {
      // On Web, path is null, use bytes
      if (file.bytes == null) throw Exception("File data is missing (bytes are null)");
      multipartFile = MultipartFile.fromBytes(
        file.bytes!,
        filename: file.name,
      );
    } else {
      // On Mobile/Desktop, use path
      if (file.path == null) throw Exception("File path is missing");
      multipartFile = await MultipartFile.fromFile(
        file.path!,
        filename: file.name,
      );
    }

    final map = <String, dynamic>{
      if (caseId != null) 'case_id': caseId,
      if (complaintId != null) 'complaint_id': complaintId,
      if (description != null) 'description': description,
      'file': multipartFile,
    };

    final formData = FormData.fromMap(map);

    await _apiClient.postMultipart(AppConstants.evidence, formData);
  }

  Future<List<Map<String, dynamic>>> getEvidenceForCase(int caseId) async {
    final response = await _apiClient.get(AppConstants.evidence, queryParameters: {
      'case_id': caseId,
    });
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  Future<List<Map<String, dynamic>>> getEvidenceForComplaint(int complaintId) async {
    final response = await _apiClient.get(AppConstants.evidence, queryParameters: {
      'complaint_id': complaintId,
    });
    return List<Map<String, dynamic>>.from(response.data['data']);
  }
}
