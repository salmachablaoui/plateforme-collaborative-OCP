import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  final User? user;
  final String? userId;

  const ProfileScreen({super.key, this.user, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> _userData;
  bool _isLoading = true;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  File? _imageFile;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  late String _currentUserId;

  late TextEditingController _fullNameController;
  late TextEditingController _departmentController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.user?.uid ?? widget.userId ?? '';
    _userData = {
      'fullName': 'Chargement...',
      'email': '',
      'department': '',
      'phone': '',
      'photoBase64': '',
    };
    _fullNameController = TextEditingController();
    _departmentController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_currentUserId.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUserId)
              .get();

      if (doc.exists) {
        setState(() {
          _userData = doc.data() as Map<String, dynamic>;
          _fullNameController.text = _userData['fullName'] ?? '';
          _departmentController.text = _userData['department'] ?? '';
          _phoneController.text = _userData['phone'] ?? '';

          if (widget.user == null && _userData['email'] != null) {
            _userData['email'] = _userData['email'];
          } else if (widget.user != null) {
            _userData['email'] = widget.user!.email ?? '';
          }
        });
      }
    } catch (e) {
      _showError('Erreur chargement données: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (_currentUserId == (widget.user?.uid ?? ''))
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: _toggleEditMode,
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // Section profil fixe
                    _buildProfileHeader(),

                    // Séparateur
                    Container(height: 8, color: Colors.grey[200]),

                    // Section publications scrollable
                    _buildUserPostsSection(),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isEditing ? _pickImage : null,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200],
              backgroundImage: _getProfileImage(),
              child:
                  _userData['photoBase64']?.isEmpty ?? true
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _userData['fullName'],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(_userData['email'], style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          if (_userData['department']?.isNotEmpty ?? false)
            Text(
              _userData['department'],
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),

          // Section informations modifiables
          if (_isEditing) _buildEditableInfoSection(),
        ],
      ),
    );
  }

  Widget _buildEditableInfoSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildInfoTile(
              icon: Icons.person,
              label: 'Nom complet',
              controller: _fullNameController,
              isEditable: true,
            ),
            _buildInfoTile(
              icon: Icons.work,
              label: 'Département',
              controller: _departmentController,
              isEditable: true,
            ),
            _buildInfoTile(
              icon: Icons.phone,
              label: 'Téléphone',
              controller: _phoneController,
              isEditable: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserPostsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('posts')
              .where('userId', isEqualTo: _currentUserId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(child: Text('Erreur: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('Aucune publication disponible')),
          );
        }

        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Publications',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ...snapshot.data!.docs.map((post) {
              final postData = post.data() as Map<String, dynamic>;
              return _buildPostCard(postData, post.id);
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> postData, String postId) {
    final likes = List<String>.from(postData['likes'] ?? []);
    final commentCount = postData['commentCount'] ?? 0;
    final createdAt = postData['createdAt'] as Timestamp?;
    final timeAgo =
        createdAt != null ? _getTimeAgo(createdAt.toDate()) : 'Récemment';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de la publication
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      _userData['photoBase64']?.isNotEmpty == true
                          ? MemoryImage(
                            base64Decode(
                              _userData['photoBase64'].split(',').last,
                            ),
                          )
                          : null,
                  child:
                      _userData['photoBase64']?.isEmpty ?? true
                          ? const Icon(Icons.person)
                          : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userData['fullName'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Contenu de la publication
            if (postData['content'] != null && postData['content'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  postData['content'],
                  style: const TextStyle(fontSize: 16),
                ),
              ),

            // Image de la publication
            if (postData['imageBase64'] != null &&
                postData['imageBase64'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(postData['imageBase64'].split(',').last),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Center(child: Icon(Icons.broken_image)),
                        ),
                  ),
                ),
              ),

            // Sondage
            if (postData['hasPoll'] == true && postData['poll'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: _buildPollWidget(postData['poll'], postId),
              ),

            const SizedBox(height: 12),

            // Stats et actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(Icons.thumb_up, size: 18, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(likes.length.toString()),
                  const SizedBox(width: 16),
                  Icon(Icons.comment, size: 18, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(commentCount.toString()),
                ],
              ),
            ),

            const Divider(height: 16),

            // Boutons d'action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  icon: Icon(
                    Icons.thumb_up,
                    color:
                        likes.contains(_currentUserId)
                            ? Colors.blue
                            : Colors.grey,
                  ),
                  label: Text(
                    'J\'aime',
                    style: TextStyle(
                      color:
                          likes.contains(_currentUserId)
                              ? Colors.blue
                              : Colors.grey,
                    ),
                  ),
                  onPressed: () => _likePost(postId, likes),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.comment, color: Colors.green),
                  label: const Text(
                    'Commenter',
                    style: TextStyle(color: Colors.green),
                  ),
                  onPressed: () => _showCommentsDialog(postId, commentCount),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.share, color: Colors.green),
                  label: const Text(
                    'Partager',
                    style: TextStyle(color: Colors.green),
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollWidget(Map<String, dynamic> pollData, String postId) {
    final options = List<String>.from(pollData['options'] ?? []);
    final votes = List<int>.from(pollData['votes'] ?? []);
    final voters = List<String>.from(pollData['voters'] ?? []);
    final endTime = DateTime.parse(pollData['endTime']);
    final hasVoted = voters.contains(_currentUserId);
    final isExpired = DateTime.now().isAfter(endTime);
    final totalVotes = votes.isNotEmpty ? votes.reduce((a, b) => a + b) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sondage', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  if (!hasVoted && !isExpired) {
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
                          color: Colors.green,
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

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    String? value,
    TextEditingController? controller,
    required bool isEditable,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title:
            isEditable && controller != null
                ? TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: label,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (label == 'Nom complet' &&
                        (value == null || value.isEmpty)) {
                      return 'Ce champ est requis';
                    }
                    return null;
                  },
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value ?? controller?.text ?? 'Non renseigné',
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            (value ?? controller?.text)?.isEmpty ?? true
                                ? Colors.grey
                                : Colors.black,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    try {
      if (_userData['photoBase64']?.isNotEmpty == true) {
        return MemoryImage(
          base64Decode(_userData['photoBase64'].split(',').last),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Erreur chargement image: $e');
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          _imageBytes = await pickedFile.readAsBytes();
        } else {
          _imageFile = File(pickedFile.path);
          _imageBytes = await _imageFile!.readAsBytes();
        }
        await _saveProfileImage();
      }
    } catch (e) {
      _showError('Erreur lors de la sélection: $e');
    }
  }

  Future<void> _saveProfileImage() async {
    if (_imageBytes == null || _currentUserId.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final base64Image = base64Encode(_imageBytes!);
      final imageData = 'data:image/jpeg;base64,$base64Image';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .update({
            'photoBase64': imageData,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await _loadUserData();
      _showSuccess('Photo sauvegardée avec succès');
    } catch (e) {
      _showError('Erreur sauvegarde photo: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleEditMode() async {
    if (_isEditing) {
      if (_formKey.currentState!.validate()) {
        await _saveProfileData();
      }
    }
    setState(() => _isEditing = !_isEditing);
  }

  Future<void> _saveProfileData() async {
    if (_currentUserId.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .update({
            'fullName': _fullNameController.text.trim(),
            'department': _departmentController.text.trim(),
            'phone': _phoneController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await _loadUserData();
      _showSuccess('Profil mis à jour');
    } catch (e) {
      _showError('Erreur sauvegarde: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'poll.votes': newVotes,
        'poll.voters': FieldValue.arrayUnion([_currentUserId]),
      });
    } catch (e) {
      _showError('Erreur lors du vote: $e');
    }
  }

  Future<void> _likePost(String postId, List<String> likes) async {
    try {
      if (likes.contains(_currentUserId)) {
        await FirebaseFirestore.instance.collection('posts').doc(postId).update(
          {
            'likes': FieldValue.arrayRemove([_currentUserId]),
          },
        );
      } else {
        await FirebaseFirestore.instance.collection('posts').doc(postId).update(
          {
            'likes': FieldValue.arrayUnion([_currentUserId]),
          },
        );
      }
    } catch (e) {
      _showError('Erreur: $e');
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
    super.dispose();
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
                            : const Icon(Icons.send, size: 24),
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
                        Icons.thumb_up,
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

  Widget _buildCommentOptionsMenu(DocumentSnapshot comment) {
    final data = comment.data() as Map<String, dynamic>;
    final isOwner = data['userId'] == _user?.uid;

    return PopupMenuButton(
      icon: const Icon(Icons.more_vert, size: 20),
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

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty || _user == null) return;

    setState(() => _isLoading = true);

    try {
      final userData = await _getUserData(_user!.uid);
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
}
