import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'profil.dart';
import 'shared/custom_app_bar.dart';
import 'shared/adaptive_drawer.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final firebase_auth.User? _user =
      firebase_auth.FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago.FrMessages());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AdaptiveDrawer(),
      appBar: CustomAppBar(
        title: 'Notifications',
        scaffoldKey: _scaffoldKey,
        user: _user,
        showSearchButton: false,
      ),
      body:
          _user == null
              ? const Center(child: Text('Veuillez vous connecter'))
              : Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: _buildNotificationList(),
                  ),
                ),
              ),
    );
  }

  Widget _buildNotificationList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('notifications')
              .where('userId', isEqualTo: _user?.uid)
              .orderBy('createdAt', descending: true)
              .limit(100) // Limite pour éviter de charger trop de données
              .snapshots(),
      builder: (context, snapshot) {
        // Gestion des erreurs améliorée
        if (snapshot.hasError) {
          debugPrint('Erreur de notification: ${snapshot.error}');
          return _buildErrorWidget(
            snapshot.error?.toString() ?? 'Erreur inconnue',
            onRetry: () => setState(() {}),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final notifications = snapshot.data!.docs;

        return RefreshIndicator(
          onRefresh: _refreshNotifications,
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, index) {
              final notification =
                  notifications[index].data() as Map<String, dynamic>;
              final notificationId = notifications[index].id;
              return _NotificationCard(
                notification: notification,
                notificationId: notificationId,
                onTap:
                    () => _handleNotificationTap(notification, notificationId),
                onDismiss: () => _dismissNotification(notificationId),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _markAllAsRead() async {
    try {
      final query =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: _user?.uid)
              .where('read', isEqualTo: false)
              .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toutes les notifications marquées comme lues'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors du marquage comme lues: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() {});
  }

  Future<void> _handleNotificationTap(
    Map<String, dynamic> notification,
    String notificationId,
  ) async {
    try {
      if (!notification['read']) {
        await _firestore.collection('notifications').doc(notificationId).update(
          {'read': true, 'readAt': FieldValue.serverTimestamp()},
        );
      }

      if (!mounted) return;

      switch (notification['type']) {
        case 'friend_request':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ProfileScreen(userId: notification['senderId']),
            ),
          );
          break;
        case 'friend_request_accepted':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ProfileScreen(userId: notification['senderId']),
            ),
          );
          break;
        case 'new_message':
          Navigator.pushNamed(
            context,
            '/chatrooms',
            arguments: {'userId': notification['senderId']},
          );
          break;
        case 'post_comment':
          Navigator.pushNamed(
            context,
            '/post',
            arguments: {
              'postId': notification['data']['postId'],
              'focusComment': true,
            },
          );
          break;
        default:
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Action non prise en charge')),
            );
          }
      }
    } catch (e) {
      debugPrint('Erreur lors du traitement: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  Future<void> _dismissNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notification supprimée')));
      }
    } catch (e) {
      debugPrint('Erreur lors de la suppression: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  Widget _buildErrorWidget(String error, {VoidCallback? onRetry}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune notification',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Toutes vos notifications apparaîtront ici',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final String notificationId;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.notificationId,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !(notification['read'] ?? false);
    final theme = Theme.of(context);
    final createdAt = (notification['createdAt'] as Timestamp).toDate();
    final senderImage = notification['senderImage'] as String?;

    return Dismissible(
      key: Key(notificationId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Confirmer'),
                content: const Text(
                  'Voulez-vous vraiment supprimer cette notification ?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Supprimer'),
                  ),
                ],
              ),
        );
      },
      onDismissed: (_) => onDismiss(),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                          senderImage != null
                              ? NetworkImage(senderImage)
                              : null,
                      child:
                          senderImage == null
                              ? const Icon(
                                Icons.person,
                                size: 20,
                                color: Colors.grey,
                              )
                              : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification['title'] ?? 'Notification',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight:
                                  isUnread
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification['message'] ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      timeago.format(createdAt, locale: 'fr'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
