import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class InfosChatroomPage extends StatefulWidget {
  final String chatroomId;
  final bool isAdmin;
  final VoidCallback onMembersUpdated;

  const InfosChatroomPage({
    Key? key,
    required this.chatroomId,
    required this.isAdmin,
    required this.onMembersUpdated,
  }) : super(key: key);

  @override
  State<InfosChatroomPage> createState() => _InfosChatroomPageState();
}

class _InfosChatroomPageState extends State<InfosChatroomPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  late Stream<DocumentSnapshot> _chatroomStream;
  String? _newChatroomName;
  String? _newChatroomPhoto;

  @override
  void initState() {
    super.initState();
    _chatroomStream =
        _firestore.collection('chatrooms').doc(widget.chatroomId).snapshots();
  }

  Future<void> _updateChatroomName() async {
    if (_newChatroomName == null || _newChatroomName!.isEmpty) return;

    try {
      await _firestore.collection('chatrooms').doc(widget.chatroomId).update({
        'name': _newChatroomName,
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nom du groupe mis à jour')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _updateChatroomPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      // Ici vous devriez uploader l'image vers Firebase Storage
      // et récupérer l'URL pour la sauvegarder dans Firestore
      // Ceci est un exemple simplifié
      final String imageUrl = image.path; // Remplacez par l'URL réelle

      await _firestore.collection('chatrooms').doc(widget.chatroomId).update({
        'photoUrl': imageUrl,
      });

      setState(() => _newChatroomPhoto = imageUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo du groupe mise à jour')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _removeParticipant(String userId) async {
    try {
      await _firestore.collection('chatrooms').doc(widget.chatroomId).update({
        'participants': FieldValue.arrayRemove([userId]),
      });
      widget.onMembersUpdated();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Membre retiré du groupe')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Future<void> _addParticipants(List<String> userIds) async {
    try {
      await _firestore.collection('chatrooms').doc(widget.chatroomId).update({
        'participants': FieldValue.arrayUnion(userIds),
      });
      widget.onMembersUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${userIds.length} membres ajoutés')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  Widget _buildGroupHeader(DocumentSnapshot chatroomDoc) {
    final chatroomData = chatroomDoc.data() as Map<String, dynamic>;
    final photoUrl = chatroomData['photoUrl'] as String?;
    final name = chatroomData['name'] as String? ?? 'Chatroom';
    final createdAt = chatroomData['createdAt'] as Timestamp?;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage:
                  photoUrl != null
                      ? CachedNetworkImageProvider(photoUrl)
                      : null,
              child:
                  photoUrl == null
                      ? const Icon(Iconsax.people, size: 50)
                      : null,
            ),
            if (widget.isAdmin)
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.camera,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                onPressed: _updateChatroomPhoto,
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.isAdmin)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: TextFormField(
              initialValue: name,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  icon: const Icon(Iconsax.edit),
                  onPressed: _updateChatroomName,
                ),
                border: UnderlineInputBorder(),
              ),
              onChanged: (value) => _newChatroomName = value,
            ),
          )
        else
          Text(name, style: Theme.of(context).textTheme.headlineSmall),
        if (createdAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Créé le ${DateFormat('dd/MM/yyyy').format(createdAt.toDate())}',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildMemberList(List<String> participants, String createdBy) {
    return Expanded(
      child: ListView.builder(
        itemCount: participants.length,
        itemBuilder: (context, index) {
          final userId = participants[index];
          return FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('users').doc(userId).get(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return const ListTile(title: Text('Utilisateur inconnu'));
              }

              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;
              final isAdmin = userId == createdBy;
              final fullName = userData['fullName'] ?? 'Utilisateur';
              final photoUrl = userData['photoUrl'] as String?;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      photoUrl != null
                          ? CachedNetworkImageProvider(photoUrl)
                          : null,
                  child:
                      photoUrl == null ? Text(fullName.substring(0, 1)) : null,
                ),
                title: Text(fullName),
                subtitle: isAdmin ? const Text('Admin') : null,
                trailing:
                    _currentUser?.uid == userId
                        ? null
                        : widget.isAdmin
                        ? IconButton(
                          icon: const Icon(
                            Iconsax.user_minus,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeParticipant(userId),
                        )
                        : null,
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informations du groupe'),
        actions: [
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Iconsax.user_add),
              onPressed: () => _showAddParticipantsDialog(),
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _chatroomStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final chatroomData = snapshot.data!.data() as Map<String, dynamic>;
          final participants = List<String>.from(
            chatroomData['participants'] ?? [],
          );
          final createdBy = chatroomData['createdBy'] as String;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildGroupHeader(snapshot.data!),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Membres (${participants.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              _buildMemberList(participants, createdBy),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddParticipantsDialog() async {
    // Implémentez ici la logique pour sélectionner des utilisateurs à ajouter
    // Par exemple, afficher une liste de tous les utilisateurs non membres
    // et permettre leur sélection

    // Ceci est un exemple simplifié:
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajouter des membres'),
          content: const Text('Fonctionnalité à implémenter'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                // Retourner une liste fictive d'IDs utilisateur
                Navigator.pop(context, ['user1', 'user2']);
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      await _addParticipants(result);
    }
  }
}
