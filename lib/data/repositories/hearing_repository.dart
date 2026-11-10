import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_constants.dart';
import '../../core/network/api_client.dart';
import '../models/hearing_model.dart';

class HearingRepository {
  final ApiClient _apiClient;

  HearingRepository(this._apiClient);

  Future<List<HearingModel>> getHearings({String? status}) async {
    try {
      final response = await _apiClient.get(AppConstants.hearings, queryParameters: {
        if (status != null && status != 'All') 'status': status,
      });
      final data = response.data['data'] as List;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('offline_cached_hearings', jsonEncode(data));

      return data.map((json) => HearingModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[Offline Mode] Network failed for hearings, falling back to cache: $e');
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('offline_cached_hearings');
      if (cached != null) {
        final list = jsonDecode(cached) as List;
        return list.map((json) => HearingModel.fromJson(json)).toList();
      }
      rethrow;
    }
  }

  Future<void> scheduleHearing(Map<String, dynamic> data) async {
    await _apiClient.post(AppConstants.hearings, data: data);
  }

  Future<void> updateHearing(int id, Map<String, dynamic> data) async {
    await _apiClient.put('${AppConstants.hearings}/$id', data: data);
  }

  Future<void> updateHearingStatus(int id, String status) async {
    await _apiClient.put('${AppConstants.hearings}/$id/status', data: {'status': status});
  }
}
