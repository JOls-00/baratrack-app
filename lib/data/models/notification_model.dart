import 'package:flutter/material.dart';

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] as num).toInt(),
      title: json['title']?.toString() ?? '',
      message: json['body']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      isRead: json['is_read'] == true || json['is_read'] == 1,
    );
  }

  // Icon, colour and destination are picked from the title, so no extra
  // database column is needed.
  String get _t => title.toLowerCase();

  IconData get icon {
    if (_t.contains('hearing')) return Icons.gavel;
    if (_t.contains('status')) return Icons.verified;
    if (_t.contains('complaint')) return Icons.assignment;
    if (_t.contains('announcement')) return Icons.campaign;
    if (_t.contains('document')) return Icons.file_present;
    return Icons.notifications;
  }

  Color get color {
    if (_t.contains('hearing')) return Colors.blue;
    if (_t.contains('status')) return Colors.green;
    if (_t.contains('complaint')) return Colors.deepOrange;
    if (_t.contains('announcement')) return Colors.purple;
    if (_t.contains('document')) return Colors.orange;
    return Colors.blueGrey;
  }

  /// Where tapping this notification should take the user.
  String routeFor({required bool isStaff}) {
    if (_t.contains('hearing')) return isStaff ? '/hearings-mgmt' : '/my-hearings';
    if (_t.contains('status') || _t.contains('complaint')) {
      return isStaff ? '/complaints-inbox' : '/my-complaints';
    }
    if (_t.contains('announcement')) return '/app-announcements';
    if (_t.contains('document')) return '/my-documents';
    return '/notifications';
  }
}
