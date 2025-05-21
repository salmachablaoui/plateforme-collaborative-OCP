import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;

class ProfileScreen extends StatefulWidget {
  final User? user;
  final String? userId;

  const ProfileScreen({super.key, this.user, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> _userData;
  bool _isLoading = true;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  File? _imageFile;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _fullNameController;
  late TextEditingController _departmentController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _userData = {
      'fullName': 'Chargement...',
      'email': '',
      'department': '',
      'phone': '',
      'photoBase64': '',
    };
    _fullNameController = TextEditingController();
    _departmentController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserData();
  }

  String get _uid {
    return widget.user?.uid ?? widget.userId ?? '';
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          _imageBytes = await pickedFile.readAsBytes();
        } else {
          _imageFile = File(pickedFile.path);
          _imageBytes = await _imageFile!.readAsBytes();
        }
        await _saveProfileImage();
      }
    } catch (e) {
      _showError('Erreur lors de la sélection: $e');
    }
  }

  Future<void> _saveProfileImage() async {
    if (_imageBytes == null || _uid.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final base64Image = base64Encode(_imageBytes!);
      final imageData = 'data:image/jpeg;base64,$base64Image';

      await FirebaseFirestore.instance.collection('users').doc(_uid).update({
        'photoBase64': imageData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadUserData();
      _showSuccess('Photo sauvegardée avec succès');
    } catch (e) {
      _showError('Erreur sauvegarde photo: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserData() async {
    if (_uid.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance.collection('users').doc(_uid).get();

      if (doc.exists) {
        setState(() {
          _userData = doc.data() as Map<String, dynamic>;
          _fullNameController.text = _userData['fullName'] ?? '';
          _departmentController.text = _userData['department'] ?? '';
          _phoneController.text = _userData['phone'] ?? '';

          // Set email from Firestore if not available from User object
          if (widget.user == null && _userData['email'] != null) {
            _userData['email'] = _userData['email'];
          } else if (widget.user != null) {
            _userData['email'] = widget.user!.email ?? '';
          }
        });
      }
    } catch (e) {
      _showError('Erreur chargement données: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ImageProvider? _getProfileImage() {
    try {
      if (_userData['photoBase64']?.isNotEmpty == true) {
        return MemoryImage(
          base64Decode(_userData['photoBase64'].split(',').last),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Erreur chargement image: $e');
      return null;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
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
        GestureDetector(
          onTap: _isEditing ? _pickImage : null,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            backgroundImage: _getProfileImage(),
            child:
                _userData['photoBase64']?.isEmpty ?? true
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _userData['fullName'],
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(_userData['email'], style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  void _toggleEditMode() async {
    if (_isEditing) {
      if (_formKey.currentState!.validate()) {
        await _saveProfileData();
      }
    }
    setState(() => _isEditing = !_isEditing);
  }

  Future<void> _saveProfileData() async {
    if (_uid.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(_uid).update({
        'fullName': _fullNameController.text.trim(),
        'department': _departmentController.text.trim(),
        'phone': _phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadUserData();
      _showSuccess('Profil mis à jour');
    } catch (e) {
      _showError('Erreur sauvegarde: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.person,
            label: 'Nom complet',
            controller: _fullNameController,
            isEditable: _isEditing,
          ),
          const Divider(),
          _buildInfoTile(
            icon: Icons.email,
            label: 'Email',
            value: _userData['email'],
            isEditable: false,
          ),
          const Divider(),
          _buildInfoTile(
            icon: Icons.work,
            label: 'Département',
            controller: _departmentController,
            isEditable: _isEditing,
          ),
          const Divider(),
          _buildInfoTile(
            icon: Icons.phone,
            label: 'Téléphone',
            controller: _phoneController,
            isEditable: _isEditing,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    String? value,
    TextEditingController? controller,
    required bool isEditable,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title:
          isEditable && controller != null
              ? TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                ),
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
                    value ?? controller?.text ?? 'Non renseigné',
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          (value ?? controller?.text)?.isEmpty ?? true
                              ? Colors.grey
                              : Colors.black,
                    ),
                  ),
                ],
              ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
