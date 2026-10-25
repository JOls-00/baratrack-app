import '../../config/app_constants.dart';
import '../../core/network/api_client.dart';
import '../models/hearing_model.dart';

class HearingRepository {
  final ApiClient _apiClient;

  HearingRepository(this._apiClient);

  Future<List<HearingModel>> getHearings({String? status}) async {
    final response = await _apiClient.get(AppConstants.hearings, queryParameters: {
      if (status != null && status != 'All') 'status': status,
    });
    return (response.data['data'] as List)
        .map((json) => HearingModel.fromJson(json))
        .toList();
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
