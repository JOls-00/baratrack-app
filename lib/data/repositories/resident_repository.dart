import 'package:dio/dio.dart';
import '../../config/app_constants.dart';
import '../../core/network/api_client.dart';
import '../models/resident_model.dart';

class ResidentRepository {
  final ApiClient _apiClient;

  ResidentRepository(this._apiClient);

  Future<List<ResidentModel>> getResidents({String? query, String? zone, String? status}) async {
    final response = await _apiClient.get(AppConstants.residents, queryParameters: {
      if (query != null && query.isNotEmpty) 'q': query,
      if (zone != null && zone.isNotEmpty) 'zone': zone,
      if (status != null && status.isNotEmpty) 'status': status,
    });
    
    return (response.data['data'] as List)
        .map((json) => ResidentModel.fromJson(json))
        .toList();
  }

  Future<ResidentModel?> getResidentByUserId(int userId) async {
    final response = await _apiClient.get(AppConstants.residents, queryParameters: {
      'user_id': userId,
    });
    final List data = response.data['data'] ?? [];
    if (data.isEmpty) return null;
    return ResidentModel.fromJson(data.first);
  }

  Future<ResidentModel> getResidentDetails(int id) async {
    final response = await _apiClient.get('${AppConstants.residents}?id=$id');
    return ResidentModel.fromJson(response.data['data']);
  }

  Future<int> createResident(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(AppConstants.residents, data: data);
      final idData = response.data['id'] ?? response.data['data']?['id'] ?? 0;
      if (idData is String) {
        return int.tryParse(idData) ?? 0;
      }
      return idData as int;
    } on DioException catch (e) {
      final msg = e.response?.data is Map && e.response?.data['message'] != null
          ? e.response?.data['message'].toString()
          : e.message ?? 'Failed to create resident profile';
      throw Exception(msg);
    }
  }

  Future<void> updateResident(int id, Map<String, dynamic> data) async {
    try {
      await _apiClient.put('${AppConstants.residents}?id=$id', data: data);
    } on DioException catch (e) {
      final msg = e.response?.data is Map && e.response?.data['message'] != null
          ? e.response?.data['message'].toString()
          : e.message ?? 'Failed to update resident record';
      throw Exception(msg);
    }
  }

  Future<void> deleteResident(int id) async {
    try {
      await _apiClient.delete('${AppConstants.residents}?id=$id');
    } on DioException catch (e) {
      final msg = e.response?.data is Map && e.response?.data['message'] != null
          ? e.response?.data['message'].toString()
          : e.message ?? 'Failed to delete resident record';
      throw Exception(msg);
    }
  }
}
