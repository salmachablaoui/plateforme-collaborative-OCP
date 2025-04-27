import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key}); // Constructeur const présent

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  String _displayName = '';
  String _phoneNumber = '';
  String _department = '';
  String _position = '';
  String _bio = '';

  @override
  void initState() {
    super.initState();
    _displayName = user?.displayName ?? '';
    _phoneNumber = user?.phoneNumber ?? '';
    _department = 'Département IT';
    _position = 'Chef de projet';
    _bio = 'Spécialiste en développement d\'applications collaboratives';
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Iconsax.save_2 : Iconsax.edit_2),
            onPressed: () {
              if (_isEditing) {
                if (_formKey.currentState != null &&
                    _formKey.currentState!.validate()) {
                  _saveProfile();
                }
              }
              setState(() => _isEditing = !_isEditing);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                _buildProfileHeader(isMobile),
                const SizedBox(height: 24),
                _buildProfileForm(isMobile),
                if (!_isEditing) ...[
                  const SizedBox(height: 32),
                  _buildStatsSection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isMobile) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: isMobile ? 120 : 150,
              height: isMobile ? 120 : 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade100, width: 3),
              ),
              child: ClipOval(
                child: Image.network(
                  user?.photoURL ?? 'https://i.imgur.com/Qy1K5Z0.png',
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Icon(
                        Iconsax.user,
                        size: 40,
                        color: Colors.blue.shade300,
                      ),
                ),
              ),
            ).animate().scale(duration: 500.ms),
            if (_isEditing)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: IconButton(
                  icon: const Icon(
                    Iconsax.camera,
                    size: 18,
                    color: Colors.white,
                  ),
                  onPressed: _changeProfilePicture,
                ),
              ),
          ],
        ),
        if (!_isEditing) ...[
          const SizedBox(height: 16),
          Text(
            _displayName,
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            _position,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: isMobile ? 14 : 16,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProfileForm(bool isMobile) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildEditableField(
            label: 'Nom complet',
            value: _displayName,
            icon: Iconsax.user,
            isEditing: _isEditing,
            onChanged: (value) => _displayName = value,
          ),
          _buildEditableField(
            label: 'Email',
            value: user?.email ?? 'Non défini',
            icon: Iconsax.sms,
            isEditing: false,
          ),
          _buildEditableField(
            label: 'Téléphone',
            value: _phoneNumber,
            icon: Iconsax.call,
            isEditing: _isEditing,
            onChanged: (value) => _phoneNumber = value,
            validator:
                (value) =>
                    value != null && value.length < 8
                        ? 'Numéro invalide'
                        : null,
          ),
          _buildEditableField(
            label: 'Département',
            value: _department,
            icon: Iconsax.building_3,
            isEditing: _isEditing,
            onChanged: (value) => _department = value,
          ),
          _buildEditableField(
            label: 'Poste',
            value: _position,
            icon: Iconsax.briefcase,
            isEditing: _isEditing,
            onChanged: (value) => _position = value,
          ),
          _buildBioField(),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required IconData icon,
    required bool isEditing,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: value,
        enabled: isEditing,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: !isEditing,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildBioField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: _bio,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Bio',
          alignLabelWithHint: true,
          prefixIcon: const Icon(Iconsax.note_text),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabled: _isEditing,
          filled: !_isEditing,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: (value) => _bio = value,
      ),
    );
  }

  Widget _buildStatsSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Projets', '12', Iconsax.task),
            _buildStatItem('Collègues', '45', Iconsax.people),
            _buildStatItem('Années', '3', Iconsax.calendar_1),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blue.shade600),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  void _changeProfilePicture() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Changer de photo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Iconsax.camera),
                  title: const Text('Prendre une photo'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Iconsax.gallery),
                  title: const Text('Choisir depuis la galerie'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _saveProfile() async {
    try {
      await user?.updateDisplayName(_displayName);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
