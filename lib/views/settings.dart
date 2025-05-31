import 'package:app_stage/views/shared/adaptive_drawer.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_stage/views/shared/custom_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  String _language = 'Français';
  String _themeColor = 'Vert';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  User? get _currentUser => _user;
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _language = prefs.getString('language') ?? 'Français';
      _themeColor = prefs.getString('themeColor') ?? 'Vert';
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  void _changeThemeMode(bool value) {
    setState(() => _darkMode = value);
    _savePreference('darkMode', value);
  }

  void _changeLanguage(String? value) {
    if (value == null) return;
    setState(() => _language = value);
    _savePreference('language', value);
  }

  void _changeThemeColor(String? value) {
    if (value == null) return;
    setState(() => _themeColor = value);
    _savePreference('themeColor', value);
  }

  void _toggleNotifications(bool value) {
    setState(() => _notificationsEnabled = value);
    _savePreference('notifications', value);
  }

  Future<void> _changePassword() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _user?.email ?? '',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lien de réinitialisation envoyé par email'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Déconnexion'),
            content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('Déconnexion'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AdaptiveDrawer(),
      appBar: CustomAppBar(
        title: 'Paramètres',
        scaffoldKey: _scaffoldKey,
        user: _currentUser,
        showSearchButton: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.green, // Changé en vert
                      child: Icon(Iconsax.user, size: 40, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userData['fullName'] ??
                                FirebaseAuth
                                    .instance
                                    .currentUser
                                    ?.displayName ??
                                'Utilisateur',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _user?.email ?? 'john.doe@example.com',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Iconsax.edit, size: 16),
                            label: const Text('Modifier le profil'),
                            onPressed:
                                () => Navigator.pushNamed(
                                  context,
                                  '/profile-edit',
                                ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green, // Couleur verte
                              side: const BorderSide(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // App Settings
            _buildSectionHeader('PRÉFÉRENCES DE L\'APPLICATION'),
            _buildSettingSwitch(
              title: 'Mode sombre',
              value: _darkMode,
              icon: Iconsax.moon,
              onChanged: _changeThemeMode,
            ),
            _buildSettingDropdown(
              title: 'Langue',
              value: _language,
              icon: Iconsax.language_circle,
              items: const ['Français', 'Anglais', 'Espagnol', 'Arabe'],
              onChanged: _changeLanguage,
            ),
            _buildSettingDropdown(
              title: 'Couleur du thème',
              value: _themeColor,
              icon: Iconsax.colorfilter,
              items: const ['Vert', 'Bleu', 'Violet', 'Rouge', 'Orange'],
              onChanged: _changeThemeColor,
            ),
            _buildSettingSwitch(
              title: 'Notifications',
              value: _notificationsEnabled,
              icon: Iconsax.notification,
              onChanged: _toggleNotifications,
            ),
            const SizedBox(height: 24),

            // Security Settings
            _buildSectionHeader('SÉCURITÉ'),
            _buildSettingTile(
              title: 'Changer le mot de passe',
              icon: Iconsax.lock,
              onTap: _changePassword,
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Iconsax.logout),
                label: const Text('Déconnexion'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _confirmLogout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1), // Changé en vert
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.green), // Changé en vert
      ),
      title: Text(title),
      trailing: const Icon(Iconsax.arrow_right_3),
      onTap: onTap,
    );
  }

  Widget _buildSettingSwitch({
    required String title,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1), // Changé en vert
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.green), // Changé en vert
      ),
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildSettingDropdown({
    required String title,
    required String value,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1), // Changé en vert
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.green), // Changé en vert
      ),
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items:
            items.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
