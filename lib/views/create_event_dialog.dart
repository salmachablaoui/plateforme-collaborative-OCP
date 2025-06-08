import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';

class CreateEventDialog extends StatefulWidget {
  final DateTime initialDate;
  final Function({
    required String title,
    required String description,
    required DateTime date,
    required String time,
    required Color color,
    required List<String> participants,
  })
  onSave;

  const CreateEventDialog({
    Key? key,
    required this.initialDate,
    required this.onSave,
  }) : super(key: key);

  @override
  _CreateEventDialogState createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<CreateEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeController = TextEditingController(text: '09:00');

  late DateTime _selectedDate;
  Color _selectedColor = Colors.green; // Changé en vert
  List<String> _selectedParticipants = [];
  List<DocumentSnapshot> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _loadUsers();
    if (FirebaseAuth.instance.currentUser?.uid != null) {
      _selectedParticipants.add(FirebaseAuth.instance.currentUser!.uid);
    }
  }

  Future<void> _loadUsers() async {
    final users = await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      _allUsers = users.docs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.9,
          maxWidth: isMobile ? double.infinity : 600,
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Nouvel Événement',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),

                // Titre
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    prefixIcon: Icon(Iconsax.edit_2),
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) => value?.isEmpty ?? true ? 'Requis' : null,
                ),
                const SizedBox(height: 20),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Iconsax.note),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Date et Heure
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(Iconsax.calendar),
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy').format(_selectedDate),
                              ),
                              const Icon(Iconsax.arrow_down_1),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _timeController,
                        decoration: const InputDecoration(
                          labelText: 'Heure',
                          prefixIcon: Icon(Iconsax.clock),
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (value) => value?.isEmpty ?? true ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Couleur
                DropdownButtonFormField<Color>(
                  value: _selectedColor,
                  items:
                      [
                            Colors.blue,
                            Colors.green, // Couleur principale verte
                            Colors.orange,
                            Colors
                                .teal, // Remplace purple par teal (vert bleuté)
                            Colors.red,
                          ]
                          .map(
                            (color) => DropdownMenuItem(
                              value: color,
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    color: color,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    color.toString().split('.')[1].capitalize(),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                  onChanged:
                      (color) => setState(
                        () => _selectedColor = color ?? Colors.green,
                      ), // Vert par défaut
                  decoration: const InputDecoration(
                    labelText: 'Couleur',
                    prefixIcon: Icon(Iconsax.colorfilter),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Participants
                ExpansionTile(
                  title: const Text('Participants'),
                  initiallyExpanded: true,
                  children: [
                    const SizedBox(height: 8),
                    ..._allUsers.map((userDoc) {
                      final userId = userDoc.id;
                      final userData = userDoc.data() as Map<String, dynamic>;
                      final isSelected = _selectedParticipants.contains(userId);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged:
                            (value) => setState(() {
                              if (value == true) {
                                _selectedParticipants.add(userId);
                              } else {
                                _selectedParticipants.remove(userId);
                              }
                            }),
                        title: Row(
                          children: [
                            _UserAvatar(userData: userData, size: 32),
                            const SizedBox(width: 12),
                            Text(userData['fullName'] ?? 'Utilisateur'),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
                const SizedBox(height: 24),

                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // Bouton vert
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Créer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _saveEvent() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSave(
        title: _titleController.text,
        description: _descriptionController.text,
        date: _selectedDate,
        time: _timeController.text,
        color: _selectedColor,
        participants: _selectedParticipants,
      );
      Navigator.pop(context);
    }
  }
}

class _UserAvatar extends StatelessWidget {
  final Map<String, dynamic> userData;
  final double size;

  const _UserAvatar({required this.userData, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final fullName = userData['fullName'] ?? 'Utilisateur';
    final firstName = fullName.split(' ').first;
    final lastName =
        fullName.split(' ').length > 1 ? fullName.split(' ').last : '';
    final initials =
        '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}';

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.green.withOpacity(0.2), // Fond vert clair
      backgroundImage:
          userData['photoUrl'] != null
              ? CachedNetworkImageProvider(userData['photoUrl'])
              : userData['photoBase64'] != null
              ? MemoryImage(
                base64Decode(userData['photoBase64'].split(',').last),
              )
              : null,
      child:
          userData['photoUrl'] == null && userData['photoBase64'] == null
              ? Text(
                initials.isNotEmpty ? initials : 'U',
                style: TextStyle(
                  color: Colors.green, // Texte vert
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.4,
                ),
              )
              : null,
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
