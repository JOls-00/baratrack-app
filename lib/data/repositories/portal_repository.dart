import 'package:dio/dio.dart';
import '../../config/app_constants.dart';
import '../../core/network/api_client.dart';

class FaqItem {
  final int id;
  final String question;
  final String answer;
  const FaqItem({required this.id, required this.question, required this.answer});
}

class FaqCategory {
  final String name;
  final List<FaqItem> items;
  const FaqCategory({required this.name, required this.items});
}

class PortalAnnouncement {
  final int id;
  final String title;
  final String body;
  final String createdAt;
  const PortalAnnouncement({required this.id, required this.title, required this.body, this.createdAt = ''});
}

class TrackStep {
  final String label;
  final String detail;
  final String state; // done | current | todo
  const TrackStep({required this.label, required this.detail, required this.state});
}

class TrackResult {
  final String reference;
  final String title;
  final String headline;
  final List<TrackStep> steps;
  const TrackResult({
    required this.reference,
    required this.title,
    required this.headline,
    required this.steps,
  });
}

/// Talks to the PUBLIC (no-login) endpoints under /public/.
class PortalRepository {
  final ApiClient _apiClient;
  PortalRepository(this._apiClient);

  Future<List<FaqCategory>> getFaqs() async {
    final response = await _apiClient.get(AppConstants.publicFaqs);
    final list = (response.data['data'] as List?) ?? [];
    return list.map((c) {
      final m = c as Map<String, dynamic>;
      final items = ((m['items'] as List?) ?? []).map((i) {
        final im = i as Map<String, dynamic>;
        return FaqItem(
          id: (im['id'] as num).toInt(),
          question: im['question'].toString(),
          answer: im['answer'].toString(),
        );
      }).toList();
      return FaqCategory(name: m['category'].toString(), items: items);
    }).toList();
  }

  Future<List<PortalAnnouncement>> getAnnouncements({int limit = 10}) async {
    final response = await _apiClient.get(
      AppConstants.publicAnnouncements,
      queryParameters: {'limit': limit},
    );
    final list = (response.data['data'] as List?) ?? [];
    return list.map((a) {
      final m = a as Map<String, dynamic>;
      return PortalAnnouncement(
        id: (m['id'] as num).toInt(),
        title: m['title']?.toString() ?? '',
        body: m['body']?.toString() ?? '',
        createdAt: m['created_at']?.toString() ?? '',
      );
    }).toList();
  }

  Future<TrackResult> track(String reference, String lastName) async {
    try {
      final response = await _apiClient.post(AppConstants.publicTrack, data: {
        'reference': reference,
        'last_name': lastName,
      });
      final d = response.data['data'] as Map<String, dynamic>;
      final steps = ((d['steps'] as List?) ?? []).map((s) {
        final sm = s as Map<String, dynamic>;
        return TrackStep(
          label: sm['label']?.toString() ?? '',
          detail: sm['detail']?.toString() ?? '',
          state: sm['state']?.toString() ?? 'todo',
        );
      }).toList();
      return TrackResult(
        reference: d['reference']?.toString() ?? reference,
        title: d['title']?.toString() ?? 'Complaint',
        headline: d['headline']?.toString() ?? '',
        steps: steps,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        throw Exception(data['message'].toString());
      }
      throw Exception('Could not reach the server. Please try again.');
    }
  }

  /// Returns the AI's reply, or null when the AI is unavailable (caller falls back to FAQ matching).
  Future<String?> chat(List<Map<String, String>> messages) async {
    try {
      final response = await _apiClient.post(AppConstants.publicChat, data: {'messages': messages});
      final reply = response.data['reply'];
      return (reply is String && reply.trim().isNotEmpty) ? reply.trim() : null;
    } on DioException {
      return null;
    }
  }
}
