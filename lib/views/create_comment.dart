import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';

class CommentDialog extends StatefulWidget {
  final String postId;
  final int initialCommentCount;

  const CommentDialog({
    Key? key,
    required this.postId,
    required this.initialCommentCount,
  }) : super(key: key);

  @override
  _CommentDialogState createState() => _CommentDialogState();
}

class _CommentDialogState extends State<CommentDialog> {
  final TextEditingController _commentController = TextEditingController();
  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  final Map<String, Map<String, dynamic>> _userCache = {};
  bool _isLoading = false;
  int _commentCount = 0;

  @override
  void initState() {
    super.initState();
    _commentCount = widget.initialCommentCount;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<Map<String, dynamic>> _getCurrentUserData() async {
    if (_user == null) return {};
    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      return doc.data() ?? {};
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return {};
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty || _user == null) return;

    setState(() => _isLoading = true);

    try {
      final userData = await _getCurrentUserData();
      final userName =
          userData['fullName'] ??
          userData['email']?.split('@')[0] ??
          'Utilisateur';
      final userPhoto = userData['photoBase64'];

      final commentData = {
        'userId': _user!.uid,
        'userName': userName,
        'userPhoto': userPhoto,
        'content': _commentController.text,
        'likes': [],
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add(commentData);

      await _firestore.collection('posts').doc(widget.postId).update({
        'commentCount': FieldValue.increment(1),
        'lastCommentAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _commentCount++;
        _commentController.clear();
      });

      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _likeComment(String commentId, List<String> likes) async {
    if (_user == null) return;

    try {
      await _firestore
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .update({
            'likes':
                likes.contains(_user!.uid)
                    ? FieldValue.arrayRemove([_user!.uid])
                    : FieldValue.arrayUnion([_user!.uid]),
          });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await _firestore
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      await _firestore.collection('posts').doc(widget.postId).update({
        'commentCount': FieldValue.increment(-1),
      });

      setState(() => _commentCount--);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _reportComment(String commentId) async {
    try {
      await _firestore.collection('reportedComments').add({
        'commentId': commentId,
        'postId': widget.postId,
        'reporterId': _user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Commentaire signalé')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    if (_userCache.containsKey(userId)) return _userCache[userId]!;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        _userCache[userId] = doc.data() ?? {};
        return _userCache[userId]!;
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
    return {};
  }

  ImageProvider? _getUserImage(String? photoBase64) {
    try {
      if (photoBase64?.isNotEmpty == true) {
        final base64String = photoBase64!.split(',').last;
        return MemoryImage(base64Decode(base64String));
      }
      return null;
    } catch (e) {
      debugPrint('Error loading user image: $e');
      return null;
    }
  }

  Widget _buildCommentOptionsMenu(DocumentSnapshot comment) {
    final data = comment.data() as Map<String, dynamic>;
    final isOwner = data['userId'] == _user?.uid;

    return PopupMenuButton<String>(
      icon: const Icon(Iconsax.more, size: 20),
      onSelected: (value) {
        if (value == 'delete') _deleteComment(comment.id);
        if (value == 'report') _reportComment(comment.id);
      },
      itemBuilder:
          (context) => [
            if (isOwner)
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Supprimer'),
              ),
            const PopupMenuItem<String>(
              value: 'report',
              child: Text('Signaler'),
            ),
          ],
    );
  }

  Widget _buildCommentItem(DocumentSnapshot doc) {
    final comment = doc.data() as Map<String, dynamic>;
    final likes = List<String>.from(comment['likes'] ?? []);
    final isLiked = _user != null && likes.contains(_user!.uid);
    final createdAt = comment['createdAt'] as Timestamp?;

    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserData(comment['userId']),
      builder: (context, snapshot) {
        final userData = snapshot.data ?? {};
        final photoBase64 = userData['photoBase64'] ?? comment['userPhoto'];
        final imageProvider = _getUserImage(photoBase64);
        final userName =
            userData['fullName'] ??
            userData['email']?.split('@')[0] ??
            comment['userName'] ??
            'Utilisateur';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      backgroundImage: imageProvider,
                      child:
                          imageProvider == null
                              ? Text(
                                userName.substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Colors.blue),
                              )
                              : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                createdAt != null
                                    ? _getTimeAgo(createdAt.toDate())
                                    : 'Maintenant',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment['content'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    _buildCommentOptionsMenu(doc),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Iconsax.like_1,
                        size: 16,
                        color: isLiked ? Colors.blue : Colors.grey,
                      ),
                      onPressed: () => _likeComment(doc.id, likes),
                    ),
                    Text(
                      '${likes.length}',
                      style: TextStyle(
                        color: isLiked ? Colors.blue : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) return '${difference.inSeconds}s';
    if (difference.inMinutes < 60) return '${difference.inMinutes}min';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 30) return '${difference.inDays}j';
    if (difference.inDays < 365)
      return '${(difference.inDays / 30).floor()}mois';
    return '${(difference.inDays / 365).floor()}ans';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Commentaires ($_commentCount)'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _buildCommentContent(),
      );
    } else {
      return Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Commentaires ($_commentCount)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _buildCommentContent()),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildCommentContent() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                _firestore
                    .collection('posts')
                    .doc(widget.postId)
                    .collection('comments')
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erreur de chargement',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final comments = snapshot.data?.docs ?? [];

              if (comments.isEmpty) {
                return Center(
                  child: Text(
                    'Aucun commentaire',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  return _buildCommentItem(comments[index]);
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Ajouter un commentaire...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Iconsax.send_1, size: 24),
                onPressed: _isLoading ? null : _addComment,
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
