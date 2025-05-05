import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';

class ProfileScreen extends StatefulWidget {
  final User? user;

  const ProfileScreen({super.key, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> _userData;
  bool _isLoading = true;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;

  @override
  void initState() {
    super.initState();
    _userData = {
      'fullName': 'Chargement...',
      'email': widget.user?.email ?? '',
      'department': '',
      'phone': '',
    };
    _fullNameController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (widget.user == null) return;

    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.user!.uid)
              .get();

      if (doc.exists) {
        setState(() {
          _userData = {
            'fullName': doc['fullName'] ?? 'Non spécifié',
            'email': doc['email'] ?? widget.user?.email ?? 'Non spécifié',
            'department': doc['department'] ?? 'Non spécifié',
            'phone': doc['phone'] ?? 'Non spécifié',
          };
          _fullNameController.text = _userData['fullName'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _userData['fullName'] = 'Non trouvé';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _userData['fullName'] = 'Erreur de chargement';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditing ? Iconsax.save_2 : Iconsax.edit_2),
              onPressed: _toggleEditMode,
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildProfileForm(),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage:
              widget.user?.photoURL != null
                  ? CachedNetworkImageProvider(widget.user!.photoURL!)
                  : null,
          child:
              widget.user?.photoURL == null
                  ? const Icon(Iconsax.user, size: 40)
                  : null,
        ),
        const SizedBox(height: 16),
        Text(
          _userData['fullName'],
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildInfoTile(
            icon: Iconsax.user,
            label: 'Nom complet',
            value: _userData['fullName'],
            controller: _fullNameController,
          ),
          const Divider(),
          _buildInfoTile(
            icon: Iconsax.sms,
            label: 'Email',
            value: _userData['email'],
          ),
          const Divider(),
          _buildInfoTile(
            icon: Iconsax.building,
            label: 'Département',
            value: _userData['department'],
          ),
          const Divider(),
          _buildInfoTile(
            icon: Iconsax.call,
            label: 'Téléphone',
            value: _userData['phone'],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    TextEditingController? controller,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title:
          _isEditing && controller != null
              ? TextFormField(
                controller: controller,
                decoration: InputDecoration(labelText: label),
                validator:
                    (value) =>
                        value?.isEmpty ?? true ? 'Ce champ est requis' : null,
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle:
                          (value == 'Non spécifié' || value == 'Non trouvé')
                              ? FontStyle.italic
                              : FontStyle.normal,
                      color:
                          (value == 'Non spécifié' || value == 'Non trouvé')
                              ? Colors.grey
                              : Colors.black,
                    ),
                  ),
                ],
              ),
    );
  }

  void _toggleEditMode() async {
    if (_isEditing) {
      if (_formKey.currentState!.validate()) {
        setState(() => _isLoading = true);
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.user!.uid)
              .update({
                'fullName': _fullNameController.text,
                'updatedAt': FieldValue.serverTimestamp(),
              });
          await _loadUserData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil mis à jour avec succès')),
          );
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
        } finally {
          setState(() => _isLoading = false);
        }
      }
    }
    setState(() => _isEditing = !_isEditing);
  }
}
