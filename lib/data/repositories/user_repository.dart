
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

class UserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);

  Future<List<UserModel>> getUsers({String? status, String? role}) async {
    final Map<String, dynamic> params = {};
    if (status != null) params['status'] = status;
    if (role != null) params['role'] = role;

    final response = await _apiClient.get('/users.php', queryParameters: params.isNotEmpty ? params : null);
    return (response.data['data'] as List)
        .map((json) => UserModel.fromJson(json))
        .toList();
  }

  Future<UserModel> getUserDetails(int id) async {
    final response = await _apiClient.get('/users.php?id=$id');
    return UserModel.fromJson(response.data['data']);
  }

  Future<UserModel> updateProfile(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.put('/users.php?id=$id', data: data);
    return UserModel.fromJson(response.data['data']);
  }

  Future<void> updateUserStatus(int id, String status) async {
    await _apiClient.put('/users.php?id=$id', data: {'status': status});
  }

  Future<void> approveUser(int id) async {
    await _apiClient.put('/users.php/$id/approve');
  }

  Future<void> rejectUser(int id) async {
    await _apiClient.put('/users.php/$id/reject');
  }
}
