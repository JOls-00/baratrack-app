import '../../config/app_constants.dart';
import '../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiClient _apiClient;
  NotificationRepository(this._apiClient);

  Future<List<NotificationModel>> fetch() async {
    final response = await _apiClient.get(AppConstants.notifications);
    final list = (response.data['data'] as List?) ?? [];
    return list.map((n) => NotificationModel.fromJson(n as Map<String, dynamic>)).toList();
  }

  Future<void> _act(Map<String, dynamic> body) async {
    await _apiClient.post(AppConstants.notifications, data: body);
  }

  Future<void> markRead(int id) => _act({'action': 'read', 'id': id});
  Future<void> markAllRead() => _act({'action': 'read_all'});
  Future<void> delete(int id) => _act({'action': 'delete', 'id': id});
  Future<void> clearAll() => _act({'action': 'clear_all'});
}
