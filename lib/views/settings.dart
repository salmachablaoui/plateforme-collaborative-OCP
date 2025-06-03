import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_stage/views/shared/adaptive_drawer.dart';
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
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadUserData();
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

  Future<void> _loadUserData() async {
    if (_user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .get();

      if (doc.exists) {
        setState(() {
          _userData = doc.data() ?? {};
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement données utilisateur: $e');
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AdaptiveDrawer(),
      appBar: CustomAppBar(
        title: 'Paramètres',
        scaffoldKey: _scaffoldKey,
        user: _user,
        showSearchButton: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600, minHeight: screenHeight),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: isSmallScreen ? 32 : 40,
                          backgroundColor: Colors.green,
                          backgroundImage: _getProfileImage(),
                          child:
                              _getProfileImage() == null
                                  ? Icon(
                                    Iconsax.user,
                                    size: isSmallScreen ? 32 : 40,
                                    color: Colors.white,
                                  )
                                  : null,
                        ),
                        SizedBox(width: isSmallScreen ? 12 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userData['fullName'] ??
                                    _user?.displayName ??
                                    'Utilisateur',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 18 : null,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                _user?.email ?? 'john.doe@example.com',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  fontSize: isSmallScreen ? 14 : null,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              OutlinedButton.icon(
                                icon: Icon(
                                  Iconsax.edit,
                                  size: isSmallScreen ? 14 : 16,
                                ),
                                label: Text(
                                  'Modifier le profil',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : null,
                                  ),
                                ),
                                onPressed:
                                    () => Navigator.pushNamed(
                                      context,
                                      '/profile-edit',
                                    ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green,
                                  side: const BorderSide(color: Colors.green),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 8 : 12,
                                    vertical: isSmallScreen ? 6 : 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // App Settings
                _buildSectionHeader('PRÉFÉRENCES DE L\'APPLICATION'),
                _buildSettingSwitch(
                  title: 'Mode sombre',
                  value: _darkMode,
                  icon: Iconsax.moon,
                  onChanged: _changeThemeMode,
                  isSmallScreen: isSmallScreen,
                ),
                _buildSettingDropdown(
                  title: 'Langue',
                  value: _language,
                  icon: Iconsax.language_circle,
                  items: const ['Français', 'Anglais', 'Espagnol', 'Arabe'],
                  onChanged: _changeLanguage,
                  isSmallScreen: isSmallScreen,
                ),
                _buildSettingDropdown(
                  title: 'Couleur du thème',
                  value: _themeColor,
                  icon: Iconsax.colorfilter,
                  items: const ['Vert', 'Bleu', 'Violet', 'Rouge', 'Orange'],
                  onChanged: _changeThemeColor,
                  isSmallScreen: isSmallScreen,
                ),
                _buildSettingSwitch(
                  title: 'Notifications',
                  value: _notificationsEnabled,
                  icon: Iconsax.notification,
                  onChanged: _toggleNotifications,
                  isSmallScreen: isSmallScreen,
                ),
                SizedBox(height: screenHeight * 0.02),

                // Security Settings
                _buildSectionHeader('SÉCURITÉ'),
                _buildSettingTile(
                  title: 'Changer le mot de passe',
                  icon: Iconsax.lock,
                  onTap: _changePassword,
                  isSmallScreen: isSmallScreen,
                ),
                SizedBox(height: screenHeight * 0.02),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(Iconsax.logout, size: isSmallScreen ? 18 : 20),
                    label: Text(
                      'Déconnexion',
                      style: TextStyle(fontSize: isSmallScreen ? 16 : null),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 12 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _confirmLogout,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
    required bool isSmallScreen,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 8),
      leading: Container(
        width: isSmallScreen ? 36 : 40,
        height: isSmallScreen ? 36 : 40,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.green, size: isSmallScreen ? 18 : 20),
      ),
      title: Text(title, style: TextStyle(fontSize: isSmallScreen ? 16 : null)),
      trailing: Icon(Iconsax.arrow_right_3, size: isSmallScreen ? 18 : 20),
      onTap: onTap,
    );
  }

  Widget _buildSettingSwitch({
    required String title,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
    required bool isSmallScreen,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 8),
      secondary: Container(
        width: isSmallScreen ? 36 : 40,
        height: isSmallScreen ? 36 : 40,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.green, size: isSmallScreen ? 18 : 20),
      ),
      title: Text(title, style: TextStyle(fontSize: isSmallScreen ? 16 : null)),
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
    required bool isSmallScreen,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 8),
      leading: Container(
        width: isSmallScreen ? 36 : 40,
        height: isSmallScreen ? 36 : 40,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.green, size: isSmallScreen ? 18 : 20),
      ),
      title: Text(title, style: TextStyle(fontSize: isSmallScreen ? 16 : null)),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items:
            items.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(fontSize: isSmallScreen ? 14 : null),
                ),
              );
            }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
