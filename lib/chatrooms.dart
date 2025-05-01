import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'adaptive_drawer.dart';
import 'custom_app_bar.dart';

class ChatroomsScreen extends StatefulWidget {
  const ChatroomsScreen({Key? key}) : super(key: key);

  @override
  State<ChatroomsScreen> createState() => _ChatroomsScreenState();
}

class _ChatroomsScreenState extends State<ChatroomsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final User? _user = FirebaseAuth.instance.currentUser;
  final List<Chatroom> _chatrooms = [
    Chatroom(
      name: 'Général',
      lastMessage: 'Alice: Salut tout le monde !',
      time: '10:30',
      unreadCount: 3,
      isPinned: true,
    ),
    Chatroom(
      name: 'Projet A',
      lastMessage: 'Benoît: J\'ai fini le module 3',
      time: 'Hier',
      unreadCount: 0,
      isPinned: false,
    ),
    Chatroom(
      name: 'Random',
      lastMessage: 'Claire: 😂😂😂',
      time: '11/05',
      unreadCount: 12,
      isPinned: true,
    ),
    Chatroom(
      name: 'Support',
      lastMessage: 'Support: Votre ticket a été résolu',
      time: '08/05',
      unreadCount: 0,
      isPinned: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pinnedChatrooms = _chatrooms.where((c) => c.isPinned).toList();
    final otherChatrooms = _chatrooms.where((c) => !c.isPinned).toList();

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AdaptiveDrawer(),
      appBar: CustomAppBar(
        title: 'Chatrooms',
        scaffoldKey: _scaffoldKey,
        user: _user,
        showSearchButton: true,
        showNotifications: true,
        additionalActions: [
          IconButton(
            icon: const Icon(Iconsax.add),
            onPressed: _createNewChatroom,
          ),
        ],
      ),
      body: Column(
        children: [
          // Section chatrooms épinglées
          if (pinnedChatrooms.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Iconsax.location_add, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'ÉPINGLÉS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            ...pinnedChatrooms.map(
              (chatroom) => _ChatroomItem(
                chatroom: chatroom,
                onTap: () => _openChatroom(context, chatroom),
              ),
            ),
          ],

          // Section autres chatrooms
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Iconsax.message, size: 16),
                SizedBox(width: 8),
                Text(
                  'TOUTES LES CHATROOMS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: otherChatrooms.length,
              itemBuilder:
                  (context, index) => _ChatroomItem(
                    chatroom: otherChatrooms[index],
                    onTap: () => _openChatroom(context, otherChatrooms[index]),
                  ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewChatroom,
        backgroundColor: AdaptiveDrawer.primaryColor,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  void _openChatroom(BuildContext context, Chatroom chatroom) {
    Navigator.pushNamed(context, '/chatroom', arguments: chatroom);
  }

  void _createNewChatroom() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nouvelle chatroom',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Nom de la chatroom',
                    prefixIcon: const Icon(Iconsax.message),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chatroom créée')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdaptiveDrawer.primaryColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Créer'),
                ),
              ],
            ),
          ),
    );
  }
}

class Chatroom {
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isPinned;

  Chatroom({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.isPinned,
  });
}

class _ChatroomItem extends StatelessWidget {
  final Chatroom chatroom;
  final VoidCallback onTap;

  const _ChatroomItem({required this.chatroom, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AdaptiveDrawer.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          chatroom.isPinned ? Iconsax.message_favorite : Iconsax.message_2,
          color: AdaptiveDrawer.primaryColor,
        ),
      ),
      title: Text(
        chatroom.name,
        style: TextStyle(
          fontWeight:
              chatroom.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        chatroom.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight:
              chatroom.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
          color: chatroom.unreadCount > 0 ? Colors.black : Colors.grey,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            chatroom.time,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight:
                  chatroom.unreadCount > 0
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
          ),
          if (chatroom.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                chatroom.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}
