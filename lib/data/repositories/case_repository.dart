import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_constants.dart';
import '../../core/network/api_client.dart';
import '../models/case_model.dart';

class CaseRepository {
  final ApiClient _apiClient;

  CaseRepository(this._apiClient);

  Future<List<CaseModel>> getCases({String? query, String? status}) async {
    try {
      final response = await _apiClient.get(AppConstants.cases, queryParameters: {
        if (query != null) 'q': query,
        if (status != null) 'status': status,
      });
      
      final data = response.data['data'] as List;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('offline_cached_cases', jsonEncode(data));

      return data.map((json) => CaseModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[Offline Mode] Network failed for cases, falling back to cache: $e');
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('offline_cached_cases');
      if (cached != null) {
        final list = jsonDecode(cached) as List;
        return list.map((json) => CaseModel.fromJson(json)).toList();
      }
      rethrow;
    }
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
