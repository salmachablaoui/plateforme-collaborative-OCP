import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class ChatroomPage extends StatefulWidget {
  final String chatroomId;

  const ChatroomPage({Key? key, required this.chatroomId}) : super(key: key);

  @override
  State<ChatroomPage> createState() => _ChatroomPageState();
}

class _ChatroomPageState extends State<ChatroomPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  late Stream<QuerySnapshot> _messagesStream;
  late Stream<DocumentSnapshot> _chatroomStream;
  Map<String, dynamic>? _chatroomData;
  Map<String, String> _userNames = {};
  Map<String, String> _userPhotos = {};
  bool _showAttachmentOptions = false;

  // Nouvelle méthode pour gérer les pièces jointes
  void _toggleAttachmentOptions() {
    setState(() {
      _showAttachmentOptions = !_showAttachmentOptions;
    });
  }

  Future<void> _sendFileMessage(String fileType, String filePath) async {
    try {
      // Envoyer le message avec pièce jointe
      await _firestore
          .collection('chatrooms')
          .doc(widget.chatroomId)
          .collection('messages')
          .add({
            'text': '[Fichier $fileType]',
            'senderId': _currentUser?.uid,
            'timestamp': FieldValue.serverTimestamp(),
            'attachment': {
              'type': fileType,
              'url':
                  filePath, // Vous devrez uploader le fichier et obtenir l'URL
            },
          });

      // Mettre à jour la chatroom comme dans _sendMessage()
      await _updateChatroomAfterMessage('[Fichier $fileType]');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _updateChatroomAfterMessage(String message) async {
    await _firestore.collection('chatrooms').doc(widget.chatroomId).update({
      'lastMessage': message,
      'lastMessageSender': _currentUser?.uid,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCounts.${_currentUser?.uid}': 0,
    });

    final chatroomDoc =
        await _firestore.collection('chatrooms').doc(widget.chatroomId).get();
    final participants = List<String>.from(chatroomDoc['participants'] ?? []);

    for (final participant in participants) {
      if (participant != _currentUser?.uid) {
        await _firestore.collection('chatrooms').doc(widget.chatroomId).update({
          'unreadCounts.$participant': FieldValue.increment(1),
        });
      }
    }
  }

  // Méthodes pour les différents types de pièces jointes
  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      PlatformFile file = result.files.first;
      _sendFileMessage('document', file.path!);
    }
    _toggleAttachmentOptions();
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _sendFileMessage('image', image.path);
    }
    _toggleAttachmentOptions();
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      _sendFileMessage('image', photo.path);
    }
    _toggleAttachmentOptions();
  }

  void _recordAudio() {
    // Implémentation de l'enregistrement audio
    _sendFileMessage('audio', 'chemin/vers/audio');
    _toggleAttachmentOptions();
  }

  @override
  void initState() {
    super.initState();
    _messagesStream =
        _firestore
            .collection('chatrooms')
            .doc(widget.chatroomId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .snapshots();

    _chatroomStream =
        _firestore.collection('chatrooms').doc(widget.chatroomId).snapshots();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    try {
      await _firestore
          .collection('chatrooms')
          .doc(widget.chatroomId)
          .collection('messages')
          .add({
            'text': message,
            'senderId': _currentUser?.uid,
            'timestamp': FieldValue.serverTimestamp(),
          });

      await _updateChatroomAfterMessage(message);
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _loadUserInfo(String userId) async {
    if (_userNames.containsKey(userId)) return;

    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      setState(() {
        _userNames[userId] = userDoc['fullName'] ?? 'Utilisateur';
        _userPhotos[userId] = userDoc['photoUrl'];
      });
    }
  }

  Widget _buildMessageBubble(DocumentSnapshot messageDoc) {
    final messageData = messageDoc.data() as Map<String, dynamic>;
    final isMe = messageData['senderId'] == _currentUser?.uid;
    final senderId = messageData['senderId'];
    final messageText = messageData['text'] ?? '';
    final timestamp = messageData['timestamp'] as Timestamp?;
    final attachment = messageData['attachment'] as Map<String, dynamic>?;

    _loadUserInfo(senderId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 16,
              backgroundImage:
                  _userPhotos[senderId] != null
                      ? CachedNetworkImageProvider(_userPhotos[senderId]!)
                      : null,
              child:
                  _userPhotos[senderId] == null
                      ? Text(_userNames[senderId]?.substring(0, 1) ?? 'U')
                      : null,
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Text(
                    _userNames[senderId] ?? 'Utilisateur',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (attachment != null) _buildAttachmentWidget(attachment),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.green : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    messageText,
                    style: TextStyle(color: isMe ? Colors.white : Colors.black),
                  ),
                ),
                if (timestamp != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat.Hm().format(timestamp.toDate()),
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentWidget(Map<String, dynamic> attachment) {
    final type = attachment['type'] as String;
    final url = attachment['url'] as String;

    switch (type) {
      case 'image':
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: url,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
        );
      case 'document':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.document),
              const SizedBox(width: 8),
              Text('Document', style: TextStyle(color: Colors.green)),
            ],
          ),
        );
      case 'audio':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.voice_cricle),
              const SizedBox(width: 8),
              Text('Audio', style: TextStyle(color: Colors.green)),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildAttachmentOptions() {
    return Positioned(
      bottom: 70,
      left: 10,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildAttachmentOption(
                Iconsax.document,
                'Document',
                _pickDocument,
              ),
              _buildAttachmentOption(
                Iconsax.gallery,
                'Galerie',
                _pickImageFromGallery,
              ),
              _buildAttachmentOption(Iconsax.camera, 'Camera', _takePhoto),
              _buildAttachmentOption(Iconsax.microphone, 'Audio', _recordAudio),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onTap: onTap,
    );
  }

  Widget _buildParticipantChips() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _chatroomStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox();
        }

        final chatroomData = snapshot.data!.data() as Map<String, dynamic>;
        final participants = List<String>.from(
          chatroomData['participants'] ?? [],
        );

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                participants.map((userId) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: _firestore.collection('users').doc(userId).get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                        return const SizedBox();
                      }

                      final userData =
                          userSnapshot.data!.data() as Map<String, dynamic>;
                      final fullName = userData['fullName'] ?? 'Utilisateur';
                      final photoUrl = userData['photoUrl'];

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Chip(
                          avatar: CircleAvatar(
                            backgroundImage:
                                photoUrl != null
                                    ? CachedNetworkImageProvider(photoUrl)
                                    : null,
                            child:
                                photoUrl == null
                                    ? Text(fullName.substring(0, 1))
                                    : null,
                          ),
                          label: Text(fullName),
                        ),
                      );
                    },
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: _chatroomStream,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.exists) {
              _chatroomData = snapshot.data!.data() as Map<String, dynamic>;
              return Text(_chatroomData!['name'] ?? 'Chatroom');
            }
            return const Text('Chatroom');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.info_circle),
            onPressed: () => _showChatroomInfo(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8,
                ),
                child: _buildParticipantChips(),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _messagesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Erreur: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data!.docs;

                    if (messages.isEmpty) {
                      return const Center(
                        child: Text('Aucun message dans cette chatroom'),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(messages[index]);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Iconsax.paperclip),
                      onPressed: _toggleAttachmentOptions,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Écrire un message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Iconsax.send1),
                      onPressed: _sendMessage,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showAttachmentOptions) _buildAttachmentOptions(),
        ],
      ),
    );
  }

  void _showChatroomInfo() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StreamBuilder<DocumentSnapshot>(
          stream: _chatroomStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: CircularProgressIndicator());
            }

            final chatroomData = snapshot.data!.data() as Map<String, dynamic>;
            final participants = List<String>.from(
              chatroomData['participants'] ?? [],
            );
            final createdAt = chatroomData['createdAt'] as Timestamp?;
            final createdBy = chatroomData['createdBy'];

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      chatroomData['name'] ?? 'Chatroom',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (createdAt != null)
                    Text(
                      'Créée le ${DateFormat('dd/MM/yyyy').format(createdAt.toDate())}',
                      style: TextStyle(color: Colors.grey),
                    ),
                  const SizedBox(height: 16),
                  const Text('Participants:'),
                  const SizedBox(height: 8),
                  ...participants
                      .map(
                        (userId) => FutureBuilder<DocumentSnapshot>(
                          future:
                              _firestore.collection('users').doc(userId).get(),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData ||
                                !userSnapshot.data!.exists) {
                              return const ListTile(
                                title: Text('Utilisateur inconnu'),
                              );
                            }

                            final userData =
                                userSnapshot.data!.data()
                                    as Map<String, dynamic>;
                            final isAdmin = userId == createdBy;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    userData['photoUrl'] != null
                                        ? CachedNetworkImageProvider(
                                          userData['photoUrl'],
                                        )
                                        : null,
                                child:
                                    userData['photoUrl'] == null
                                        ? Text(
                                          _getInitials(
                                            userData['fullName'] ?? 'UU',
                                          ),
                                        )
                                        : null,
                              ),
                              title: Text(
                                userData['fullName'] ?? 'Utilisateur',
                              ),
                              trailing:
                                  isAdmin
                                      ? const Chip(
                                        label: Text('Admin'),
                                        backgroundColor: Colors.green,
                                        labelStyle: TextStyle(
                                          color: Colors.white,
                                        ),
                                      )
                                      : null,
                            );
                          },
                        ),
                      )
                      .toList(),
                  const SizedBox(height: 16),
                  if (_currentUser?.uid == createdBy)
                    ElevatedButton(
                      onPressed: () => _addParticipants(),
                      child: const Text('Ajouter des participants'),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addParticipants() async {
    // Implémentez la logique pour ajouter des participants
  }

  String _getInitials(String fullName) {
    return fullName
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join('')
        .toUpperCase();
  }
}
