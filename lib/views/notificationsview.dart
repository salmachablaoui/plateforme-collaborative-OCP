import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
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
  int _unreadCount = 0;
  StreamSubscription<QuerySnapshot>? _unreadSubscription;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    _initUnreadCount();
  }

  @override
  void dispose() {
    _unreadSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initUnreadCount() async {
    // Charge le compteur initial
    await _loadUnreadCount();

    // Met en place l'écouteur pour les changements en temps réel
    if (_user?.uid != null) {
      _unreadSubscription = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _user?.uid)
          .where('read', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
            setState(() {
              _unreadCount = snapshot.size;
            });
          });
    }
  }

  Future<void> _loadUnreadCount() async {
    if (_user?.uid == null) return;

    final snapshot =
        await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: _user?.uid)
            .where('read', isEqualTo: false)
            .get();

    setState(() {
      _unreadCount = snapshot.size;
    });
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
        unreadNotificationsCount: _unreadCount,
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
              .limit(100)
              .snapshots(),
      builder: (context, snapshot) {
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

  Future<void> _handleNotificationTap(
    Map<String, dynamic> notification,
    String notificationId,
  ) async {
    if (!notification['read']) {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      // Pas besoin de setState ici car l'écouteur se chargera de la mise à jour
    }

    // Gestion de la navigation en fonction du type de notification
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
      // Ajoutez d'autres cas selon vos besoins
      default:
        // Action par défaut
        break;
    }
  }

  Future<void> _dismissNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
    // Pas besoin de setState ici car l'écouteur se chargera de la mise à jour
  }

  Future<void> _refreshNotifications() async {
    await _loadUnreadCount();
  }

  Widget _buildErrorWidget(String error, {required VoidCallback onRetry}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
    final senderImageBase64 = notification['senderImageBase64'] as String?;
    final senderName = notification['senderName'] as String? ?? 'Utilisateur';

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
                    _buildProfileImage(
                      senderImage,
                      senderImageBase64,
                      senderName,
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

  Widget _buildProfileImage(
    String? photoUrl,
    String? photoBase64,
    String name,
  ) {
    final initials =
        name.isNotEmpty
            ? name
                .split(' ')
                .map((e) => e.isNotEmpty ? e[0] : '')
                .take(2)
                .join()
            : '?';

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: CachedNetworkImageProvider(photoUrl),
        backgroundColor: Colors.grey.shade200,
      );
    } else if (photoBase64 != null && photoBase64.isNotEmpty) {
      try {
        final base64String = photoBase64.split(',').last;
        return CircleAvatar(
          radius: 20,
          backgroundImage: MemoryImage(base64Decode(base64String)),
          backgroundColor: Colors.grey.shade200,
        );
      } catch (e) {
        debugPrint('Erreur de décodage base64: $e');
        return _buildInitialsAvatar(initials);
      }
    } else {
      return _buildInitialsAvatar(initials);
    }
  }

  Widget _buildInitialsAvatar(String initials) {
    final color = Colors.primaries[initials.length % Colors.primaries.length];
    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withOpacity(0.2),
      child: Text(
        initials,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
