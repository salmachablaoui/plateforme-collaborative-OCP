import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'adaptive_drawer.dart'; // Import correct du drawer adaptatif
import 'profil.dart'; // Import de la page de profil

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
  final ScrollController _scrollController = ScrollController();
  final double _maxCardWidth = 600;
  final double _drawerWidth = 280;
  bool _isDrawerOpen = false;

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
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() => _isDrawerOpen = !_isDrawerOpen);
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      drawer:
          isMobile
              ? const AdaptiveDrawer()
              : null, // Utilisation du drawer adaptatif
      appBar: AppBar(
        title: const Text('Flux Collaboratif'),
        leading:
            isDesktop
                ? IconButton(
                  icon: const Icon(Iconsax.menu_1),
                  onPressed: _toggleDrawer,
                )
                : null,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Badge.count(
              count: 3,
              child: const Icon(Iconsax.notification),
            ),
            onPressed: () {},
          ),
          if (!isMobile) ...[
            IconButton(
              icon: const Icon(Iconsax.search_normal),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            _buildUserProfileButton(isMobile),
            const SizedBox(width: 12),
          ],
        ],
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: Stack(
        children: [
          _buildMainContent(isMobile, isDesktop, screenWidth),

          if (isDesktop && _isDrawerOpen) ...[
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: SizedBox(
                width: _drawerWidth,
                child: Card(
                  elevation: 8,
                  margin: EdgeInsets.zero,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: const AdaptiveDrawer(), // Drawer pour desktop
                ),
              ),
            ),

            if (_isDrawerOpen)
              GestureDetector(
                onTap: _toggleDrawer,
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
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
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildCreatePostCard(isMobile)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildPostItem(index, isMobile),
                  childCount: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileButton(bool isMobile) {
    return Tooltip(
      message: 'Profil',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _navigateToProfile,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Hero(
                tag: 'user-avatar-${_user?.uid}',
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.shade100,
                  child:
                      _user?.photoURL != null
                          ? ClipOval(child: Image.network(_user!.photoURL!))
                          : Text(
                            _user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(color: Colors.blue),
                          ),
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 8),
                Text(
                  _user?.displayName?.split(' ').first ?? 'Profil',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ],
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
                    onTap: () {},
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
                ),
                _buildPostActionButton(
                  Iconsax.gallery,
                  'Photo',
                  Colors.green,
                  isMobile,
                ),
                if (!isMobile)
                  _buildPostActionButton(
                    Iconsax.document,
                    'Fichier',
                    Colors.blue,
                    isMobile,
                  ),
                _buildPostActionButton(
                  Iconsax.activity,
                  'Sondage',
                  Colors.orange,
                  isMobile,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildPostActionButton(
    IconData icon,
    String label,
    Color color,
    bool isMobile,
  ) {
    return TextButton.icon(
      icon: Icon(icon, size: isMobile ? 20 : 24, color: color),
      label: Text(label, style: TextStyle(fontSize: isMobile ? 12 : 14)),
      onPressed: () {},
      style: TextButton.styleFrom(
        foregroundColor: Colors.grey.shade700,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
      ),
    );
  }

  Widget _buildPostItem(int index, bool isMobile) {
    final authors = [
      'Marie Dupont',
      'Jean Martin',
      'Sophie Leroy',
      'Thomas Richard',
      'Élodie Moreau',
    ];
    final contents = [
      'Nous venons de lancer notre nouveau projet! Qui veut rejoindre l\'équipe?',
      'Je partage les résultats de notre dernière étude. Des questions?',
      'Quelqu\'un aurait des ressources pour la gestion de projet agile?',
      'Besoin de feedback sur le nouveau design. Merci pour vos retours!',
      'Qui sera disponible pour une session de brainstorming demain?',
    ];
    final times = ['10 min', '25 min', '1h', '3h', '5h', '1j', '2j', '1 sem'];
    final likes = [12, 45, 8, 23, 17];
    final comments = [3, 7, 1, 5, 2];
    final shares = [1, 3, 0, 2, 1];

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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              dense: isMobile,
              leading: CircleAvatar(
                backgroundColor: Colors
                    .primaries[index % Colors.primaries.length]
                    .withOpacity(0.1),
                child: Text(
                  authors[index % authors.length].substring(0, 1),
                  style: TextStyle(
                    color: Colors.primaries[index % Colors.primaries.length],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                authors[index % authors.length],
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
              subtitle: Text(
                '${times[index % times.length]} • Public',
                style: TextStyle(fontSize: isMobile ? 12 : 14),
              ),
              trailing: IconButton(
                icon: Icon(Iconsax.more, size: isMobile ? 20 : 24),
                onPressed: () {},
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                0,
                isMobile ? 16 : 24,
                isMobile ? 8 : 12,
              ),
              child: Text(
                contents[index % contents.length],
                style: TextStyle(fontSize: isMobile ? 14 : 16),
              ),
            ),

            if (index % 2 == 0) ...[
              Container(
                height: isMobile ? 180 : 240,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://picsum.photos/800/400?random=$index',
                    ),
                    fit: BoxFit.cover,
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
                    '${likes[index % likes.length]}',
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
                    '${comments[index % comments.length]}',
                    style: TextStyle(fontSize: isMobile ? 12 : 14),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Iconsax.send_2,
                    size: isMobile ? 16 : 18,
                    color: Colors.purple.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${shares[index % shares.length]}',
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
                      icon: Icon(Iconsax.like_1, size: isMobile ? 18 : 20),
                      label: Text(
                        'J\'aime',
                        style: TextStyle(fontSize: isMobile ? 12 : 14),
                      ),
                      onPressed: () {},
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
      ),
    );
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
