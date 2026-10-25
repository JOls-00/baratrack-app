import 'package:flutter/foundation.dart';
import '../../config/app_constants.dart';
import '../../core/network/api_client.dart';
import '../models/case_model.dart';

class CaseRepository {
  final ApiClient _apiClient;

  CaseRepository(this._apiClient);

  Future<List<CaseModel>> getCases({String? query, String? status}) async {
    final response = await _apiClient.get(AppConstants.cases, queryParameters: {
      if (query != null) 'q': query,
      if (status != null) 'status': status,
    });
    
    return (response.data['data'] as List)
        .map((json) => CaseModel.fromJson(json))
        .toList();
  }

  Future<List<CaseModel>> getCasesByResident(int residentId) async {
    final response = await _apiClient.get(AppConstants.cases, queryParameters: {
      'resident_id': residentId,
    });
    
    return (response.data['data'] as List)
        .map((json) => CaseModel.fromJson(json))
        .toList();
  }

  Future<CaseModel> getCaseDetails(int id) async {
    final response = await _apiClient.get('${AppConstants.cases}/$id');
    return CaseModel.fromJson(response.data['data']);
  }

  Future<void> updateCaseStatus(int id, String status, String remarks) async {
    await _apiClient.put('${AppConstants.cases}/$id/status', data: {
      'status': status,
      'remarks': remarks,
    });
  }

  Future<void> createCaseFromComplaint(int complaintId) async {
    debugPrint("DEBUG: Repository calling POST ${AppConstants.cases} with complaint_id: $complaintId");
    try {
      final response = await _apiClient.post(AppConstants.cases, data: {
        'complaint_id': complaintId,
      });
      debugPrint("DEBUG: Repository POST response: ${response.statusCode} - ${response.data}");
    } catch (e) {
      debugPrint("DEBUG: Repository POST error: $e");
      rethrow;
    }
  }
}
