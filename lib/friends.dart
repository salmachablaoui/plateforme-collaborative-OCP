import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'adaptive_drawer.dart';
import 'custom_app_bar.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final User? _user = FirebaseAuth.instance.currentUser;
  String _searchQuery = '';

  final List<Friend> _friends = [
    Friend(
      name: 'Alice Durand',
      status: 'En ligne',
      avatar: 'A',
      isOnline: true,
    ),
    Friend(name: 'Benoît Lefèvre', status: 'Hier, 18:30', avatar: 'B'),
    Friend(
      name: 'Claire Morel',
      status: 'En ligne',
      avatar: 'C',
      isOnline: true,
    ),
    Friend(name: 'David Petit', status: 'Il y a 2 jours', avatar: 'D'),
    Friend(
      name: 'Émilie Bernard',
      status: 'En ligne',
      avatar: 'E',
      isOnline: true,
    ),
    Friend(name: 'François Dubois', status: 'La semaine dernière', avatar: 'F'),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredFriends =
        _friends
            .where(
              (friend) => friend.name.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
            )
            .toList();

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AdaptiveDrawer(),
      appBar: CustomAppBar(
        title: 'Amis',
        scaffoldKey: _scaffoldKey,
        user: _user,
      ), // <-- Parenthèse fermée ici
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher des amis...',
                prefixIcon: const Icon(Iconsax.search_normal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredFriends.length,
              itemBuilder:
                  (context, index) => _FriendCard(
                    friend: filteredFriends[index],
                    onTap:
                        () => _navigateToFriendProfile(
                          context,
                          filteredFriends[index],
                        ),
                  ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFriendDialog(context),
        backgroundColor: AdaptiveDrawer.primaryColor,
        child: const Icon(Iconsax.user_add, color: Colors.white),
      ),
    );
  }

  void _navigateToFriendProfile(BuildContext context, Friend friend) {
    Navigator.pushNamed(context, '/friend-profile', arguments: friend);
  }

  void _showAddFriendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Ajouter un ami'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Email ou pseudo',
                    prefixIcon: const Icon(Iconsax.user),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Demande d\'ami envoyée')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdaptiveDrawer.primaryColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Envoyer la demande'),
                ),
              ],
            ),
          ),
    );
  }
}

class Friend {
  final String name;
  final String status;
  final String avatar;
  final bool isOnline;

  Friend({
    required this.name,
    required this.status,
    required this.avatar,
    this.isOnline = false,
  });
}

class _FriendCard extends StatelessWidget {
  final Friend friend;
  final VoidCallback onTap;

  const _FriendCard({required this.friend, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        Colors.primaries[friend.name.length % Colors.primaries.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: color.withOpacity(0.2),
                    child: Text(
                      friend.avatar,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  if (friend.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      friend.status,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  friend.isOnline ? Iconsax.message : Iconsax.message_question,
                  color: AdaptiveDrawer.primaryColor,
                ),
                onPressed: () => _startChat(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startChat(BuildContext context) {
    Navigator.pushNamed(context, '/chat', arguments: friend);
  }
}
