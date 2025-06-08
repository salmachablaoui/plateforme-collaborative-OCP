import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CreatePostDialog extends StatefulWidget {
  final User user;
  final String userName;
  final Map<String, dynamic> userData;

  const CreatePostDialog({
    Key? key,
    required this.user,
    required this.userName,
    required this.userData,
  }) : super(key: key);

  @override
  _CreatePostDialogState createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final TextEditingController _postController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  dynamic _imageFile;
  bool _isLoading = false;
  String _visibility = 'public';
  final ImagePicker _picker = ImagePicker();

  // Variables pour le sondage
  bool _showPoll = false;
  final List<TextEditingController> _pollOptionsControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  int _pollDuration = 1;

  ImageProvider? _getProfileImage() {
    try {
      if (widget.userData['photoBase64']?.isNotEmpty == true) {
        final base64String = widget.userData['photoBase64'].split(',').last;
        return MemoryImage(base64Decode(base64String));
      }
      return null;
    } catch (e) {
      debugPrint('Erreur chargement image: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _postController.dispose();
    for (var controller in _pollOptionsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _createPost() async {
    if (_postController.text.isEmpty && _imageFile == null && !_showPoll)
      return;

    setState(() => _isLoading = true);

    try {
      String? imageBase64;
      if (_imageFile != null) {
        if (kIsWeb) {
          imageBase64 = base64Encode(
            await _compressImageWeb(_imageFile as Uint8List),
          );
        } else {
          final compressedBytes = await _compressImageMobile(
            _imageFile as File,
          );
          imageBase64 = base64Encode(compressedBytes);
        }
      }

      Map<String, dynamic>? pollData;
      if (_showPoll) {
        final options =
            _pollOptionsControllers
                .where((controller) => controller.text.isNotEmpty)
                .map((controller) => controller.text)
                .toList();

        if (options.length < 2) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Un sondage doit avoir au moins 2 options'),
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        pollData = {
          'options': options,
          'votes': List.filled(options.length, 0),
          'voters': [],
          'endTime':
              DateTime.now()
                  .add(Duration(days: _pollDuration))
                  .toIso8601String(),
        };
      }

      await _firestore.collection('posts').add({
        'userId': widget.user.uid,
        'userName': widget.userName,
        'userPhoto': widget.userData['photoBase64'] ?? widget.user.photoURL,
        'content': _postController.text,
        'imageBase64': imageBase64,
        'likes': [],
        'commentCount': 0,
        'visibility': _visibility,
        'createdAt': FieldValue.serverTimestamp(),
        'lastCommentAt': FieldValue.serverTimestamp(),
        'hasPoll': _showPoll,
        'poll': pollData,
      });

      _postController.clear();
      setState(() {
        _imageFile = null;
        _showPoll = false;
        for (var controller in _pollOptionsControllers) {
          controller.clear();
        }
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publication créée avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Uint8List> _compressImageMobile(File file) async {
    final originalBytes = await file.readAsBytes();
    if (originalBytes.lengthInBytes > 1 * 1024 * 1024) {
      return originalBytes.sublist(0, 1 * 1024 * 1024);
    }
    return originalBytes;
  }

  Future<Uint8List> _compressImageWeb(Uint8List bytes) async {
    if (bytes.lengthInBytes > 1 * 1024 * 1024) {
      return bytes.sublist(0, 1 * 1024 * 1024);
    }
    return bytes;
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() => _imageFile = bytes);
        } else {
          setState(() => _imageFile = File(pickedFile.path));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() => _imageFile = bytes);
        } else {
          setState(() => _imageFile = File(pickedFile.path));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fonctionnalité vidéo à implémenter')),
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

  Widget _buildImagePreview() {
    if (_imageFile == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child:
                kIsWeb
                    ? Image.memory(
                      _imageFile as Uint8List,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                    )
                    : Image.file(
                      _imageFile as File,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => setState(() => _imageFile = null),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollSection() {
    if (!_showPoll) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Créer un sondage',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
        ),
        const SizedBox(height: 12),
        ..._pollOptionsControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Option ${index + 1}',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _pollOptionsControllers[index].dispose();
                      _pollOptionsControllers.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          );
        }).toList(),
        Padding(
          padding: const EdgeInsets.only(left: 44),
          child: TextButton(
            onPressed: () {
              setState(() {
                _pollOptionsControllers.add(TextEditingController());
              });
            },
            child: Text(
              '+ Ajouter une option',
              style: TextStyle(color: Colors.green[800]),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Durée du sondage',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButton<int>(
                value: _pollDuration,
                isExpanded: true,
                items:
                    List.generate(30, (index) => index + 1).map((days) {
                      return DropdownMenuItem<int>(
                        value: days,
                        child: Text(
                          '$days jour${days > 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 15),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _pollDuration = value);
                  }
                },
                style: Theme.of(context).textTheme.bodyMedium,
                dropdownColor: Colors.white,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: isActive ? color : Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: isActive ? color : Colors.grey.shade600),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? color : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildActionButton(
          icon: Icons.image,
          label: 'Photo',
          color: Colors.green[800]!,
          onPressed: _pickImage,
        ),
        _buildActionButton(
          icon: Icons.videocam,
          label: 'Vidéo',
          color: Colors.red,
          onPressed: _pickVideo,
        ),
        if (!kIsWeb)
          _buildActionButton(
            icon: Icons.camera_alt,
            label: 'Caméra',
            color: Colors.blue,
            onPressed: _takePhoto,
          ),
        _buildActionButton(
          icon: Icons.poll,
          label: 'Sondage',
          color: Colors.green[800]!,
          onPressed: () {
            setState(() {
              _showPoll = !_showPoll;
              if (!_showPoll) {
                for (var controller in _pollOptionsControllers) {
                  controller.clear();
                }
              }
            });
          },
          isActive: _showPoll,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isMobile ? 12 : 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 700,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor, width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Créer une publication',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Contenu
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête utilisateur avec photo de profil
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.green[100],
                          backgroundImage: _getProfileImage(),
                          child:
                              _getProfileImage() == null
                                  ? Text(
                                    widget.userName.isNotEmpty
                                        ? widget.userName[0].toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.green[800],
                                    ),
                                  )
                                  : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.userName,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _visibility == 'public'
                                          ? Colors.green[50]
                                          : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButton<String>(
                                  value: _visibility,
                                  isDense: true,
                                  underline: const SizedBox(),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'public',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.public,
                                            size: 18,
                                            color: Colors.green[800],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Public',
                                            style: TextStyle(
                                              color: Colors.green[800],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'private',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.lock,
                                            size: 18,
                                            color: Colors.grey.shade700,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('Privé'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _visibility = value);
                                    }
                                  },
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Champ de texte
                    TextField(
                      controller: _postController,
                      decoration: InputDecoration(
                        hintText:
                            'Partagez vos idées, projets ou ressources...',
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.hintColor,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: theme.textTheme.bodyLarge,
                    ),

                    // Aperçu de l'image
                    _buildImagePreview(),

                    // Section sondage
                    _buildPollSection(),
                  ],
                ),
              ),
            ),

            // Footer avec boutons
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.dividerColor, width: 1),
                ),
              ),
              child: Column(
                children: [
                  _buildImageButtons(),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: isMobile ? 14 : 16,
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Text(
                                'Publier',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
