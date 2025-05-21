import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'shared/adaptive_drawer.dart';
import 'profil.dart';
import 'shared/custom_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  final double _maxCardWidth = 600;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _postController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _postController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    if (_postController.text.isEmpty && _imageFile == null) return;

    setState(() => _isLoading = true);

    try {
      String? imageBase64;
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        imageBase64 = base64Encode(bytes);
      }

      await _firestore.collection('posts').add({
        'userId': _user!.uid,
        'userName': _user!.displayName ?? 'Anonyme',
        'userPhoto': _user!.photoURL,
        'content': _postController.text,
        'imageBase64': imageBase64,
        'likes': [],
        'comments': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      _postController.clear();
      setState(() => _imageFile = null);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
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

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ProfileScreen(
              userId: _user?.uid ?? '', // Provide the required userId
            ),
      ),
    );
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
      body: _buildMainContent(isMobile, isDesktop, screenWidth),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostDialog(context),
        child: const Icon(Iconsax.add),
        tooltip: 'Créer une publication',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildMainContent(bool isMobile, bool isDesktop, double screenWidth) {
    return Center(
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
    );
  }

  Widget _buildCreatePostCard(bool isMobile) {
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
                Hero(
                  tag: 'user-avatar-${_user?.uid}',
                  child: CircleAvatar(
                    radius: isMobile ? 20 : 24,
                    backgroundColor: Colors.blue.shade100,
                    child:
                        _user?.photoURL != null
                            ? ClipOval(child: Image.network(_user!.photoURL!))
                            : Text(
                              _user?.email?.substring(0, 1).toUpperCase() ??
                                  'U',
                              style: const TextStyle(color: Colors.blue),
                            ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _showCreatePostDialog(context),
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
                _buildPostActionButton(
                  Iconsax.video,
                  'Vidéo',
                  Colors.red,
                  isMobile,
                  onTap: () {},
                ),
                _buildPostActionButton(
                  Iconsax.gallery,
                  'Photo',
                  Colors.green,
                  isMobile,
                  onTap: _pickImage,
                ),
                if (!isMobile)
                  _buildPostActionButton(
                    Iconsax.document,
                    'Fichier',
                    Colors.blue,
                    isMobile,
                    onTap: () {},
                  ),
                _buildPostActionButton(
                  Iconsax.activity,
                  'Sondage',
                  Colors.orange,
                  isMobile,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildPostItem(DocumentSnapshot post, bool isMobile) {
    final data = post.data() as Map<String, dynamic>;
    final likes = List<String>.from(data['likes'] ?? []);
    final comments = List<dynamic>.from(data['comments'] ?? []);
    final createdAt = data['createdAt'] as Timestamp?;
    final timeAgo =
        createdAt != null ? _getTimeAgo(createdAt.toDate()) : 'Récemment';

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
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.1),
              child:
                  data['userPhoto'] != null
                      ? ClipOval(child: Image.network(data['userPhoto']))
                      : Text(
                        data['userName'].substring(0, 1),
                        style: const TextStyle(color: Colors.blue),
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
              '$timeAgo • Public',
              style: TextStyle(fontSize: isMobile ? 12 : 14),
            ),
            trailing: IconButton(
              icon: Icon(Iconsax.more, size: isMobile ? 20 : 24),
              onPressed: () {},
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
                        child: const Center(child: Icon(Iconsax.gallery_slash)),
                      ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

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
                  '${comments.length}',
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
                    onPressed: () {},
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
  }

  Widget _buildPostActionButton(
    IconData icon,
    String label,
    Color color,
    bool isMobile, {
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      icon: Icon(icon, size: isMobile ? 20 : 24, color: color),
      label: Text(label, style: TextStyle(fontSize: isMobile ? 12 : 14)),
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.grey.shade700,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Créer une publication'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _postController,
                decoration: const InputDecoration(
                  hintText: 'Quoi de neuf ?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                minLines: 1,
              ),
              const SizedBox(height: 16),
              if (_imageFile != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_imageFile!),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => setState(() => _imageFile = null),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed:
                  _isLoading
                      ? null
                      : () async {
                        await _createPost();
                        if (mounted) Navigator.pop(context);
                      },
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Publier'),
            ),
          ],
        );
      },
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
}

class Badge extends StatelessWidget {
  final Widget child;
  final int count;

  const Badge.count({super.key, required this.count, required this.child});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0) ...[
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: BoxConstraints(
                minWidth: isMobile ? 16 : 18,
                minHeight: isMobile ? 16 : 18,
              ),
              child: Text(
                count > 9 ? '9+' : count.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 10 : 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
