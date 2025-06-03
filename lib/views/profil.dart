import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:intl/intl.dart';

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
  late String _currentUserId;

  late TextEditingController _fullNameController;
  late TextEditingController _departmentController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.user?.uid ?? widget.userId ?? '';
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

  Future<void> _loadUserData() async {
    if (_currentUserId.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUserId)
              .get();

      if (doc.exists) {
        setState(() {
          _userData = doc.data() as Map<String, dynamic>;
          _fullNameController.text = _userData['fullName'] ?? '';
          _departmentController.text = _userData['department'] ?? '';
          _phoneController.text = _userData['phone'] ?? '';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (_currentUserId == (widget.user?.uid ?? ''))
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
              onPressed: _toggleEditMode,
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const TabBar(
                      tabs: [
                        Tab(icon: Icon(Icons.info), text: 'Informations'),
                        Tab(icon: Icon(Icons.post_add), text: 'Publications'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildProfileInfoTab(),
                          _buildUserPostsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
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
          const SizedBox(height: 8),
          if (_userData['department']?.isNotEmpty ?? false)
            Text(
              _userData['department'],
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
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
      ),
    );
  }

  Widget _buildUserPostsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('posts')
              .where('userId', isEqualTo: _currentUserId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Aucune publication disponible'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final post = snapshot.data!.docs[index];
            final postData = post.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête de la publication
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage:
                              _userData['photoBase64']?.isNotEmpty == true
                                  ? MemoryImage(
                                    base64Decode(
                                      _userData['photoBase64'].split(',').last,
                                    ),
                                  )
                                  : null,
                          child:
                              _userData['photoBase64']?.isEmpty ?? true
                                  ? const Icon(Icons.person)
                                  : null,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userData['fullName'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (postData['createdAt'] != null)
                              Text(
                                DateFormat('dd MMM yyyy à HH:mm').format(
                                  (postData['createdAt'] as Timestamp).toDate(),
                                ),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Contenu de la publication
                    if (postData['content'] != null &&
                        postData['content'].toString().isNotEmpty)
                      Text(
                        postData['content'],
                        style: const TextStyle(fontSize: 16),
                      ),

                    // Image de la publication
                    if (postData['imageBase64'] != null &&
                        postData['imageBase64'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Image.memory(
                          base64Decode(postData['imageBase64'].split(',').last),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Commentaires et likes
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.comment),
                          onPressed: () {},
                        ),
                        Text(postData['comments']?.length.toString() ?? '0'),

                        const SizedBox(width: 16),

                        IconButton(
                          icon: Icon(
                            Icons.favorite,
                            color:
                                postData['likes']?.contains(_currentUserId) ??
                                        false
                                    ? Colors.red
                                    : Colors.grey,
                          ),
                          onPressed: () {},
                        ),
                        Text(postData['likes']?.length.toString() ?? '0'),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
                validator: (value) {
                  if (label == 'Nom complet' &&
                      (value == null || value.isEmpty)) {
                    return 'Ce champ est requis';
                  }
                  return null;
                },
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
    if (_imageBytes == null || _currentUserId.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final base64Image = base64Encode(_imageBytes!);
      final imageData = 'data:image/jpeg;base64,$base64Image';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .update({
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

  void _toggleEditMode() async {
    if (_isEditing) {
      if (_formKey.currentState!.validate()) {
        await _saveProfileData();
      }
    }
    setState(() => _isEditing = !_isEditing);
  }

  Future<void> _saveProfileData() async {
    if (_currentUserId.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .update({
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
  void dispose() {
    _fullNameController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
