import 'package:flutter/foundation.dart';
import '../../config/app_constants.dart';
import '../../core/network/api_client.dart';
import '../models/case_model.dart';

class ComplaintRepository {
  final ApiClient _apiClient;

  ComplaintRepository(this._apiClient);

  Future<List<ComplaintModel>> getMyComplaints() async {
    debugPrint("DEBUG: Repository calling GET ${AppConstants.complaints}");
    try {
      final response = await _apiClient.get(AppConstants.complaints);
      debugPrint("DEBUG: Repository GET response: ${response.statusCode}");
      return (response.data['data'] as List)
          .map((json) => ComplaintModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint("DEBUG: Repository GET error: $e");
      rethrow;
    }
  }

  Future<List<IncidentPin>> getIncidentMap({String? dateFrom, String? dateTo}) async {
    final response = await _apiClient.get(AppConstants.incidentMap, queryParameters: {
      if (dateFrom != null) 'date_from': dateFrom,
      if (dateTo != null) 'date_to': dateTo,
    });
    return (response.data['data'] as List).map((j) => IncidentPin.fromJson(Map<String, dynamic>.from(j as Map))).toList();
  }

  Future<int> fileComplaint(Map<String, dynamic> data) async {
    final response = await _apiClient.post(AppConstants.complaints, data: data);
    final rawId = response.data['id'] ?? response.data['data']?['id'];
    if (rawId is int) return rawId;
    if (rawId is String) return int.tryParse(rawId) ?? 0;
    return 0;
  }
}
