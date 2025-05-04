import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firestore_service.dart'; // ajuste le chemin si besoin

class ProfileScreen extends StatefulWidget {
  final User? user;

  const ProfileScreen({super.key, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  late String _displayName;
  late String _position;

  final _firestore = FirestoreService();

  @override
  void initState() {
    super.initState();
    _displayName = widget.user?.displayName ?? 'Nom non défini';
    _position = 'Chargement...';
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (widget.user == null) return;

    final doc = await _firestore.getDocument(
      collection: 'users',
      docId: widget.user!.uid,
    );

    setState(() {
      _displayName = doc?['name'] ?? _displayName;
      _position = doc?['position'] ?? 'Position non définie';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return const Scaffold(
        body: Center(child: Text('Veuillez vous connecter')),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Iconsax.save_2 : Iconsax.edit_2),
            onPressed: _toggleEditMode,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Center(
          child: Column(
            children: [
              _buildProfileHeader(isMobile),
              const SizedBox(height: 24),
              _buildProfileForm(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(bool isMobile) {
    final heroTag = 'profile-${widget.user!.uid}';

    return Column(
      children: [
        Hero(
          tag: heroTag,
          child: _ProfileAvatar(
            imageUrl: widget.user!.photoURL,
            size: isMobile ? 120 : 150,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _displayName,
          style: TextStyle(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          _position,
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileForm(bool isMobile) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            initialValue: _displayName,
            enabled: _isEditing,
            decoration: const InputDecoration(labelText: 'Nom complet'),
            validator:
                (value) =>
                    value == null || value.isEmpty
                        ? 'Veuillez entrer un nom'
                        : null,
            onSaved: (value) => _displayName = value!,
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _position,
            enabled: _isEditing,
            decoration: const InputDecoration(labelText: 'Poste'),
            validator:
                (value) =>
                    value == null || value.isEmpty
                        ? 'Veuillez entrer un poste'
                        : null,
            onSaved: (value) => _position = value!,
          ),
        ],
      ),
    );
  }

  void _toggleEditMode() async {
    if (_isEditing && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      await _firestore.updateDocument(
        collection: 'users',
        docId: widget.user!.uid,
        data: {'name': _displayName, 'position': _position},
      );
    }

    setState(() => _isEditing = !_isEditing);
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const _ProfileAvatar({required this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue.shade100, width: 3),
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl ?? 'https://via.placeholder.com/150',
          fit: BoxFit.cover,
          placeholder:
              (_, __) => const Center(child: CircularProgressIndicator()),
          errorWidget:
              (_, __, ___) => Icon(
                Iconsax.user,
                size: size * 0.4,
                color: Colors.blue.shade300,
              ),
        ),
      ),
    );
  }
}
