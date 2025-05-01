import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:app_stage/views/shared/adaptive_drawer.dart';
import 'shared/custom_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  bool _biometricAuth = false;
  String _language = 'Français';
  String _themeColor = 'Vert';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AdaptiveDrawer(),
      appBar: CustomAppBar(
        title: 'Paramètres',
        scaffoldKey: _scaffoldKey,
        user: _user,
        //showBackButton: true,
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
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue,
                      child: Icon(Iconsax.user, size: 40, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'John Doe',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'john.doe@example.com',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Iconsax.edit, size: 16),
                            label: const Text('Modifier le profil'),
                            onPressed: () => _navigateTo('/profile-edit'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AdaptiveDrawer.primaryColor,
                              side: BorderSide(
                                color: AdaptiveDrawer.primaryColor,
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
            const SizedBox(height: 24),

            // App Settings
            _buildSectionHeader('PRÉFÉRENCES DE L\'APPLICATION'),
            _buildSettingSwitch(
              title: 'Mode sombre',
              value: _darkMode,
              icon: Iconsax.moon,
              onChanged: (value) => setState(() => _darkMode = value),
            ),
            _buildSettingDropdown(
              title: 'Langue',
              value: _language,
              icon: Iconsax.language_circle,
              items: const ['Français', 'Anglais', 'Espagnol', 'Arabe'],
              onChanged: (value) => setState(() => _language = value!),
            ),
            _buildSettingDropdown(
              title: 'Couleur du thème',
              value: _themeColor,
              icon: Iconsax.colorfilter,
              items: const ['Vert', 'Bleu', 'Violet', 'Rouge', 'Orange'],
              onChanged: (value) => setState(() => _themeColor = value!),
            ),
            _buildSettingSwitch(
              title: 'Notifications',
              value: _notificationsEnabled,
              icon: Iconsax.notification,
              onChanged:
                  (value) => setState(() => _notificationsEnabled = value),
            ),
            const SizedBox(height: 24),

            // Security Settings
            _buildSectionHeader('SÉCURITÉ'),
            _buildSettingSwitch(
              title: 'Authentification biométrique',
              value: _biometricAuth,
              icon: Iconsax.finger_cricle,
              onChanged: (value) => setState(() => _biometricAuth = value),
            ),
            _buildSettingTile(
              title: 'Changer le mot de passe',
              icon: Iconsax.lock,
              onTap: () => _navigateTo('/change-password'),
            ),
            _buildSettingTile(
              title: 'Authentification à deux facteurs',
              icon: Iconsax.shield,
              onTap: () => _navigateTo('/two-factor-auth'),
            ),
            const SizedBox(height: 24),

            // Help & Support
            _buildSectionHeader('AIDE & SUPPORT'),
            _buildSettingTile(
              title: 'Centre d\'aide',
              icon: Iconsax.message_question,
              onTap: () => _navigateTo('/help-center'),
            ),
            _buildSettingTile(
              title: 'Nous contacter',
              icon: Iconsax.message,
              onTap: () => _navigateTo('/contact-us'),
            ),
            _buildSettingTile(
              title: 'Conditions d\'utilisation',
              icon: Iconsax.document,
              onTap: () => _navigateTo('/terms'),
            ),
            _buildSettingTile(
              title: 'Politique de confidentialité',
              icon: Iconsax.lock,
              onTap: () => _navigateTo('/privacy'),
            ),
            const SizedBox(height: 24),

            // Logout Button
            _buildLogoutButton(),
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
          color: AdaptiveDrawer.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AdaptiveDrawer.primaryColor),
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
          color: AdaptiveDrawer.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AdaptiveDrawer.primaryColor),
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
          color: AdaptiveDrawer.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AdaptiveDrawer.primaryColor),
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

  Widget _buildLogoutButton() {
    return SizedBox(
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
    );
  }

  void _navigateTo(String route) {
    Navigator.pushNamed(context, route);
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
                  // TODO: Implement logout
                  Navigator.popUntil(context, ModalRoute.withName('/login'));
                },
                child: const Text('Déconnexion'),
              ),
            ],
          ),
    );
  }
}
