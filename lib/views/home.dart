import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'shared/adaptive_drawer.dart';
import 'profil.dart';
import 'shared/custom_app_bar.dart';
import 'create_post_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  final double _maxCardWidth = 600;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, Map<String, dynamic>> _userProfiles = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _getUserProfile(String userId) async {
    if (_userProfiles.containsKey(userId)) {
      return _userProfiles[userId]!;
    }

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        _userProfiles[userId] = doc.data() ?? {};
        return _userProfiles[userId]!;
      }
    } catch (e) {
      debugPrint('Erreur chargement profil utilisateur: $e');
    }
    return {};
  }

  ImageProvider? _getProfileImage(String? photoBase64) {
    try {
      if (photoBase64?.isNotEmpty == true) {
        final base64String = photoBase64!.split(',').last;
        return MemoryImage(base64Decode(base64String));
      }
      return null;
    } catch (e) {
      debugPrint('Erreur chargement image: $e');
      return null;
    }
  }

  Widget _buildPollWidget(Map<String, dynamic> pollData, String postId) {
    final options = List<String>.from(pollData['options'] ?? []);
    final votes = List<int>.from(pollData['votes'] ?? []);
    final voters = List<String>.from(pollData['voters'] ?? []);
    final endTime = DateTime.parse(pollData['endTime']);
    final hasVoted = voters.contains(_user?.uid);
    final isExpired = DateTime.now().isAfter(endTime);
    final totalVotes = votes.isNotEmpty ? votes.reduce((a, b) => a + b) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Sondage',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final percentage =
              totalVotes > 0 ? (votes[index] / totalVotes * 100) : 0;

          return Column(
            children: [
              InkWell(
                onTap: () {
                  if (!hasVoted && !isExpired && _user != null) {
                    _voteInPoll(postId, index, options, votes, voters);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (hasVoted || isExpired)
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(option)),
                          if (hasVoted || isExpired) Text('(${votes[index]})'),
                        ],
                      ),
                      if (hasVoted || isExpired) ...[
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey.shade200,
                          color: Colors.green, // Changé en bleu ici
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          );
        }),
        Text(
          isExpired
              ? 'Sondage terminé • $totalVotes votes'
              : 'Clôture dans ${endTime.difference(DateTime.now()).inDays} jours',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Future<void> _voteInPoll(
    String postId,
    int optionIndex,
    List<String> options,
    List<int> votes,
    List<String> voters,
  ) async {
    try {
      final newVotes = List<int>.from(votes);
      newVotes[optionIndex] += 1;

      await _firestore.collection('posts').doc(postId).update({
        'poll.votes': newVotes,
        'poll.voters': FieldValue.arrayUnion([_user!.uid]),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du vote: ${e.toString()}')),
      );
    }
  }

  Future<void> _likePost(String postId, List likes) async {
    try {
      if (likes.contains(_user!.uid)) {
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayRemove([_user!.uid]),
        });
      } else {
        await _firestore.collection('posts').doc(postId).update({
          'likes': FieldValue.arrayUnion([_user!.uid]),
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Widget _buildCreatePostCard(bool isMobile) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserProfile(_user?.uid ?? ''),
      builder: (context, snapshot) {
        final photoBase64 = snapshot.data?['photoBase64'];
        return Card(
          margin: EdgeInsets.all(isMobile ? 12 : 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: isMobile ? 20 : 24,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: _getProfileImage(photoBase64),
                      child:
                          _getProfileImage(photoBase64) == null
                              ? Text(
                                _user?.email?.substring(0, 1).toUpperCase() ??
                                    'U',
                                style: const TextStyle(color: Colors.blue),
                              )
                              : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _showCreatePostDialog,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 16,
                            vertical: isMobile ? 10 : 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Partagez une idée, une ressource...',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      icon: Icon(
                        Iconsax.video,
                        size: isMobile ? 20 : 24,
                        color: Colors.red,
                      ),
                      label: Text(
                        'Vidéo',
                        style: TextStyle(fontSize: isMobile ? 12 : 14),
                      ),
                      onPressed: () {},
                    ),
                    TextButton.icon(
                      icon: Icon(
                        Iconsax.gallery,
                        size: isMobile ? 20 : 24,
                        color: Colors.green,
                      ),
                      label: Text(
                        'Photo',
                        style: TextStyle(fontSize: isMobile ? 12 : 14),
                      ),
                      onPressed: _showCreatePostDialog,
                    ),
                    TextButton.icon(
                      icon: Icon(
                        Iconsax.chart,
                        size: isMobile ? 20 : 24,
                        color: Colors.purple,
                      ),
                      label: Text(
                        'Sondage',
                        style: TextStyle(fontSize: isMobile ? 12 : 14),
                      ),
                      onPressed: _showCreatePostDialog,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 100.ms);
      },
    );
  }

  void _showCreatePostDialog() async {
    if (_user == null) return;

    String userName = _user!.displayName ?? 'Utilisateur';

    try {
      final userDoc =
          await _firestore.collection('users').doc(_user!.uid).get();
      if (userDoc.exists) {
        userName = userDoc.data()?['fullName'] ?? 'Utilisateur';
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du nom: $e');
    }

    final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
    final userData = userDoc.data() ?? {};

    showDialog(
      context: context,
      builder:
          (context) => CreatePostDialog(
            user: _user!,
            userName: userName,
            userData: userData,
          ),
    );
  }

  Widget _buildPostItem(DocumentSnapshot post, bool isMobile) {
    final data = post.data() as Map<String, dynamic>;
    final postId = post.id;
    final likes = List<String>.from(data['likes'] ?? []);
    final commentCount = data['commentCount'] ?? 0;
    final createdAt = data['createdAt'] as Timestamp?;
    final timeAgo =
        createdAt != null ? _getTimeAgo(createdAt.toDate()) : 'Récemment';
    final hasPoll = data['hasPoll'] == true;
    final pollData = data['poll'] as Map<String, dynamic>?;

    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserProfile(data['userId']),
      builder: (context, snapshot) {
        final photoBase64 = snapshot.data?['photoBase64'];
        return Card(
          margin: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 8 : 12,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                dense: isMobile,
                leading: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ProfileScreen(userId: data['userId']),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    backgroundImage: _getProfileImage(photoBase64),
                    child:
                        _getProfileImage(photoBase64) == null
                            ? Text(data['userName'][0])
                            : null,
                  ),
                ),
                title: Text(
                  data['userName'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
                subtitle: Text(
                  '$timeAgo • ${data['visibility'] ?? 'Public'}',
                  style: TextStyle(fontSize: isMobile ? 12 : 14),
                ),
                trailing: PopupMenuButton(
                  icon: const Icon(Iconsax.more, size: 20),
                  itemBuilder:
                      (context) => [
                        if (data['userId'] == _user?.uid)
                          PopupMenuItem(
                            child: const Text('Supprimer'),
                            onTap: () => _deletePost(postId),
                          ),
                        PopupMenuItem(
                          child: const Text('Signaler'),
                          onTap: () => _reportPost(postId),
                        ),
                      ],
                ),
              ),

              if (data['content'] != null && data['content'].isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 24,
                    0,
                    isMobile ? 16 : 24,
                    isMobile ? 8 : 12,
                  ),
                  child: Text(
                    data['content'],
                    style: TextStyle(fontSize: isMobile ? 14 : 16),
                  ),
                ),

              if (data['imageBase64'] != null) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(data['imageBase64']),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: isMobile ? 180 : 240,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            height: isMobile ? 180 : 240,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Iconsax.gallery_slash),
                            ),
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              if (hasPoll && pollData != null)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: 8,
                  ),
                  child: _buildPollWidget(pollData, postId),
                ),

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: isMobile ? 8 : 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.like_1,
                      size: isMobile ? 16 : 18,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${likes.length}',
                      style: TextStyle(fontSize: isMobile ? 12 : 14),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Iconsax.message,
                      size: isMobile ? 16 : 18,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$commentCount',
                      style: TextStyle(fontSize: isMobile ? 12 : 14),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: Icon(
                          Iconsax.like_1,
                          size: isMobile ? 18 : 20,
                          color:
                              likes.contains(_user?.uid)
                                  ? Colors.blue
                                  : Colors.grey,
                        ),
                        label: Text(
                          'J\'aime',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color:
                                likes.contains(_user?.uid)
                                    ? Colors.blue
                                    : Colors.grey,
                          ),
                        ),
                        onPressed: () => _likePost(post.id, likes),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        icon: Icon(Iconsax.message, size: isMobile ? 18 : 20),
                        label: Text(
                          'Commenter',
                          style: TextStyle(fontSize: isMobile ? 12 : 14),
                        ),
                        onPressed:
                            () => _showCommentsDialog(postId, commentCount),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        icon: Icon(Iconsax.send_2, size: isMobile ? 18 : 20),
                        label: Text(
                          'Partager',
                          style: TextStyle(fontSize: isMobile ? 12 : 14),
                        ),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _reportPost(String postId) async {
    try {
      await _firestore.collection('reports').add({
        'postId': postId,
        'reporterId': _user!.uid,
        'reason': 'Contenu inapproprié',
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publication signalée avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  void _showCommentsDialog(String postId, int commentCount) {
    showDialog(
      context: context,
      builder:
          (context) =>
              CommentDialog(postId: postId, initialCommentCount: commentCount),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Il y a ${difference.inSeconds} secondes';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} heures';
    } else if (difference.inDays < 30) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Il y a $years ans';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AdaptiveDrawer(),
      appBar: CustomAppBar(
        title: 'Accueil',
        scaffoldKey: _scaffoldKey,
        user: _user,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? _maxCardWidth : double.infinity,
          ),
          child: RefreshIndicator(
            onRefresh:
                () async => await Future.delayed(const Duration(seconds: 1)),
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('posts')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverToBoxAdapter(child: _buildCreatePostCard(isMobile)),
                      const SliverFillRemaining(
                        child: Center(
                          child: Text('Aucune publication disponible'),
                        ),
                      ),
                    ],
                  );
                }

                return CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildCreatePostCard(isMobile)),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final post = snapshot.data!.docs[index];
                        return _buildPostItem(post, isMobile);
                      }, childCount: snapshot.data!.docs.length),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostDialog,
        child: const Icon(Iconsax.add),
        tooltip: 'Créer une publication',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

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

      setState(() {
        _commentCount--;
      });
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

    return PopupMenuButton(
      icon: const Icon(Iconsax.more, size: 20),
      itemBuilder:
          (context) => [
            if (isOwner)
              PopupMenuItem(
                child: const Text('Supprimer'),
                onTap: () => _deleteComment(comment.id),
              ),
            PopupMenuItem(
              child: const Text('Signaler'),
              onTap: () => _reportComment(comment.id),
            ),
          ],
    );
  }

  Widget _buildCommentItem(DocumentSnapshot doc) {
    final comment = doc.data() as Map<String, dynamic>;
    final likes = List<String>.from(comment['likes'] ?? []);
    final isLiked = _user != null && likes.contains(_user!.uid);
    final createdAt = (comment['createdAt'] as Timestamp).toDate();

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
                                _getTimeAgo(createdAt),
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
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text('Commentaires ($_commentCount)'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
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
                    return Center(child: Text('Erreur de chargement'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final comments = snapshot.data?.docs ?? [];

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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Ajouter un commentaire...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
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
                            ? const CircularProgressIndicator()
                            : const Icon(Iconsax.send_1, size: 24),
                    onPressed: _isLoading ? null : _addComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
