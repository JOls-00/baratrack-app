import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/notification_provider.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationProvider = context.watch<NotificationProvider>();
    final notifications = notificationProvider.notifications;
    final isFil = context.watch<LocaleProvider>().isFilipino;
    final isResident = context.watch<AuthProvider>().user?.role == 'Resident';

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(isFil ? 'Mga Abiso' : 'Notifications', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: notificationProvider.unreadCount == 0 ? null : () => notificationProvider.markAllAsRead(),
                    child: Text(isFil ? 'Markahan lahat' : 'Mark all as read'),
                  ),
                  TextButton(
                    onPressed: notifications.isEmpty ? null : () => notificationProvider.clearAll(),
                    child: Text(isFil ? 'Burahin lahat' : 'Clear all'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notificationProvider.load(),
              child: notifications.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        Center(child: Text(isFil ? 'Wala pang bagong abiso.' : 'No notifications yet.')),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final n = notifications[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: n.isRead ? theme.cardColor : theme.colorScheme.primary.withValues(alpha: 0.05),
                          elevation: n.isRead ? 0 : 2,
                          child: ListTile(
                            onTap: () {
                              notificationProvider.markAsRead(n.id);
                              final text = '${n.title} ${n.message}'.toLowerCase();
                              if (text.contains('hearing')) {
                                context.go(isResident ? '/my-hearings' : '/hearings-mgmt');
                              } else if (text.contains('complaint') || text.contains('reklamo') || text.contains('case')) {
                                context.go(isResident ? '/my-complaints' : '/cases');
                              }
                            },
                            trailing: IconButton(
                              tooltip: isFil ? 'Alisin' : 'Remove',
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => notificationProvider.remove(n.id),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            leading: CircleAvatar(
                              backgroundColor: n.color.withValues(alpha: 0.1),
                              child: Icon(n.icon, color: n.color, size: 20),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    n.title,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold),
                                  ),
                                ),
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
          ),
        ],
      ),
    );
  }
}
