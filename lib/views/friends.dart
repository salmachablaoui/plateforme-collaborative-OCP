import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_stage/views/shared/adaptive_drawer.dart';
import 'package:app_stage/views/shared/custom_app_bar.dart';
import 'package:app_stage/views/profil.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AdaptiveDrawer(),
      appBar: CustomAppBar(
        title: 'Amis',
        scaffoldKey: _scaffoldKey,
        user: _user,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildMainTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsList(),
                _buildSuggestionsList(),
                _buildFriendRequestsTabView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          prefixIcon: const Icon(Iconsax.search_normal),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.withOpacity(0.1),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  )
                  : null,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildMainTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: Theme.of(context).primaryColor,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Theme.of(context).primaryColor,
      tabs: const [
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.people),
              SizedBox(width: 6),
              Text('Mes amis'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.user_search),
              SizedBox(width: 6),
              Text('Suggestions'),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.user_add),
              SizedBox(width: 6),
              Text('Demandes'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFriendsList() {
    return RefreshIndicator(
      onRefresh: _refreshFriendsList,
      child: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('users')
                .doc(_user?.uid)
                .collection('friends')
                .orderBy('addedAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final friends = snapshot.data?.docs ?? [];

          if (friends.isEmpty) {
            return _buildEmptyState(
              icon: Icons.group,
              title: 'Aucun ami pour le moment',
              subtitle: 'Ajoutez des amis via les suggestions',
            );
          }

          return ListView.separated(
            itemCount: friends.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final friendId = friends[index].id;
              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(friendId).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: CircleAvatar(child: CircularProgressIndicator()),
                      title: Text('Chargement...'),
                    );
                  }

                  if (!userSnapshot.hasData ||
                      userSnapshot.data?.data() == null) {
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.error)),
                      title: const Text('Utilisateur introuvable'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _removeFriend(context, friendId),
                      ),
                    );
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  return UserCard(
                    userId: friendId,
                    name: userData['fullName'] ?? 'Utilisateur inconnu',
                    department: userData['department'] ?? '',
                    photoUrl: userData['photoUrl'],
                    photoBase64: userData['photoBase64'],
                    isOnline: userData['isOnline'] ?? false,
                    showRemoveButton: true,
                    onTap: () => _navigateToUserProfile(friendId),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _searchQuery.isEmpty
              ? _firestore.collection('users').snapshots()
              : _firestore
                  .collection('users')
                  .where('fullName', isGreaterThanOrEqualTo: _searchQuery)
                  .where('fullName', isLessThan: '$_searchQuery\uf8ff')
                  .snapshots(),
      builder: (context, allUsersSnapshot) {
        if (allUsersSnapshot.hasError) {
          return _buildErrorWidget(allUsersSnapshot.error.toString());
        }

        if (allUsersSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<QuerySnapshot>(
          stream:
              _firestore
                  .collection('users')
                  .doc(_user?.uid)
                  .collection('friends')
                  .snapshots(),
          builder: (context, friendsSnapshot) {
            if (friendsSnapshot.hasError) {
              return _buildErrorWidget(friendsSnapshot.error.toString());
            }

            final allUsers = allUsersSnapshot.data?.docs ?? [];
            final friends = friendsSnapshot.data?.docs ?? [];

            final suggestions =
                allUsers.where((user) {
                  if (user.id == _user?.uid) return false;
                  final isFriend = friends.any(
                    (friend) => friend.id == user.id,
                  );
                  return !isFriend;
                }).toList();

            final filteredSuggestions =
                _searchQuery.isEmpty
                    ? suggestions
                    : suggestions.where((user) {
                      final userData = user.data() as Map<String, dynamic>;
                      final name =
                          userData['fullName']?.toString().toLowerCase() ?? '';
                      return name.contains(_searchQuery.toLowerCase());
                    }).toList();

            if (filteredSuggestions.isEmpty) {
              return _buildEmptyState(
                icon: Icons.search_off,
                title:
                    _searchQuery.isEmpty
                        ? 'Aucune suggestion disponible'
                        : 'Aucun résultat pour "$_searchQuery"',
              );
            }

            return ListView.builder(
              itemCount: filteredSuggestions.length,
              itemBuilder: (context, index) {
                final user = filteredSuggestions[index];
                final userData = user.data() as Map<String, dynamic>;
                return UserCard(
                  userId: user.id,
                  name: userData['fullName'] ?? 'Utilisateur inconnu',
                  department: userData['department'] ?? '',
                  photoUrl: userData['photoUrl'],
                  photoBase64: userData['photoBase64'],
                  isOnline: userData['isOnline'] ?? false,
                  showAddButton: true,
                  onTap: () => _navigateToUserProfile(user.id),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFriendRequestsTabView() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              tabs: const [Tab(text: 'Reçues'), Tab(text: 'Envoyées')],
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [_buildReceivedRequests(), _buildSentRequests()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('users')
              .doc(_user?.uid)
              .collection('received_requests')
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return _buildEmptyState(
            icon: Icons.mark_email_unread,
            title: 'Aucune demande reçue',
            subtitle: 'Les demandes que vous recevez apparaîtront ici',
          );
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(request.id).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const ListTile(title: Text('Chargement...'));
                }

                final userData =
                    userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                return UserCard(
                  userId: request.id,
                  name: userData['fullName'] ?? 'Utilisateur inconnu',
                  department: userData['department'] ?? '',
                  photoUrl: userData['photoUrl'],
                  photoBase64: userData['photoBase64'],
                  isOnline: userData['isOnline'] ?? false,
                  showAcceptRejectButtons: true,
                  onTap: () => _navigateToUserProfile(request.id),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSentRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('users')
              .doc(_user?.uid)
              .collection('sent_requests')
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return _buildEmptyState(
            icon: Icons.send,
            title: 'Aucune demande envoyée',
            subtitle: 'Les demandes que vous envoyez apparaîtront ici',
          );
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(request.id).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const ListTile(title: Text('Chargement...'));
                }

                final userData =
                    userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                return UserCard(
                  userId: request.id,
                  name: userData['fullName'] ?? 'Utilisateur inconnu',
                  department: userData['department'] ?? '',
                  photoUrl: userData['photoUrl'],
                  photoBase64: userData['photoBase64'],
                  isOnline: userData['isOnline'] ?? false,
                  showCancelButton: true,
                  onTap: () => _navigateToUserProfile(request.id),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(error, textAlign: TextAlign.center),
          TextButton(
            onPressed: () => setState(() {}),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  Future<void> _refreshFriendsList() async {
    setState(() {});
  }

  Future<void> _sendFriendRequest(
    BuildContext context,
    String recipientId,
  ) async {
    try {
      final friendDoc =
          await _firestore
              .collection('users')
              .doc(_user?.uid)
              .collection('friends')
              .doc(recipientId)
              .get();

      if (friendDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cet utilisateur est déjà votre ami')),
        );
        return;
      }

      final existingRequest =
          await _firestore
              .collection('users')
              .doc(_user?.uid)
              .collection('sent_requests')
              .doc(recipientId)
              .get();

      if (existingRequest.exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Demande déjà envoyée')));
        return;
      }

      await _firestore.runTransaction((transaction) async {
        transaction.set(
          _firestore
              .collection('users')
              .doc(_user?.uid)
              .collection('sent_requests')
              .doc(recipientId),
          {'timestamp': FieldValue.serverTimestamp()},
        );

        transaction.set(
          _firestore
              .collection('users')
              .doc(recipientId)
              .collection('received_requests')
              .doc(_user?.uid),
          {'timestamp': FieldValue.serverTimestamp()},
        );
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Demande d\'ami envoyée')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _removeFriend(BuildContext context, String friendId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        transaction.delete(
          _firestore
              .collection('users')
              .doc(_user?.uid)
              .collection('friends')
              .doc(friendId),
        );

        transaction.delete(
          _firestore
              .collection('users')
              .doc(friendId)
              .collection('friends')
              .doc(_user?.uid),
        );
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ami supprimé')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _acceptFriendRequest(
    BuildContext context,
    String senderId,
  ) async {
    final timestamp = FieldValue.serverTimestamp();
    try {
      await _firestore.runTransaction((transaction) async {
        transaction.delete(
          _firestore
              .collection('users')
              .doc(_user?.uid)
              .collection('received_requests')
              .doc(senderId),
        );

        transaction.delete(
          _firestore
              .collection('users')
              .doc(senderId)
              .collection('sent_requests')
              .doc(_user?.uid),
        );

        transaction.set(
          _firestore
              .collection('users')
              .doc(_user?.uid)
              .collection('friends')
              .doc(senderId),
          {'addedAt': timestamp},
        );

        transaction.set(
          _firestore
              .collection('users')
              .doc(senderId)
              .collection('friends')
              .doc(_user?.uid),
          {'addedAt': timestamp},
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande acceptée - Ami ajouté')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _rejectFriendRequest(
    BuildContext context,
    String senderId,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        transaction.delete(
          _firestore
              .collection('users')
              .doc(_user?.uid)
              .collection('received_requests')
              .doc(senderId),
        );

        transaction.delete(
          _firestore
              .collection('users')
              .doc(senderId)
              .collection('sent_requests')
              .doc(_user?.uid),
        );
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Demande rejetée')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _cancelFriendRequest(
    BuildContext context,
    String recipientId,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        transaction.delete(
          _firestore
              .collection('users')
              .doc(_user?.uid)
              .collection('sent_requests')
              .doc(recipientId),
        );

        transaction.delete(
          _firestore
              .collection('users')
              .doc(recipientId)
              .collection('received_requests')
              .doc(_user?.uid),
        );
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Demande annulée')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  void _navigateToUserProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen(userId: userId)),
    );
  }
}

class UserCard extends StatelessWidget {
  final String userId;
  final String name;
  final String department;
  final String? photoUrl;
  final String? photoBase64;
  final bool isOnline;
  final bool showAddButton;
  final bool showRemoveButton;
  final bool showAcceptRejectButtons;
  final bool showCancelButton;
  final VoidCallback? onTap;

  const UserCard({
    required this.userId,
    required this.name,
    required this.department,
    this.photoUrl,
    this.photoBase64,
    required this.isOnline,
    this.showAddButton = false,
    this.showRemoveButton = false,
    this.showAcceptRejectButtons = false,
    this.showCancelButton = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials =
        name.isNotEmpty
            ? name
                .split(' ')
                .map((e) => e.isNotEmpty ? e[0] : '')
                .take(2)
                .join()
            : '?';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  _buildUserAvatar(initials),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (department.isNotEmpty)
                      Text(
                        department,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              if (showAddButton ||
                  showRemoveButton ||
                  showAcceptRejectButtons ||
                  showCancelButton)
                _buildActionButtons(context) ?? const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(String initials) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: CachedNetworkImageProvider(photoUrl!),
        backgroundColor: Colors.grey.shade200,
      );
    } else if (photoBase64 != null && photoBase64!.isNotEmpty) {
      try {
        final base64String = photoBase64!.split(',').last;
        return CircleAvatar(
          radius: 24,
          backgroundImage: MemoryImage(base64Decode(base64String)),
          backgroundColor: Colors.grey.shade200,
        );
      } catch (e) {
        return _buildInitialsAvatar(initials);
      }
    } else {
      return _buildInitialsAvatar(initials);
    }
  }

  Widget _buildInitialsAvatar(String initials) {
    final color = Colors.primaries[name.length % Colors.primaries.length];
    return CircleAvatar(
      radius: 24,
      backgroundColor: color.withOpacity(0.2),
      child: Text(
        initials,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget? _buildActionButtons(BuildContext context) {
    if (showAddButton) {
      return IconButton(
        icon: const Icon(Iconsax.user_add, size: 22),
        color: Theme.of(context).primaryColor,
        onPressed: () => _sendFriendRequest(context),
      );
    }

    if (showRemoveButton) {
      return IconButton(
        icon: const Icon(Iconsax.user_minus, size: 22),
        color: Colors.red,
        onPressed: () => _removeFriend(context),
      );
    }

    if (showAcceptRejectButtons) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check, size: 22),
            color: Colors.green,
            onPressed: () => _acceptFriendRequest(context),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 22),
            color: Colors.red,
            onPressed: () => _rejectFriendRequest(context),
          ),
        ],
      );
    }

    if (showCancelButton) {
      return IconButton(
        icon: const Icon(Icons.close, size: 22),
        color: Colors.grey,
        onPressed: () => _cancelFriendRequest(context),
      );
    }

    return null;
  }

  void _sendFriendRequest(BuildContext context) {
    final state = context.findAncestorStateOfType<_FriendsScreenState>();
    state?._sendFriendRequest(context, userId);
  }

  void _removeFriend(BuildContext context) {
    final state = context.findAncestorStateOfType<_FriendsScreenState>();
    state?._removeFriend(context, userId);
  }

  void _acceptFriendRequest(BuildContext context) {
    final state = context.findAncestorStateOfType<_FriendsScreenState>();
    state?._acceptFriendRequest(context, userId);
  }

  void _rejectFriendRequest(BuildContext context) {
    final state = context.findAncestorStateOfType<_FriendsScreenState>();
    state?._rejectFriendRequest(context, userId);
  }

  void _cancelFriendRequest(BuildContext context) {
    final state = context.findAncestorStateOfType<_FriendsScreenState>();
    state?._cancelFriendRequest(context, userId);
  }
}
