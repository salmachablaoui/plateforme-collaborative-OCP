import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:app_stage/views/profil.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final User? user;
  final bool showSearchButton;
  final bool showNotifications;
  final List<Widget>? additionalActions;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.scaffoldKey,
    this.user,
    this.showSearchButton = true,
    this.showNotifications = true,
    this.additionalActions,
  });

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
        _buildProfileButton(isMobile),
        if (!isMobile) const SizedBox(width: 12),
      ],
      elevation: 0,
      scrolledUnderElevation: 1,
    );
  }

  Widget _buildNotificationButton() {
    return IconButton(
      icon: Badge.count(count: 3, child: const Icon(Iconsax.notification)),
      onPressed: () {
        Navigator.pushNamed(scaffoldKey.currentContext!, '/notifications');
      },
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

  Widget _buildProfileButton(bool isMobile) {
    return Tooltip(
      message: 'Profil',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap:
            () => Navigator.push(
              scaffoldKey.currentContext!,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(user: user),
              ),
            ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Hero(
                tag: 'user-avatar-${user?.uid ?? 'default'}',
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.shade100,
                  child:
                      user?.photoURL != null
                          ? ClipOval(child: Image.network(user!.photoURL!))
                          : Text(
                            user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(color: Colors.blue),
                          ),
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 8),
                Text(
                  user?.displayName?.split(' ').first ?? 'Profil',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      ),
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
