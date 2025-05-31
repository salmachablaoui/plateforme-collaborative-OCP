import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'chatroom_page.dart';
import 'package:app_stage/views/shared/custom_app_bar.dart';
import 'package:app_stage/views/shared/adaptive_drawer.dart';
import 'package:app_stage/views/shared/adaptive_scaffold.dart';

class ChatroomsScreen extends StatefulWidget {
  const ChatroomsScreen({Key? key}) : super(key: key);

  @override
  State<ChatroomsScreen> createState() => _ChatroomsScreenState();
}

class _ChatroomsScreenState extends State<ChatroomsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedChatroomId;
  int _currentFilterIndex = 0;
  bool _showFriendsList = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (MediaQuery.of(context).size.width > 600) {
        _selectFirstChatroom();
      }
    });
  }

  void _selectFirstChatroom() async {
    final snapshot =
        await _firestore
            .collection('chatrooms')
            .where('participants', arrayContains: _user?.uid)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _selectedChatroomId = snapshot.docs.first.id;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

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
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Container(
          width: 350,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: const Icon(Iconsax.search_normal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.1),
                  ),
                  onChanged:
                      (value) =>
                          setState(() => _searchQuery = value.toLowerCase()),
                ),
              ),
              _buildFilterTabs(),
              Expanded(
                child:
                    _showFriendsList
                        ? _buildFriendsList()
                        : _buildChatroomList(),
              ),
              _buildActionButtons(),
            ],
          ),
        ),
        Expanded(
          child:
              _selectedChatroomId != null
                  ? ChatroomPage(
                    chatroomId: _selectedChatroomId!,
                    onDelete: _handleChatroomDeletion,
                  )
                  : _buildEmptyConversationView(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher...',
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
        _buildFilterTabs(),
        Expanded(
          child: _showFriendsList ? _buildFriendsList() : _buildChatroomList(),
        ),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildEmptyConversationView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.message, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Sélectionnez une conversation',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    const filters = ['Tous', 'Favoris', 'Groupes', 'Non lus'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ChoiceChip(
              label: Text(filters[index]),
              selected: _currentFilterIndex == index,
              onSelected: (selected) {
                setState(() {
                  _currentFilterIndex = selected ? index : 0;
                  _showFriendsList = false;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Iconsax.message_add, size: 20),
              label: const Text('Discussion'),
              onPressed: () => setState(() => _showFriendsList = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Iconsax.add, size: 20),
              label: const Text('Groupe'),
              onPressed: _showCreateChatroomDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getFriendsList(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final friends = snapshot.data!;

        return friends.isEmpty
            ? const Center(child: Text('Aucun ami disponible'))
            : ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        friend['photoUrl'] != null
                            ? CachedNetworkImageProvider(friend['photoUrl'])
                            : null,
                    child:
                        friend['photoUrl'] == null
                            ? Text(_getInitials(friend['fullName']))
                            : null,
                  ),
                  title: Text(friend['fullName']),
                  trailing: IconButton(
                    icon: const Icon(Iconsax.message),
                    onPressed: () => _createPrivateChat(friend['id']),
                  ),
                  onTap: () => _createPrivateChat(friend['id']),
                );
              },
            );
      },
    );
  }

  Widget _buildChatroomList() {
    return StreamBuilder<QuerySnapshot>(
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

        final filteredChatrooms = _filterChatrooms(snapshot.data!.docs);

        return filteredChatrooms.isEmpty
            ? _buildEmptyState()
            : _buildChatroomListView(filteredChatrooms);
      },
    );
  }

  List<DocumentSnapshot> _filterChatrooms(List<DocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      if (!data['name'].toString().toLowerCase().contains(_searchQuery)) {
        return false;
      }

      switch (_currentFilterIndex) {
        case 1:
          return data['isPinned'] == true;
        case 2:
          return (data['participants'] as List).length > 2;
        case 3:
          return (data['unreadCounts']?[_user?.uid] ?? 0) > 0;
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildChatroomListView(List<DocumentSnapshot> chatrooms) {
    final pinnedChatrooms =
        chatrooms.where((doc) => doc['isPinned'] == true).toList();
    final recentChatrooms =
        chatrooms.where((doc) => doc['isPinned'] != true).toList();

    return ListView(
      children: [
        if (pinnedChatrooms.isNotEmpty) ...[
          _buildSectionHeader('ÉPINGLÉS', Iconsax.location_add),
          ...pinnedChatrooms.map((doc) => _buildChatroomItem(doc)),
        ],
        _buildSectionHeader('RÉCENTS', Iconsax.clock),
        ...recentChatrooms.map((doc) => _buildChatroomItem(doc)),
      ],
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
    final isGroup = (data['participants'] as List).length > 2;

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
                  color: unreadCount > 0 ? Colors.black : Colors.grey[800],
                ),
              ),
              subtitle: Text(
                lastMessage.isNotEmpty
                    ? isGroup
                        ? '$senderName: $lastMessage'
                        : lastMessage
                    : 'Aucun message',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight:
                      unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                  color: unreadCount > 0 ? Colors.black : Colors.grey,
                ),
              ),
              trailing: _buildChatroomTrailing(
                unreadCount,
                data['lastMessageTime'],
              ),
              onTap: () => _openChatroom(doc),
              onLongPress: () => _showChatroomOptions(doc),
            );
          },
        );
      },
    );
  }

  Widget _buildChatroomTrailing(int unreadCount, dynamic timestamp) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _formatTimestamp(timestamp),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        if (unreadCount > 0)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red[600],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              unreadCount > 9 ? '9+' : unreadCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
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
              onPressed: _showCreateChatroomDialog,
              child: const Text('Créer une chatroom'),
            ),
        ],
      ),
    );
  }

  Future<void> _openChatroom(DocumentSnapshot doc) async {
    await _firestore.collection('chatrooms').doc(doc.id).update({
      'unreadCounts.${_user?.uid}': 0,
    });

    if (MediaQuery.of(context).size.width > 600) {
      setState(() => _selectedChatroomId = doc.id);
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ChatroomPage(
                chatroomId: doc.id,
                onDelete: _handleChatroomDeletion,
              ),
        ),
      );
      if (mounted) setState(() {});
    }
  }

  void _handleChatroomDeletion() {
    setState(() => _selectedChatroomId = null);
  }

  void _showChatroomOptions(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isPinned = data['isPinned'] ?? false;
    final isCreator = data['createdBy'] == _user?.uid;
    final isGroup = (data['participants'] as List).length > 2;

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  isPinned ? Iconsax.location_slash : Iconsax.location,
                ),
                title: Text(isPinned ? 'Désépingler' : 'Épingler'),
                onTap: () {
                  Navigator.pop(context);
                  _togglePinChatroom(doc.id, !isPinned);
                },
              ),
              if (isCreator) ...[
                ListTile(
                  leading: const Icon(Iconsax.edit),
                  title: const Text('Modifier le nom'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditChatroomNameDialog(doc);
                  },
                ),
                ListTile(
                  leading: const Icon(Iconsax.trash),
                  title: const Text('Supprimer la chatroom'),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteChatroom(doc.id);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Iconsax.profile_delete),
                title: Text(
                  isGroup ? 'Quitter le groupe' : 'Supprimer la discussion',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _leaveChatroom(doc.id, isCreator: isCreator);
                },
              ),
            ],
          ),
    );
  }

  Future<void> _deleteChatroom(String chatroomId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer la chatroom'),
            content: const Text(
              'Voulez-vous vraiment supprimer définitivement cette chatroom ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _firestore.collection('chatrooms').doc(chatroomId).delete();

      // Delete all associated messages
      final messages =
          await _firestore
              .collection('chatrooms')
              .doc(chatroomId)
              .collection('messages')
              .get();

      for (var doc in messages.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        setState(() {
          if (_selectedChatroomId == chatroomId) {
            _selectedChatroomId = null;
          }
        });
      }
    }
  }

  Future<void> _leaveChatroom(
    String chatroomId, {
    required bool isCreator,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              isCreator ? 'Supprimer la chatroom' : 'Quitter la chatroom',
            ),
            content: Text(
              isCreator
                  ? 'Vous êtes le créateur. Voulez-vous vraiment supprimer cette chatroom ?'
                  : 'Voulez-vous vraiment quitter cette chatroom ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  isCreator ? 'Supprimer' : 'Quitter',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      if (isCreator) {
        await _deleteChatroom(chatroomId);
      } else {
        await _firestore.collection('chatrooms').doc(chatroomId).update({
          'participants': FieldValue.arrayRemove([_user?.uid]),
        });
      }

      if (mounted) {
        setState(() {
          if (_selectedChatroomId == chatroomId) {
            _selectedChatroomId = null;
          }
        });
      }
    }
  }

  Future<void> _createPrivateChat(String friendId) async {
    try {
      // Check if chatroom already exists
      final existingChats =
          await _firestore
              .collection('chatrooms')
              .where('participants', arrayContains: _user?.uid)
              .get();

      for (var doc in existingChats.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants']);
        if (participants.length == 2 && participants.contains(friendId)) {
          _openExistingChatroom(doc);
          return;
        }
      }

      // Create new private chat
      final participants = [_user?.uid, friendId];
      final friendDoc =
          await _firestore.collection('users').doc(friendId).get();
      final friendName = friendDoc['fullName'] ?? 'Utilisateur';

      final newChat = await _firestore.collection('chatrooms').add({
        'name': 'Chat avec $friendName',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _user?.uid,
        'isPinned': false,
        'lastMessage': '',
        'lastMessageSender': null,
        'lastMessageTime': null,
        'participants': participants,
        'isGroup': false,
        'unreadCounts': {for (var uid in participants) uid: 0},
      });

      _openNewChatroom(newChat.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _openExistingChatroom(DocumentSnapshot doc) {
    if (MediaQuery.of(context).size.width > 600) {
      setState(() {
        _selectedChatroomId = doc.id;
        _showFriendsList = false;
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ChatroomPage(
                chatroomId: doc.id,
                onDelete: _handleChatroomDeletion,
              ),
        ),
      );
    }
  }

  void _openNewChatroom(String chatroomId) {
    if (MediaQuery.of(context).size.width > 600) {
      setState(() {
        _selectedChatroomId = chatroomId;
        _showFriendsList = false;
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ChatroomPage(
                chatroomId: chatroomId,
                onDelete: _handleChatroomDeletion,
              ),
        ),
      );
    }
  }

  void _showCreateChatroomDialog() {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    List<Map<String, dynamic>> friends = [];
    List<String> selectedFriends = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Nouveau Groupe',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: formKey,
                      child: TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Nom du groupe',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.withOpacity(0.1),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un nom';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Participants:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: FutureBuilder(
                        future: _getFriendsList(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Erreur: ${snapshot.error}'),
                            );
                          }

                          friends = snapshot.data as List<Map<String, dynamic>>;

                          if (friends.isEmpty) {
                            return const Center(
                              child: Text('Aucun ami à ajouter'),
                            );
                          }

                          return ListView.builder(
                            itemCount: friends.length,
                            itemBuilder: (context, index) {
                              final friend = friends[index];
                              return CheckboxListTile(
                                value: selectedFriends.contains(friend['id']),
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedFriends.add(friend['id']);
                                    } else {
                                      selectedFriends.remove(friend['id']);
                                    }
                                  });
                                },
                                title: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
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
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              if (selectedFriends.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Veuillez sélectionner au moins un participant',
                                    ),
                                  ),
                                );
                                return;
                              }

                              try {
                                final participants = [
                                  ...selectedFriends,
                                  _user?.uid,
                                ];

                                final newChat = await _firestore
                                    .collection('chatrooms')
                                    .add({
                                      'name': nameController.text.trim(),
                                      'createdAt': FieldValue.serverTimestamp(),
                                      'createdBy': _user?.uid,
                                      'isPinned': false,
                                      'lastMessage': '',
                                      'lastMessageSender': null,
                                      'lastMessageTime': null,
                                      'participants': participants,
                                      'isGroup': true,
                                      'unreadCounts': {
                                        for (var uid in participants) uid: 0,
                                      },
                                    });

                                Navigator.pop(context);
                                _openNewChatroom(newChat.id);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erreur: $e')),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Créer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getFriendsList() async {
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

  void _togglePinChatroom(String chatroomId, bool pin) {
    _firestore.collection('chatrooms').doc(chatroomId).update({
      'isPinned': pin,
    });
  }

  void _showEditChatroomNameDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final nameController = TextEditingController(text: data['name']);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Modifier le nom'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nouveau nom',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    _firestore.collection('chatrooms').doc(doc.id).update({
                      'name': nameController.text.trim(),
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
    );
  }
}
