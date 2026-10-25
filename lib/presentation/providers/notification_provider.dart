import 'package:flutter/material.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

export '../../data/models/notification_model.dart';

/// The logged-in user's notifications, kept in sync with the server.
/// Changes show immediately; if the server call fails the list is reloaded.
class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;
  NotificationProvider(this._repository);

  List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> load() async {
    try {
      _notifications = await _repository.fetch();
      notifyListeners();
    } catch (_) {
      // Keep whatever is already shown if the server can't be reached.
    }
  }

  Future<void> markAsRead(int id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1 || _notifications[index].isRead) return;
    _notifications[index].isRead = true;
    notifyListeners();
    try {
      await _repository.markRead(id);
    } catch (_) {
      await load();
    }
  }

  Future<void> markAllAsRead() async {
    if (unreadCount == 0) return;
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
    try {
      await _repository.markAllRead();
    } catch (_) {
      await load();
    }
  }

  Future<void> remove(int id) async {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    try {
      await _repository.delete(id);
    } catch (_) {
      await load();
    }
  }

  Future<void> clearAll() async {
    if (_notifications.isEmpty) return;
    _notifications = [];
    notifyListeners();
    try {
      await _repository.clearAll();
    } catch (_) {
      await load();
    }
  }

  /// Called on logout so the next person to sign in never sees this list.
  void reset() {
    _notifications = [];
    notifyListeners();
  }
}
