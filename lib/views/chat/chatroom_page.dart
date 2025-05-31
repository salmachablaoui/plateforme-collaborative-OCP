import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

// Thème vert moderne
final ThemeData greenTheme = ThemeData(
  primaryColor: const Color(0xFF2E7D32),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF2E7D32),
    secondary: Color(0xFF4CAF50),
    surface: Colors.white,
    //background: Color(0xFFE8F5E9),
    background: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF2E7D32),
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: Colors.white),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF4CAF50),
  ),
  cardTheme: CardThemeData(
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);

class ChatroomPage extends StatefulWidget {
  final String chatroomId;
  final VoidCallback onDelete;

  const ChatroomPage({
    Key? key,
    required this.chatroomId,
    required this.onDelete,
  }) : super(key: key);

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
  bool _isFavorite = false;
  bool _isAdmin = false;
  bool _isScrolledUp = false;

  @override
  void initState() {
    super.initState();
    _initializeStreams();
    _checkUserStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
      _scrollToBottom();
    });

    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels > 100) {
      if (!_isScrolledUp) {
        setState(() => _isScrolledUp = true);
      }
    } else {
      if (_isScrolledUp) {
        setState(() => _isScrolledUp = false);
      }
    }
  }

  void _initializeStreams() {
    _messagesStream =
        _firestore
            .collection('chatrooms')
            .doc(widget.chatroomId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .snapshots();

    _chatroomStream =
        _firestore.collection('chatrooms').doc(widget.chatroomId).snapshots();
  }

  Future<void> _checkUserStatus() async {
    if (_currentUser == null) return;

    // Vérifier le statut favori
    final favDoc =
        await _firestore
            .collection('chatrooms')
            .doc(widget.chatroomId)
            .collection('favorites')
            .doc(_currentUser!.uid)
            .get();

    // Vérifier le statut admin
    final chatroomDoc =
        await _firestore.collection('chatrooms').doc(widget.chatroomId).get();

    setState(() {
      _isFavorite = favDoc.exists;
      _isAdmin = chatroomDoc['createdBy'] == _currentUser!.uid;
    });
  }

  Future<void> _toggleFavorite() async {
    if (_currentUser == null) return;

    setState(() => _isFavorite = !_isFavorite);

    final favoritesRef = _firestore
        .collection('chatrooms')
        .doc(widget.chatroomId)
        .collection('favorites')
        .doc(_currentUser!.uid);

    if (_isFavorite) {
      await favoritesRef.set({
        'userId': _currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'userName': _userNames[_currentUser!.uid] ?? 'Utilisateur',
      });
    } else {
      await favoritesRef.delete();
    }
  }

  void _markMessagesAsRead() {
    if (_currentUser == null) return;
    _firestore.collection('chatrooms').doc(widget.chatroomId).update({
      'unreadCounts.${_currentUser!.uid}': 0,
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

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
            'read': false,
          });

      await _updateChatroomAfterMessage(message);
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _updateChatroomAfterMessage(String message) async {
    try {
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
          await _firestore
              .collection('chatrooms')
              .doc(widget.chatroomId)
              .update({'unreadCounts.$participant': FieldValue.increment(1)});
        }
      }
    } catch (e) {
      debugPrint('Error updating chatroom: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _loadUserInfo(String userId) async {
    if (_userNames.containsKey(userId)) return;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>? ?? {};
        setState(() {
          _userNames[userId] = data['fullName'] ?? 'Utilisateur';
          _userPhotos[userId] = data['photoUrl'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading user info: $e');
    }
  }

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.green[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              DateFormat('EEEE, d MMMM y').format(date),
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.green[300])),
        ],
      ),
    );
  }

  bool _shouldShowDateSeparator(
    DocumentSnapshot current,
    DocumentSnapshot? previous,
  ) {
    if (previous == null) return true;

    final currentDate = (current['timestamp'] as Timestamp).toDate();
    final previousDate = (previous['timestamp'] as Timestamp).toDate();

    return !DateUtils.isSameDay(currentDate, previousDate);
  }

  Widget _buildMessageBubble(
    DocumentSnapshot messageDoc,
    DocumentSnapshot? previousDoc,
  ) {
    final messageData = messageDoc.data() as Map<String, dynamic>;
    final isMe = messageData['senderId'] == _currentUser?.uid;
    final senderId = messageData['senderId'];
    final messageText = messageData['text'] ?? '';
    final timestamp = messageData['timestamp'] as Timestamp?;
    final attachment = messageData['attachment'] as Map<String, dynamic>?;

    _loadUserInfo(senderId);

    return Column(
      children: [
        if (_shouldShowDateSeparator(messageDoc, previousDoc))
          _buildDateSeparator(timestamp!.toDate()),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage:
                        _userPhotos[senderId]?.isNotEmpty ?? false
                            ? CachedNetworkImageProvider(_userPhotos[senderId]!)
                            : null,
                    child:
                        _userPhotos[senderId]?.isEmpty ?? true
                            ? Text(_userNames[senderId]?.substring(0, 1) ?? 'U')
                            : null,
                  ),
                ),
              Flexible(
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          _userNames[senderId] ?? 'Utilisateur',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                      ),
                    if (attachment != null) _buildAttachmentWidget(attachment),
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isMe
                                ? greenTheme.colorScheme.primary
                                : Colors.grey[200],
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 16),
                        ),
                      ),
                      child: Text(
                        messageText,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment:
                            isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                        children: [
                          if (timestamp != null)
                            Text(
                              DateFormat.Hm().format(timestamp.toDate()),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          if (isMe)
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Icon(
                                messageData['read'] == true
                                    ? Iconsax.tick_circle
                                    : Iconsax.link,
                                size: 12,
                                color:
                                    messageData['read'] == true
                                        ? Colors.blue
                                        : Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentWidget(Map<String, dynamic> attachment) {
    final type = attachment['type'] as String? ?? 'unknown';
    final url = attachment['url'] as String? ?? '';

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
              placeholder:
                  (context, url) => Container(
                    color: Colors.grey[300],
                    width: 200,
                    height: 200,
                  ),
              errorWidget:
                  (context, url, error) => Container(
                    color: Colors.grey[300],
                    width: 200,
                    height: 200,
                    child: const Icon(Iconsax.gallery_slash),
                  ),
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
              const Icon(Iconsax.document, color: Colors.green),
              const SizedBox(width: 8),
              const Text('Document', style: TextStyle(color: Colors.green)),
            ],
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('Fichier joint'),
        );
    }
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
          padding: const EdgeInsets.symmetric(horizontal: 8),
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
                      final isAdmin = userId == chatroomData['createdBy'];
                      final fullName = userData['fullName'] ?? 'Utilisateur';
                      final photoUrl = userData['photoUrl'] as String?;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Chip(
                          avatar: CircleAvatar(
                            radius: 14,
                            backgroundImage:
                                photoUrl != null && photoUrl.isNotEmpty
                                    ? CachedNetworkImageProvider(photoUrl)
                                    : null,
                            child:
                                photoUrl == null || photoUrl.isEmpty
                                    ? Text(fullName.substring(0, 1))
                                    : null,
                          ),
                          label: Text(fullName),
                          backgroundColor:
                              isAdmin
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.grey[200],
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

  Widget _buildAppBarActions() {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            _isFavorite ? Iconsax.star1 : Iconsax.star,
            color: _isFavorite ? Colors.amber : Colors.white,
          ),
          onPressed: _toggleFavorite,
        ),
        IconButton(
          icon: const Icon(Iconsax.info_circle),
          onPressed: _showChatroomInfo,
        ),
        if (_isAdmin)
          PopupMenuButton<String>(
            icon: const Icon(Iconsax.more),
            onSelected: (value) {
              if (value == 'delete') _confirmDeleteChatroom();
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Supprimer la conversation'),
                  ),
                ],
          ),
      ],
    );
  }

  void _showChatroomInfo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Participants:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: participants.length,
                      itemBuilder: (context, index) {
                        final userId = participants[index];
                        return FutureBuilder<DocumentSnapshot>(
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
                            final fullName =
                                userData['fullName'] ?? 'Utilisateur';
                            final photoUrl = userData['photoUrl'] as String?;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                    photoUrl != null && photoUrl.isNotEmpty
                                        ? CachedNetworkImageProvider(photoUrl)
                                        : null,
                                child:
                                    photoUrl == null || photoUrl.isEmpty
                                        ? Text(fullName.substring(0, 1))
                                        : null,
                              ),
                              title: Text(fullName),
                              subtitle: isAdmin ? const Text('Admin') : null,
                              trailing:
                                  isAdmin
                                      ? const Icon(
                                        Iconsax.crown1,
                                        color: Colors.amber,
                                      )
                                      : null,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_currentUser?.uid == createdBy)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _addParticipants,
                        child: const Text('Ajouter des participants'),
                      ),
                    ),
                  if (_currentUser?.uid != createdBy)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _confirmLeaveChatroom,
                        child: const Text('Quitter la conversation'),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteChatroom() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer la conversation'),
            content: const Text(
              'Voulez-vous vraiment supprimer définitivement cette conversation ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteChatroom();
                },
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteChatroom() async {
    try {
      await _firestore.collection('chatrooms').doc(widget.chatroomId).delete();
      widget.onDelete();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  void _confirmLeaveChatroom() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Quitter la conversation'),
            content: const Text(
              'Voulez-vous vraiment quitter cette conversation ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _leaveChatroom();
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

  Future<void> _leaveChatroom() async {
    if (_currentUser == null) return;

    try {
      await _firestore.collection('chatrooms').doc(widget.chatroomId).update({
        'participants': FieldValue.arrayRemove([_currentUser!.uid]),
      });
      widget.onDelete();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  Future<void> _addParticipants() async {
    // TODO: Implémenter la logique d'ajout de participants
  }

  Widget _buildAttachmentOptions() {
    return Positioned(
      bottom: 70,
      left: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildAttachmentOption(
                Iconsax.image,
                'Galerie',
                _pickImageFromGallery,
              ),
              _buildAttachmentOption(
                Iconsax.camera,
                'Appareil photo',
                _takePhoto,
              ),
              _buildAttachmentOption(
                Iconsax.document,
                'Document',
                _pickDocument,
              ),
              _buildAttachmentOption(Iconsax.microphone, 'Audio', _recordAudio),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
    IconData icon,
    String text,
    VoidCallback onTap,
  ) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.green[700]),
      title: Text(text, style: TextStyle(color: Colors.grey[800])),
      onTap: onTap,
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        _sendFileMessage('image', image.path);
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la sélection de l\'image');
    } finally {
      setState(() => _showAttachmentOptions = false);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        _sendFileMessage('image', photo.path);
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la prise de photo');
    } finally {
      setState(() => _showAttachmentOptions = false);
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        if (file.path != null) {
          _sendFileMessage('document', file.path!);
        }
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la sélection du document');
    } finally {
      setState(() => _showAttachmentOptions = false);
    }
  }

  void _recordAudio() {
    // TODO: Implémenter l'enregistrement audio
    setState(() => _showAttachmentOptions = false);
  }

  void _toggleAttachmentOptions() {
    setState(() => _showAttachmentOptions = !_showAttachmentOptions);
  }

  Future<void> _sendFileMessage(String type, String path) async {
    try {
      await _firestore
          .collection('chatrooms')
          .doc(widget.chatroomId)
          .collection('messages')
          .add({
            'text': '[Fichier $type]',
            'senderId': _currentUser?.uid,
            'timestamp': FieldValue.serverTimestamp(),
            'attachment': {'type': type, 'url': path},
          });

      await _updateChatroomAfterMessage('[Fichier $type]');
    } catch (e) {
      _showErrorSnackbar('Erreur lors de l\'envoi du fichier');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Iconsax.paperclip),
            onPressed: _toggleAttachmentOptions,
            color: Colors.green[700],
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Écrire un message...',
                          border: InputBorder.none,
                        ),
                        maxLines: 3,
                        minLines: 1,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Iconsax.send1, color: Colors.green[700]),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollDownButton() {
    return Positioned(
      bottom: 80,
      right: 16,
      child: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.green[700],
        onPressed: _scrollToBottom,
        child: const Icon(Iconsax.arrow_down_1, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: greenTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFE8F5E9),
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
          actions: [_buildAppBarActions()],
        ),
        body: GestureDetector(
          onTap: () {
            if (_showAttachmentOptions) {
              setState(() => _showAttachmentOptions = false);
            }
            FocusScope.of(context).unfocus();
          },
          child: Stack(
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
                          return Center(
                            child: Text('Erreur: ${snapshot.error}'),
                          );
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final messages = snapshot.data!.docs;

                        if (messages.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Iconsax.message,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun message dans cette conversation',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            return _buildMessageBubble(
                              messages[index],
                              index < messages.length - 1
                                  ? messages[index + 1]
                                  : null,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  _buildMessageInput(),
                ],
              ),
              if (_showAttachmentOptions) _buildAttachmentOptions(),
              if (_isScrolledUp) _buildScrollDownButton(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
