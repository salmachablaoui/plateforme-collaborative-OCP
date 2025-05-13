import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:app_stage/views/shared/adaptive_drawer.dart';
import 'package:app_stage/views/shared/custom_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:app_stage/views/chat/chatroom_page.dart';

class ChatroomsScreen extends StatefulWidget {
  const ChatroomsScreen({Key? key}) : super(key: key);

  @override
  State<ChatroomsScreen> createState() => _UltimateChatroomsScreenState();
}

class _UltimateChatroomsScreenState extends State<ChatroomsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AdaptiveDrawer(),
      appBar: CustomAppBar(
        title: 'Chatrooms',
        scaffoldKey: _scaffoldKey,
        user: _user,
        showSearchButton: true,
        showNotifications: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher des chatrooms...',
                prefixIcon: const Icon(Iconsax.search_normal),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
              ),
              onChanged:
                  (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('chatrooms')
                      .where('participants', arrayContains: _user?.uid)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                final chatrooms =
                    snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['name'].toString().toLowerCase().contains(
                        _searchQuery,
                      );
                    }).toList();

                if (chatrooms.isEmpty) {
                  return _buildEmptyState();
                }

                // Correction de l'erreur de type - conversion explicite en List<Widget>
                final pinnedChatrooms =
                    chatrooms.where((doc) => doc['isPinned'] == true).toList();
                final recentChatrooms =
                    chatrooms.where((doc) => doc['isPinned'] != true).toList();

                return ListView(
                  children: [
                    if (pinnedChatrooms.isNotEmpty) ...[
                      _buildSectionHeader('ÉPINGLÉS', Iconsax.location_add),
                      ...pinnedChatrooms
                          .map((doc) => _buildChatroomItem(doc))
                          .toList(),
                    ],
                    _buildSectionHeader('RÉCENTS', Iconsax.clock),
                    ...recentChatrooms
                        .map((doc) => _buildChatroomItem(doc))
                        .toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateChatroomDialog(context),
        backgroundColor: Colors.green,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatroomItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final unreadCount = data['unreadCounts']?[_user?.uid] ?? 0;
    final lastMessage = data['lastMessage'] ?? '';
    final lastMessageSenderId = data['lastMessageSender'];

    return FutureBuilder(
      future: _getLastMessageSenderName(lastMessageSenderId),
      builder: (context, senderSnapshot) {
        final senderName = senderSnapshot.data ?? 'Utilisateur';

        return FutureBuilder(
          future: _getParticipantsInfo(data['participants']),
          builder: (context, participantsSnapshot) {
            final participants = participantsSnapshot.data ?? [];

            return ListTile(
              leading: _buildParticipantsAvatar(participants),
              title: Text(
                data['name'] ?? 'Chatroom sans nom',
                style: TextStyle(
                  fontWeight:
                      unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                lastMessage.isNotEmpty
                    ? '$senderName: $lastMessage'
                    : 'Aucun message',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight:
                      unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                  color: unreadCount > 0 ? Colors.black : Colors.grey,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTimestamp(data['lastMessageTime']),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight:
                          unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (unreadCount > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatroomPage(chatroomId: doc.id),
                  ),
                );
              },
              onLongPress: () => _showChatroomOptions(doc),
            );
          },
        );
      },
    );
  }

  Widget _buildParticipantsAvatar(List<Map<String, dynamic>> participants) {
    if (participants.isEmpty) {
      return const CircleAvatar(child: Icon(Iconsax.profile));
    }

    if (participants.length == 1) {
      return CircleAvatar(
        backgroundImage:
            participants[0]['photoUrl'] != null
                ? CachedNetworkImageProvider(participants[0]['photoUrl'])
                : null,
        child:
            participants[0]['photoUrl'] == null
                ? Text(participants[0]['initials'])
                : null,
      );
    }

    return Stack(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundImage:
              participants[0]['photoUrl'] != null
                  ? CachedNetworkImageProvider(participants[0]['photoUrl'])
                  : null,
          child:
              participants[0]['photoUrl'] == null
                  ? Text(participants[0]['initials'])
                  : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: CircleAvatar(
            radius: 16,
            backgroundImage:
                participants.length > 1 && participants[1]['photoUrl'] != null
                    ? CachedNetworkImageProvider(participants[1]['photoUrl'])
                    : null,
            child:
                participants.length > 1 && participants[1]['photoUrl'] == null
                    ? Text(participants[1]['initials'])
                    : null,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.message_remove, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Aucune chatroom trouvée',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Commencez par créer une nouvelle chatroom'
                : 'Aucun résultat pour "${_searchQuery}"',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          if (_searchQuery.isEmpty)
            ElevatedButton(
              onPressed: () => _showCreateChatroomDialog(context),
              child: const Text('Créer une chatroom'),
            ),
        ],
      ),
    );
  }

  Future<String> _getLastMessageSenderName(String? userId) async {
    if (userId == null) return 'Utilisateur';
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc['fullName'] ?? 'Utilisateur';
  }

  Future<List<Map<String, dynamic>>> _getParticipantsInfo(
    List<dynamic> participantIds,
  ) async {
    final friends =
        await _firestore
            .collection('users')
            .where('uid', whereIn: participantIds.whereType<String>().toList())
            .get();

    return friends.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'fullName': data['fullName'] ?? 'Utilisateur',
        'photoUrl': data['photoUrl'],
        'initials': _getInitials(data['fullName'] ?? 'UU'),
      };
    }).toList();
  }

  String _getInitials(String fullName) {
    return fullName
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join('')
        .toUpperCase();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is! Timestamp) return timestamp.toString();

    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.isAfter(today)) {
      return DateFormat.Hm().format(date);
    } else if (date.isAfter(yesterday)) {
      return 'Hier';
    } else {
      return DateFormat('dd/MM').format(date);
    }
  }

  void _openChatroom(String chatroomId) {
    // Réinitialiser le compteur de messages non lus
    _firestore.collection('chatrooms').doc(chatroomId).update({
      'unreadCounts.${_user?.uid}': 0,
    });

    Navigator.pushNamed(context, '/chatroom', arguments: chatroomId);
  }

  void _showChatroomOptions(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isPinned = data['isPinned'] ?? false;

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(isPinned ? Iconsax.coin : Iconsax.coin_1),
                title: Text(isPinned ? 'Désépingler' : 'Épingler'),
                onTap: () {
                  Navigator.pop(context);
                  _togglePinChatroom(doc.id, !isPinned);
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.profile_delete),
                title: const Text('Quitter la chatroom'),
                onTap: () {
                  Navigator.pop(context);
                  _leaveChatroom(doc.id);
                },
              ),
            ],
          ),
    );
  }

  void _togglePinChatroom(String chatroomId, bool pin) {
    _firestore.collection('chatrooms').doc(chatroomId).update({
      'isPinned': pin,
    });
  }

  void _leaveChatroom(String chatroomId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Quitter la chatroom'),
            content: const Text(
              'Voulez-vous vraiment quitter cette chatroom ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _firestore.collection('chatrooms').doc(chatroomId).update({
                    'participants': FieldValue.arrayRemove([_user?.uid]),
                  });
                },
                child: const Text(
                  'Quitter',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showCreateChatroomDialog(BuildContext context) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    List<Map<String, dynamic>> friends = [];
    List<String> selectedFriends = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nouvelle chatroom'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom de la chatroom',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un nom';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Sélectionnez des participants:'),
                      const SizedBox(height: 8),
                      FutureBuilder(
                        future: _getFriendsList(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Text('Erreur: ${snapshot.error}');
                          }

                          friends = snapshot.data as List<Map<String, dynamic>>;

                          return Column(
                            children: [
                              ...friends
                                  .map(
                                    (friend) => CheckboxListTile(
                                      value: selectedFriends.contains(
                                        friend['id'],
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          if (value == true) {
                                            selectedFriends.add(friend['id']);
                                          } else {
                                            selectedFriends.remove(
                                              friend['id'],
                                            );
                                          }
                                        });
                                      },
                                      title: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundImage:
                                                friend['photoUrl'] != null
                                                    ? CachedNetworkImageProvider(
                                                      friend['photoUrl'],
                                                    )
                                                    : null,
                                            child:
                                                friend['photoUrl'] == null
                                                    ? Text(
                                                      _getInitials(
                                                        friend['fullName'],
                                                      ),
                                                    )
                                                    : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(friend['fullName']),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate() &&
                        selectedFriends.isNotEmpty) {
                      try {
                        final participants = [...selectedFriends, _user?.uid];

                        await _firestore.collection('chatrooms').add({
                          'name': nameController.text.trim(),
                          'createdAt': FieldValue.serverTimestamp(),
                          'createdBy': _user?.uid,
                          'isPinned': false,
                          'lastMessage': '',
                          'lastMessageSender': null,
                          'lastMessageTime': null,
                          'participants': participants,
                          'unreadCounts': {
                            for (var uid in participants) uid: 0,
                          },
                        });

                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                      }
                    } else if (selectedFriends.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Veuillez sélectionner au moins un participant',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Créer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getFriendsList() async {
    // Implémentez la récupération de la liste d'amis depuis Firestore
    // Par exemple, à partir de la sous-collection 'friends' de l'utilisateur
    final friendsDoc =
        await _firestore
            .collection('users')
            .doc(_user?.uid)
            .collection('friends')
            .get();

    final friendsIds = friendsDoc.docs.map((doc) => doc.id).toList();

    if (friendsIds.isEmpty) return [];

    final friendsData =
        await _firestore
            .collection('users')
            .where('uid', whereIn: friendsIds)
            .get();

    return friendsData.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'fullName': data['fullName'] ?? 'Utilisateur',
        'photoUrl': data['photoUrl'],
      };
    }).toList();
  }
}
