import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:app_stage/views/chat/infos_chatroom.dart';

// Thème vert moderne
final ThemeData greenTheme = ThemeData(
  primaryColor: const Color(0xFF2E7D32),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF2E7D32),
    secondary: Color(0xFF4CAF50),
    surface: Colors.white,
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
  cardTheme: const CardThemeData(
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
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
  bool _isUploading = false;

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

    final favDoc =
        await _firestore
            .collection('chatrooms')
            .doc(widget.chatroomId)
            .collection('favorites')
            .doc(_currentUser!.uid)
            .get();

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
            'type': 'text',
          });

      await _updateChatroomAfterMessage(message);
      _scrollToBottom();
    } catch (e) {
      _showErrorSnackbar('Erreur: ${e.toString()}');
    }
  }

  Future<void> _sendPollMessage(List<String> options, String question) async {
    try {
      await _firestore
          .collection('chatrooms')
          .doc(widget.chatroomId)
          .collection('messages')
          .add({
            'text': question,
            'senderId': _currentUser?.uid,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
            'type': 'poll',
            'poll': {
              'options': options,
              'votes': List.filled(options.length, 0),
              'voters': [],
              'endTime':
                  DateTime.now().add(const Duration(days: 1)).toIso8601String(),
              'question': question,
            },
          });

      await _updateChatroomAfterMessage('Sondage: $question');
      _scrollToBottom();
    } catch (e) {
      _showErrorSnackbar(
        'Erreur lors de la création du sondage: ${e.toString()}',
      );
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
    final type = messageData['type'] ?? 'text';
    final pollData = messageData['poll'] as Map<String, dynamic>?;
    final imageBase64 = messageData['imageBase64'] as String?;
    final imageUrl = messageData['imageUrl'] as String?;

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
                  child: _buildUserAvatar(senderId),
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
                    if (type == 'image' &&
                        (imageBase64 != null || imageUrl != null))
                      _buildImageMessage(imageBase64, imageUrl),
                    if (type == 'poll' && pollData != null)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return SizedBox(
                            width: constraints.maxWidth * 0.65,
                            child: _buildPollWidget(pollData, messageDoc.id),
                          );
                        },
                      ),
                    if (type == 'text')
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isMe
                                  ? greenTheme.colorScheme.primary
                                  : Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: Radius.circular(isMe ? 12 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 12),
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

  Widget _buildUserAvatar(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final photoUrl = userData['photoUrl'] as String?;

          if (photoUrl?.isNotEmpty ?? false) {
            return CircleAvatar(
              radius: 16,
              backgroundImage: CachedNetworkImageProvider(photoUrl!),
            );
          }
        }

        return CircleAvatar(
          radius: 16,
          backgroundColor: Colors.green[100],
          child: Text(
            _userNames[userId]?.substring(0, 1) ?? 'U',
            style: TextStyle(color: Colors.green[800]),
          ),
        );
      },
    );
  }

  Widget _buildImageMessage(String? imageBase64, String? imageUrl) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(imageBase64, imageUrl),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
          maxHeight: 200,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildImageContent(imageBase64, imageUrl),
        ),
      ),
    );
  }

  Widget _buildImageContent(String? imageBase64, String? imageUrl) {
    if (imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey[300]),
        errorWidget:
            (context, url, error) => Container(
              color: Colors.grey[300],
              child: const Icon(Iconsax.gallery_slash),
            ),
      );
    } else if (imageBase64 != null) {
      return Image.memory(
        base64Decode(imageBase64.split(',').last),
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => Container(
              color: Colors.grey[300],
              child: const Icon(Iconsax.gallery_slash),
            ),
      );
    } else {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Iconsax.gallery_slash),
      );
    }
  }

  void _showFullScreenImage(String? imageBase64, String? imageUrl) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: InteractiveViewer(
              child:
                  imageUrl != null
                      ? CachedNetworkImage(imageUrl: imageUrl)
                      : imageBase64 != null
                      ? Image.memory(base64Decode(imageBase64.split(',').last))
                      : Container(),
            ),
          ),
    );
  }

  Widget _buildPollWidget(Map<String, dynamic> pollData, String messageId) {
    final options = List<String>.from(pollData['options'] ?? []);
    final votes = List<int>.from(pollData['votes'] ?? []);
    final voters = List<String>.from(pollData['voters'] ?? []);
    final endTime = DateTime.parse(pollData['endTime']);
    final hasVoted = voters.contains(_currentUser?.uid);
    final isExpired = DateTime.now().isAfter(endTime);
    final totalVotes = votes.isNotEmpty ? votes.reduce((a, b) => a + b) : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sondage: ${pollData['question'] ?? ''}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final percentage =
                totalVotes > 0 ? (votes[index] / totalVotes * 100).round() : 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  if (!hasVoted && !isExpired && _currentUser != null) {
                    _voteInPoll(messageId, index, options, votes, voters);
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              color:
                                  hasVoted || isExpired
                                      ? Colors.green[800]
                                      : Colors.black87,
                            ),
                          ),
                        ),
                        if (hasVoted || isExpired)
                          Text(
                            '$percentage%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    if (hasVoted || isExpired) ...[
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 4,
                        backgroundColor: Colors.grey[300],
                        color: Colors.green,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          Text(
            isExpired
                ? 'Terminé • $totalVotes votes'
                : 'Clôture dans ${_formatTimeRemaining(endTime)}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeRemaining(DateTime endTime) {
    final now = DateTime.now();
    final difference = endTime.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'moins d\'une minute';
    }
  }

  Future<void> _voteInPoll(
    String messageId,
    int optionIndex,
    List<String> options,
    List<int> votes,
    List<String> voters,
  ) async {
    try {
      final newVotes = List<int>.from(votes);
      newVotes[optionIndex] += 1;

      await _firestore
          .collection('chatrooms')
          .doc(widget.chatroomId)
          .collection('messages')
          .doc(messageId)
          .update({
            'poll.votes': newVotes,
            'poll.voters': FieldValue.arrayUnion([_currentUser!.uid]),
          });
    } catch (e) {
      _showErrorSnackbar('Erreur lors du vote: ${e.toString()}');
    }
  }

  Widget _buildGroupAvatar() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _chatroomStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const CircleAvatar(radius: 16, child: Icon(Iconsax.people));
        }

        final chatroomData = snapshot.data!.data() as Map<String, dynamic>;
        final photoUrl = chatroomData['photoUrl'] as String?;

        return CircleAvatar(
          radius: 16,
          backgroundImage:
              photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null,
          child: photoUrl == null ? const Icon(Iconsax.people, size: 16) : null,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          _buildGroupAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: _chatroomStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.exists) {
                      _chatroomData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      return Text(
                        _chatroomData!['name'] ?? 'Chatroom',
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      );
                    }
                    return const Text('Chatroom');
                  },
                ),
                StreamBuilder<DocumentSnapshot>(
                  stream: _chatroomStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final participants =
                          (snapshot.data!['participants'] as List).length;
                      return Text(
                        '$participants membres',
                        style: const TextStyle(fontSize: 12),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => InfosChatroomPage(
              chatroomId: widget.chatroomId,
              isAdmin: _isAdmin,
              onMembersUpdated: () => setState(() {}),
            ),
      ),
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
        _showErrorSnackbar('Erreur: ${e.toString()}');
      }
    }
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
              _buildAttachmentOption(Iconsax.chart, 'Sondage', _createPoll),
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
        await _uploadImage(File(image.path));
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
        await _uploadImage(File(photo.path));
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la prise de photo');
    } finally {
      setState(() => _showAttachmentOptions = false);
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() => _isUploading = true);

    try {
      // Vérifier la taille de l'image avant l'upload
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        // 5MB max
        _showErrorSnackbar('L\'image est trop grande (max 5MB)');
        return;
      }

      if (kIsWeb) {
        // Solution pour le web
        final bytes = await imageFile.readAsBytes();
        final imageData = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        await _firestore
            .collection('chatrooms')
            .doc(widget.chatroomId)
            .collection('messages')
            .add({
              'imageBase64': imageData,
              'senderId': _currentUser?.uid,
              'timestamp': FieldValue.serverTimestamp(),
              'type': 'image',
              'text': _messageController.text.trim(),
            });
      } else {
        // Solution pour mobile
        final bytes = await imageFile.readAsBytes();
        final base64String = base64Encode(bytes);
        final imageData = 'data:image/jpeg;base64,$base64String';

        await _firestore
            .collection('chatrooms')
            .doc(widget.chatroomId)
            .collection('messages')
            .add({
              'imageBase64': imageData,
              'senderId': _currentUser?.uid,
              'timestamp': FieldValue.serverTimestamp(),
              'type': 'image',
              'text': _messageController.text.trim(),
            });
      }

      await _updateChatroomAfterMessage('Image envoyée');
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      _showErrorSnackbar('Erreur lors de l\'envoi de l\'image: $e');
    } finally {
      setState(() => _isUploading = false);
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

  void _createPoll() {
    setState(() => _showAttachmentOptions = false);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Créer un sondage'),
            content: PollCreationDialog(
              onCreatePoll: (question, options) {
                _sendPollMessage(options, question);
              },
            ),
          ),
    );
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

  void _toggleAttachmentOptions() {
    setState(() => _showAttachmentOptions = !_showAttachmentOptions);
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
                    onPressed: _isUploading ? null : _sendMessage,
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

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: greenTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFFE8F5E9),
        appBar: _buildAppBar(),
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
                  if (_isUploading)
                    const LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: Colors.transparent,
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

class PollCreationDialog extends StatefulWidget {
  final Function(String, List<String>) onCreatePoll;

  const PollCreationDialog({Key? key, required this.onCreatePoll})
    : super(key: key);

  @override
  _PollCreationDialogState createState() => _PollCreationDialogState();
}

class _PollCreationDialogState extends State<PollCreationDialog> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers.removeAt(index);
      });
    }
  }

  void _createPoll() {
    final question = _questionController.text.trim();
    final options =
        _optionControllers
            .map((controller) => controller.text.trim())
            .where((option) => option.isNotEmpty)
            .toList();

    if (question.isEmpty || options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une question et au moins 2 options'),
        ),
      );
      return;
    }

    widget.onCreatePoll(question, options);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _questionController,
            decoration: const InputDecoration(
              labelText: 'Question du sondage',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Options (minimum 2)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._optionControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Option ${index + 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  if (_optionControllers.length > 2)
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => _removeOption(index),
                    ),
                ],
              ),
            );
          }),
          TextButton(
            onPressed: _addOption,
            child: const Text('Ajouter une option'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _createPoll,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Créer le sondage'),
          ),
        ],
      ),
    );
  }
}
