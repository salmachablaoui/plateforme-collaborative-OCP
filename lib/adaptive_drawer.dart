import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

class AdaptiveDrawer extends StatelessWidget {
  const AdaptiveDrawer({super.key});

  // Couleurs corporate OCP
  static const primaryColor = Color(0xFF2F9D4E);
  static const primaryDark = Color(0xFF1E8449);
  static const primaryLight = Color(0xFFE8F5E9);
  static const accentColor = Color(0xFFF7931E);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final bool isDesktop = MediaQuery.of(context).size.width >= 768;
    final bool isTablet = MediaQuery.of(context).size.width >= 600;

    return Drawer(
      width:
          isDesktop
              ? 300
              : (isTablet ? 260 : MediaQuery.of(context).size.width * 0.8),
      backgroundColor: Colors.white,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header avec photo de profil
          _buildHeader(context, user),

          // Section de navigation principale
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    _buildNavigationSection(),
                    _buildToolsSection(),
                    _buildSupportSection(),
                  ]),
                ),
              ],
            ),
          ),

          // Footer avec déconnexion
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User? user) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryDark, primaryColor],
        ),
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Effet de bulles décoratives
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),

          // Contenu du header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar avec badge de statut
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.network(
                            user?.photoURL ?? 'https://i.imgur.com/Qy1K5Z0.png',
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => Icon(
                                  Iconsax.user,
                                  size: 36,
                                  color: Colors.white,
                                ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(duration: 400.ms).shake(delay: 300.ms),

                const SizedBox(height: 16),
                Text(
                  user?.displayName ?? 'Collaborateur OCP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'user@ocpgroup.ma',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Niveau 3 - Accès complet',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSection() {
    return _Section(
      title: "NAVIGATION",
      children: [
        _DrawerTile(
          icon: Iconsax.home,
          activeIcon: Iconsax.home_25,
          title: "Tableau de bord",
          route: "/home",
          isActive: true,
          notificationCount: 0,
        ),
        _DrawerTile(
          icon: Iconsax.people,
          activeIcon: Iconsax.people5,
          title: "Mon réseau",
          route: "/network",
          notificationCount: 3,
        ),
        _DrawerTile(
          icon: Iconsax.message,
          activeIcon: Iconsax.message5,
          title: "Messagerie",
          route: "/messages",
          notificationCount: 5,
        ),
        _DrawerTile(
          icon: Iconsax.document,
          activeIcon: Iconsax.document5,
          title: "Documents partagés",
          route: "/documents",
        ),
      ],
    );
  }

  Widget _buildToolsSection() {
    return _Section(
      title: "OUTILS COLLABORATIFS",
      children: [
        _DrawerTile(
          icon: Iconsax.calendar,
          activeIcon: Iconsax.calendar_2,
          title: "Agenda d'équipe",
          route: "/calendar",
        ),
        _DrawerTile(
          icon: Iconsax.task,
          activeIcon: Iconsax.task_square,
          title: "Gestion de projets",
          route: "/projects",
        ),
        _DrawerTile(
          icon: Iconsax.chart,
          activeIcon: Iconsax.chart_2,
          title: "Tableaux de bord",
          route: "/dashboards",
        ),
        _DrawerTile(
          icon: Iconsax.video,
          activeIcon: Iconsax.video_play,
          title: "Réunions virtuelles",
          route: "/meetings",
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return _Section(
      title: "SUPPORT & PARAMÈTRES",
      children: [
        _DrawerTile(
          icon: Iconsax.setting,
          activeIcon: Iconsax.setting_2,
          title: "Paramètres du compte",
          route: "/settings",
        ),
        _DrawerTile(
          icon: Iconsax.shield,
          activeIcon: Iconsax.shield_tick,
          title: "Sécurité",
          route: "/security",
        ),
        _DrawerTile(
          icon: Iconsax.info_circle,
          activeIcon: Iconsax.info_circle5,
          title: "Centre d'aide",
          route: "/help",
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
            label: const Text("Déconnexion"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red,
              elevation: 0,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: () => _showLogoutDialog(context),
          ),
          const SizedBox(height: 8),
          Text(
            "v2.4.1 • © OCP ${DateTime.now().year}",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Déconnexion"),
            content: const Text(
              "Êtes-vous sûr de vouloir vous déconnecter de l'application ?",
            ),
            actions: [
              TextButton(
                child: const Text("Annuler"),
                onPressed: () => Navigator.pop(ctx),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Déconnecter"),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.popUntil(ctx, (route) => route.isFirst);
                  Navigator.pushReplacementNamed(ctx, '/login');
                },
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            title,
            style: TextStyle(
              color: AdaptiveDrawer.primaryDark.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        dense: true,
        leading: AnimatedContainer(
          duration: 300.ms,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color:
                isActive
                    ? AdaptiveDrawer.primaryColor.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isActive ? activeIcon : icon,
            size: 20,
            color:
                isActive ? AdaptiveDrawer.primaryColor : Colors.grey.shade700,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? AdaptiveDrawer.primaryDark : Colors.grey.shade800,
          ),
        ),
        trailing:
            notificationCount != null && notificationCount! > 0
                ? Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    notificationCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                )
                : null,
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, route);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ).animate().fadeIn().slideX(begin: 0.1),
    );
  }
}
