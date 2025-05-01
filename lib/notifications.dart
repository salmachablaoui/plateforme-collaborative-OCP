import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'adaptive_drawer.dart';
import 'custom_app_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final User? _user = FirebaseAuth.instance.currentUser;
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Alice Durand',
      'subtitle': 'a commenté votre publication',
      'time': '10 min',
      'read': false,
      'type': 'comment',
    },
    {
      'title': 'Système',
      'subtitle': 'Mise à jour disponible - Version 2.1.0',
      'time': '1 h',
      'read': true,
      'type': 'system',
    },
    {
      'title': 'Jean Martin',
      'subtitle': 'vous a envoyé un message privé',
      'time': '3 h',
      'read': false,
      'type': 'message',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AdaptiveDrawer(),
      appBar: CustomAppBar(
        title: 'Notifications',
        scaffoldKey: _scaffoldKey,
        user: _user,
        showSearchButton: false, // Désactivé pour l'écran de notifications
      ),
      body: _buildNotificationList(),
    );
  }

  Widget _buildNotificationList() {
    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder:
            (ctx, index) => _NotificationCard(
              notification: _notifications[index],
              onTap: () => _openNotificationDetails(_notifications[index]),
            ),
      ),
    );
  }

  Future<void> _refreshNotifications() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {});
  }

  void _openNotificationDetails(Map<String, dynamic> notification) {
    Navigator.pushNamed(
      _scaffoldKey.currentContext!,
      '/notification-detail',
      arguments: notification,
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification['read'];
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône à la place de l'avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AdaptiveDrawer.primaryColor.withOpacity(0.1),
                ),
                child: Icon(
                  _getIconForType(notification['type']),
                  color: AdaptiveDrawer.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification['title'],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['subtitle'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              _buildTimeIndicator(isUnread),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeIndicator(bool isUnread) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          notification['time'],
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        if (isUnread)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'comment':
        return Iconsax.message_text;
      case 'message':
        return Iconsax.message;
      case 'system':
        return Iconsax.info_circle;
      default:
        return Iconsax.notification;
    }
  }
}
