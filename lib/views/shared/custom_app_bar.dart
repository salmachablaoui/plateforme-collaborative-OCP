import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:app_stage/views/profil.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final User? user;
  final bool showSearchButton;
  final bool showNotifications;
  final List<Widget>? additionalActions;
  final int unreadNotificationsCount; // Ajoutez ce paramètre

  const CustomAppBar({
    super.key,
    required this.title,
    required this.scaffoldKey,
    this.user,
    this.showSearchButton = true,
    this.showNotifications = true,
    this.additionalActions,
    this.unreadNotificationsCount = 0, // Valeur par défaut
  });

  Widget _buildNotificationButton() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Iconsax.notification),
          onPressed: () {
            Navigator.pushNamed(scaffoldKey.currentContext!, '/notifications');
          },
        ),
        if (unreadNotificationsCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unreadNotificationsCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return AppBar(
      title: Text(title),
      toolbarHeight: 56,
      leading: IconButton(
        icon: const Icon(Iconsax.menu_1),
        onPressed: _toggleDrawer,
      ),
      centerTitle: false,
      actions: [
        if (showNotifications) _buildNotificationButton(),
        if (showSearchButton && !isMobile) _buildSearchButton(),
        ...?additionalActions,
        _buildProfileButton(context, isMobile),
        if (!isMobile) const SizedBox(width: 12),
      ],
      elevation: 0,
      scrolledUnderElevation: 1,
    );
  }

  Widget _buildProfileButton(BuildContext context, bool isMobile) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchUserData(),
      builder: (context, snapshot) {
        final userData = snapshot.data ?? {};
        final photoUrl = userData['photoBase64'] ?? user?.photoURL;
        final displayName =
            userData['fullName'] ??
            user?.displayName?.split(' ').first ??
            'Profil';

        return Tooltip(
          message: 'Profil',
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _navigateToProfile(context),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildProfileAvatar(photoUrl),
                  if (!isMobile) ...[
                    const SizedBox(width: 8),
                    Text(displayName, style: const TextStyle(fontSize: 14)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(String? photoUrl) {
    return Hero(
      tag: 'appbar-profile-${user?.uid ?? 'default'}',
      child: Material(
        color: Colors.transparent,
        child: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.blue.shade100,
          backgroundImage: _getImageProvider(photoUrl),
          child:
              _getImageProvider(photoUrl) == null
                  ? Text(
                    user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(color: Colors.blue),
                  )
                  : null,
        ),
      ),
    );
  }

  ImageProvider? _getImageProvider(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;

    try {
      if (photoUrl.startsWith('data:image')) {
        final base64String = photoUrl.split(',').last;
        return MemoryImage(base64.decode(base64String));
      }
      return NetworkImage(photoUrl);
    } catch (e) {
      debugPrint('Error loading profile image: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _fetchUserData() async {
    if (user == null) return {};

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .get();

      return doc.data() ?? {};
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return {};
    }
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen(user: user)),
    );
  }

  Widget _buildSearchButton() {
    return IconButton(
      icon: const Icon(Iconsax.search_normal),
      onPressed: () {
        showSearch(
          context: scaffoldKey.currentContext!,
          delegate: CustomSearchDelegate(),
        );
      },
    );
  }

  void _toggleDrawer() {
    if (scaffoldKey.currentState?.isDrawerOpen ?? false) {
      scaffoldKey.currentState?.closeDrawer();
    } else {
      scaffoldKey.currentState?.openDrawer();
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

class CustomSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Iconsax.close_circle),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Iconsax.arrow_left),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(child: Text('Résultats pour: $query'));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(child: Text('Suggestions de recherche'));
  }
}
