import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'adaptive_drawer.dart';

/// Un Scaffold adaptable intégrant le Drawer, AppBar, et un FAB optionnel.
class AdaptiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final bool showSearch;
  final int notificationCount;
  final bool showFab;

  /// [title] : titre de l'AppBar
  /// [body] : contenu principal
  /// [showSearch] : afficher le bouton Search dans l'AppBar
  /// [notificationCount] : badge notifications
  /// [showFab] : afficher un FloatingActionButton
  const AdaptiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showSearch = false,
    this.notificationCount = 0,
    this.showFab = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      drawer: isMobile ? const AdaptiveDrawer() : null,
      appBar: AppBar(
        title: Text(title),
        centerTitle: false,
        leading:
            isDesktop
                ? IconButton(
                  icon: const Icon(Iconsax.menu_1),
                  onPressed: () {
                    // ouvre le drawer
                    Scaffold.of(context).openDrawer();
                  },
                )
                : null,
        actions: [
          // notifications
          IconButton(
            icon: Badge.count(
              count: notificationCount,
              child: const Icon(Iconsax.notification),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          if (showSearch && !isMobile) ...[
            IconButton(
              icon: const Icon(Iconsax.search_normal),
              onPressed: () {},
            ),
          ],
        ],
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: body,
      floatingActionButton:
          showFab
              ? FloatingActionButton(
                onPressed: () {
                  // action par défaut
                },
                child: const Icon(Iconsax.add),
                tooltip: 'Créer',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              )
              : null,
    );
  }
}

/// Widget Badge minimal
class Badge extends StatelessWidget {
  final Widget child;
  final int count;

  const Badge.count({super.key, required this.child, required this.count});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
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
