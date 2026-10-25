import 'package:dio/dio.dart';
import '../../config/app_constants.dart';
import '../../core/network/api_client.dart';

class AdminFaq {
  final int id;
  final String category;
  final String question;
  final String answer;
  final int sortOrder;
  final bool isActive;
  const AdminFaq({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    required this.sortOrder,
    required this.isActive,
  });
}

/// Staff-side editing of portal content (announcements and FAQs).
/// Reading announcements for everyone still goes through PortalRepository.
class ContentRepository {
  final ApiClient _apiClient;
  ContentRepository(this._apiClient);

  Future<void> _send(String path, Map<String, dynamic> body) async {
    try {
      await _apiClient.post(path, data: body);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw Exception(data['message'].toString());
      }
      throw Exception('Could not reach the server. Please try again.');
    }
  }

  // ---------- Announcements ----------
  Future<void> saveAnnouncement({int? id, required String title, required String body}) {
    return _send(AppConstants.adminAnnouncements, {
      'action': id == null ? 'create' : 'update',
      if (id != null) 'id': id,
      'title': title,
      'body': body,
    });
  }

  Future<void> deleteAnnouncement(int id) {
    return _send(AppConstants.adminAnnouncements, {'action': 'delete', 'id': id});
  }

  // ---------- FAQs ----------
  Future<List<AdminFaq>> fetchFaqs() async {
    try {
      final response = await _apiClient.get(AppConstants.adminFaqs);
      final list = (response.data['data'] as List?) ?? [];
      return list.map((f) {
        final m = f as Map<String, dynamic>;
        return AdminFaq(
          id: (m['id'] as num).toInt(),
          category: m['category']?.toString() ?? '',
          question: m['question']?.toString() ?? '',
          answer: m['answer']?.toString() ?? '',
          sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
          isActive: m['is_active'] == true || m['is_active'] == 1,
        );
      }).toList();
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw Exception(data['message'].toString());
      }
      throw Exception('Could not load the FAQs. Please try again.');
    }
  }

  Future<void> saveFaq({
    int? id,
    required String category,
    required String question,
    required String answer,
    required int sortOrder,
    required bool isActive,
  }) {
    return _send(AppConstants.adminFaqs, {
      'action': id == null ? 'create' : 'update',
      if (id != null) 'id': id,
      'category': category,
      'question': question,
      'answer': answer,
      'sort_order': sortOrder,
      'is_active': isActive,
    });
  }

  Future<void> deleteFaq(int id) {
    return _send(AppConstants.adminFaqs, {'action': 'delete', 'id': id});
  }
}
