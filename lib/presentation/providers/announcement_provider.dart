import 'package:flutter/material.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/repositories/portal_repository.dart';

class AnnouncementModel {
  final int id;
  final String title;
  final String content;
  final DateTime date;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
  });
}

/// Announcements come from the barangay's database (the same list the public
/// portal shows). Staff can post, edit and delete them from the app.
class AnnouncementProvider extends ChangeNotifier {
  final PortalRepository _portal;
  final ContentRepository _content;

  AnnouncementProvider(this._portal, this._content);

  List<AnnouncementModel> _announcements = [];
  bool _isLoading = false;
  String? _error;

  List<AnnouncementModel> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final items = await _portal.getAnnouncements(limit: 20);
      _announcements = items
          .map((a) => AnnouncementModel(
                id: a.id,
                title: a.title,
                content: a.body,
                date: DateTime.tryParse(a.createdAt) ?? DateTime.now(),
              ))
          .toList();
    } catch (_) {
      _error = 'Could not load announcements. Pull down to try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save({int? id, required String title, required String body}) async {
    await _content.saveAnnouncement(id: id, title: title, body: body);
    await load();
  }

  Future<void> delete(int id) async {
    await _content.deleteAnnouncement(id);
    await load();
  }
}
