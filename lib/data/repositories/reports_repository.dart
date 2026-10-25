import '../../core/network/api_client.dart';

class ReportsRepository {
  final ApiClient _apiClient;

  ReportsRepository(this._apiClient);

  Future<Map<String, dynamic>> getReports() async {
    final response = await _apiClient.get('/reports.php');
    return response.data['data'] as Map<String, dynamic>;
  }
}
