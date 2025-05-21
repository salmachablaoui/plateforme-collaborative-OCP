import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class NavigationProvider extends ChangeNotifier {
  String _currentRoute = '/home';

  String get currentRoute => _currentRoute;

  void navigateTo(String route) {
    _currentRoute = route;
    notifyListeners();
  }
}

class AdaptiveDrawer extends StatefulWidget {
  // Couleurs corporate
  static const primaryColor = Color(0xFF2F9D4E);
  static const primaryDark = Color(0xFF1E8449);
  static const primaryLight = Color(0xFFE8F5E9);
  static const accentColor = Color(0xFFF7931E);

  const AdaptiveDrawer({super.key});

  @override
  State<AdaptiveDrawer> createState() => _AdaptiveDrawerState();
}

class _AdaptiveDrawerState extends State<AdaptiveDrawer> {
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (doc.exists) {
        setState(() {
          _userData = doc.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement données utilisateur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ImageProvider? _getProfileImage() {
    try {
      if (_userData['photoBase64']?.isNotEmpty == true) {
        final base64String = _userData['photoBase64'].split(',').last;
        return MemoryImage(base64Decode(base64String));
      }
      return null;
    } catch (e) {
      debugPrint('Erreur chargement image: $e');
      return null;
    }
  }

  String _getInitials() {
    final name =
        _userData['fullName'] ??
        FirebaseAuth.instance.currentUser?.displayName ??
        'Utilisateur';
    return name.isNotEmpty
        ? name.split(' ').map((n) => n[0]).take(2).join().toUpperCase()
        : '?';
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 768;
    final bool isTablet = MediaQuery.sizeOf(context).width >= 600;

    return Drawer(
      width:
          isDesktop
              ? 300
              : (isTablet ? 260 : MediaQuery.sizeOf(context).width * 0.8),
      backgroundColor: Colors.white,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(context, user),
          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: 8),
                _buildMainSection(context),
                _buildSecondarySection(context),
              ],
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AdaptiveDrawer.primaryColor,
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: AdaptiveDrawer.primaryDark.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AdaptiveDrawer.primaryDark.withOpacity(0.2),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor:
                            _getProfileImage() == null
                                ? AdaptiveDrawer.primaryLight
                                : Colors.transparent,
                        backgroundImage: _getProfileImage(),
                        child:
                            _getProfileImage() == null
                                ? Text(
                                  _getInitials(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: AdaptiveDrawer.primaryDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ).animate().scale(duration: 400.ms).shake(delay: 300.ms),
                  const SizedBox(height: 12),
                  Text(
                    _userData['fullName'] ?? user?.displayName ?? 'Utilisateur',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'user@example.com',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Les autres méthodes (_buildMainSection, _buildSecondarySection, _buildFooter)
  // restent exactement les mêmes que dans votre code original
  // ...

  Widget _buildMainSection(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final String currentRoute = navProvider.currentRoute;

    return _Section(
      title: 'MENU PRINCIPAL',
      children: [
        _DrawerTile(
          icon: Iconsax.home,
          activeIcon: Iconsax.home_25,
          title: 'Accueil',
          route: '/home',
          isActive: currentRoute == '/home',
        ),
        _DrawerTile(
          icon: Iconsax.notification,
          activeIcon: Iconsax.notification5,
          title: 'Notifications',
          route: '/notifications',
          isActive: currentRoute == '/notifications',
        ),
        _DrawerTile(
          icon: Iconsax.profile_2user,
          activeIcon: Iconsax.profile_2user5,
          title: 'Amis',
          route: '/friends',
          isActive: currentRoute == '/friends',
        ),
        _DrawerTile(
          icon: Iconsax.message,
          activeIcon: Iconsax.message5,
          title: 'Chatrooms',
          route: '/chatrooms',
          isActive: currentRoute == '/chatrooms',
        ),
        _DrawerTile(
          icon: Iconsax.calendar,
          activeIcon: Iconsax.calendar_2,
          title: 'Agenda',
          route: '/calendar',
          isActive: currentRoute == '/calendar',
        ),
      ],
    );
  }

  Widget _buildSecondarySection(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final String currentRoute = navProvider.currentRoute;

    return _Section(
      title: 'PARAMÈTRES',
      children: [
        _DrawerTile(
          icon: Iconsax.setting,
          activeIcon: Iconsax.setting_2,
          title: 'Paramètres',
          route: '/settings',
          isActive: currentRoute == '/settings',
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Iconsax.logout, size: 18),
            label: const Text('Déconnexion'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.popUntil(context, (route) => route.isFirst);
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          const SizedBox(height: 8),
          Text(
            'v1.0.0 • © ${DateTime.now().year}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AdaptiveDrawer.primaryDark.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        ...children,
      ],
    ),
  );
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String title;
  final String route;
  final bool isActive;
  final int? notificationCount;

  const _DrawerTile({
    required this.icon,
    required this.activeIcon,
    required this.title,
    required this.route,
    this.isActive = false,
    this.notificationCount,
  });

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    return ListTile(
      leading: Stack(
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: isActive ? AdaptiveDrawer.primaryColor : Colors.black54,
            size: 24,
          ),
          if (notificationCount != null && notificationCount! > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Center(
                  child: Text(
                    '$notificationCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? AdaptiveDrawer.primaryColor : Colors.black87,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      minLeadingWidth: 30,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      onTap: () {
        navProvider.navigateTo(route);
        Navigator.pop(context);
        Navigator.pushReplacementNamed(context, route);
      },
    );
  }
}
