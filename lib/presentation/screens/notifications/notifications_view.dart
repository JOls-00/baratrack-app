import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/notification_provider.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationProvider = context.watch<NotificationProvider>();
    final notifications = notificationProvider.notifications;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Notifications', style: theme.textTheme.headlineLarge),
              Row(
                children: [
                  TextButton(
                    onPressed: notificationProvider.unreadCount == 0 ? null : () => notificationProvider.markAllAsRead(),
                    child: const Text('Mark all as read'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: notifications.isEmpty ? null : () => notificationProvider.clearAll(),
                    child: const Text('Clear all'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: notifications.isEmpty
                ? const Center(child: Text('No notifications yet.'))
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: n.isRead ? theme.cardColor : theme.colorScheme.primary.withValues(alpha: 0.05),
                        elevation: n.isRead ? 0 : 2,
                        child: ListTile(
                          onTap: () => notificationProvider.markAsRead(n.id),
                          trailing: IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => notificationProvider.remove(n.id),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          leading: CircleAvatar(
                            backgroundColor: n.color.withValues(alpha: 0.1),
                            child: Icon(n.icon, color: n.color, size: 20),
                          ),
                          title: Row(
                            children: [
                              Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                              if (!n.isRead) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(n.message),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat('MMM dd, hh:mm a').format(n.timestamp),
                                style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
