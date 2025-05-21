import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:app_stage/views/shared/adaptive_drawer.dart';
import 'package:app_stage/views/shared/custom_app_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CollaborativeCalendarScreenState();
}

class _CollaborativeCalendarScreenState extends State<CalendarScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      _firestore
          .collection('calendar_events')
          .where('participants', arrayContains: _currentUser?.uid)
          .snapshots()
          .listen((snapshot) {
            final Map<DateTime, List<CalendarEvent>> newEvents = {};

            for (final doc in snapshot.docs) {
              final event = CalendarEvent.fromFirestore(doc);
              final date = DateTime(
                event.date.year,
                event.date.month,
                event.date.day,
              );

              newEvents[date] ??= [];
              newEvents[date]!.add(event);
            }

            setState(() {
              _events = newEvents;
              _isLoading = false;
            });
          });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur de chargement: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsForSelectedDay =
        _selectedDay != null ? _events[_selectedDay] ?? [] : [];

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AdaptiveDrawer(),
      appBar: CustomAppBar(
        title: 'Calendrier Collaboratif',
        scaffoldKey: _scaffoldKey,
        user: _currentUser,
        showSearchButton: false,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Card(
                    margin: EdgeInsets.all(isMobile ? 8 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate:
                          (day) => isSameDay(_selectedDay, day),
                      calendarFormat: _calendarFormat,
                      onFormatChanged: (format) {
                        setState(() => _calendarFormat = format);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color: AdaptiveDrawer.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: AdaptiveDrawer.primaryColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: AdaptiveDrawer.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        markersAlignment: Alignment.bottomCenter,
                        outsideDaysVisible: false,
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: true,
                        titleCentered: true,
                        formatButtonDecoration: BoxDecoration(
                          border: Border.all(
                            color: AdaptiveDrawer.primaryColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        formatButtonTextStyle: TextStyle(
                          color: AdaptiveDrawer.primaryColor,
                        ),
                        leftChevronIcon: const Icon(Iconsax.arrow_left_2),
                        rightChevronIcon: const Icon(Iconsax.arrow_right_3),
                      ),
                      eventLoader: (day) => _events[day] ?? [],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 16,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'ÉVÉNEMENTS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildEventsList(
                      List<CalendarEvent>.from(eventsForSelectedDay),
                      isMobile,
                    ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(),
        backgroundColor: AdaptiveDrawer.primaryColor,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEventsList(List<CalendarEvent> events, bool isMobile) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.calendar_remove,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun événement ce jour',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 8 : 16),
      itemCount: events.length,
      itemBuilder:
          (context, index) => _EventCard(
            event: events[index],
            currentUserId: _currentUser?.uid,
            onEdit: () => _showEditEventDialog(events[index]),
            onDelete: () => _deleteEvent(events[index]),
          ),
    );
  }

  Future<void> _showAddEventDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final timeController = TextEditingController(text: '09:00');
    DateTime selectedDate = _selectedDay ?? DateTime.now();
    Color selectedColor = Colors.blue;
    List<String> selectedParticipants = [];

    // Charger la liste des utilisateurs disponibles
    final users = await _firestore.collection('users').get();

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Nouvel Événement'),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Titre',
                            prefixIcon: Icon(Iconsax.edit_2),
                          ),
                          validator:
                              (value) =>
                                  value?.isEmpty ?? true ? 'Requis' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            prefixIcon: Icon(Iconsax.note),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now().subtract(
                                      const Duration(days: 365),
                                    ),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                  );
                                  if (date != null) {
                                    setState(() => selectedDate = date);
                                  }
                                },
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(selectedDate),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: timeController,
                                decoration: const InputDecoration(
                                  labelText: 'Heure',
                                  prefixIcon: Icon(Iconsax.clock),
                                ),
                                keyboardType: TextInputType.datetime,
                                validator:
                                    (value) =>
                                        value?.isEmpty ?? true
                                            ? 'Requis'
                                            : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Color>(
                          value: selectedColor,
                          items:
                              [
                                Colors.blue,
                                Colors.green,
                                Colors.orange,
                                Colors.purple,
                                Colors.red,
                              ].map((color) {
                                return DropdownMenuItem(
                                  value: color,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        color: color,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(color.toString().split('.')[1]),
                                    ],
                                  ),
                                );
                              }).toList(),
                          onChanged: (color) {
                            if (color != null) {
                              setState(() => selectedColor = color);
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Couleur',
                            prefixIcon: Icon(Iconsax.colorfilter),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ExpansionTile(
                          title: const Text('Participants'),
                          children: [
                            ...users.docs.map((userDoc) {
                              final userId = userDoc.id;
                              final userData = userDoc.data();
                              final isSelected = selectedParticipants.contains(
                                userId,
                              );

                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedParticipants.add(userId);
                                    } else {
                                      selectedParticipants.remove(userId);
                                    }
                                  });
                                },
                                title: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundImage:
                                          userData['photoUrl'] != null
                                              ? CachedNetworkImageProvider(
                                                userData['photoUrl'],
                                              )
                                              : null,
                                      child:
                                          userData['photoUrl'] == null
                                              ? Text(
                                                userData['fullName']?.substring(
                                                      0,
                                                      1,
                                                    ) ??
                                                    'U',
                                              )
                                              : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(userData['fullName'] ?? 'Utilisateur'),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState?.validate() ?? false) {
                        await _addEvent(
                          title: titleController.text,
                          description: descriptionController.text,
                          date: selectedDate,
                          time: timeController.text,
                          color: selectedColor,
                          participants: [
                            ...selectedParticipants,
                            _currentUser?.uid ?? '',
                          ],
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdaptiveDrawer.primaryColor,
                    ),
                    child: const Text('Créer'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _showEditEventDialog(CalendarEvent event) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: event.title);
    final descriptionController = TextEditingController(
      text: event.description,
    );
    final timeController = TextEditingController(text: event.time);
    DateTime selectedDate = event.date;
    Color selectedColor = event.color;
    List<String> selectedParticipants = event.participants;

    // Charger la liste des utilisateurs disponibles
    final users = await _firestore.collection('users').get();

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Modifier Événement'),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Titre',
                            prefixIcon: Icon(Iconsax.edit_2),
                          ),
                          validator:
                              (value) =>
                                  value?.isEmpty ?? true ? 'Requis' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            prefixIcon: Icon(Iconsax.note),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now().subtract(
                                      const Duration(days: 365),
                                    ),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 365),
                                    ),
                                  );
                                  if (date != null) {
                                    setState(() => selectedDate = date);
                                  }
                                },
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(selectedDate),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: timeController,
                                decoration: const InputDecoration(
                                  labelText: 'Heure',
                                  prefixIcon: Icon(Iconsax.clock),
                                ),
                                keyboardType: TextInputType.datetime,
                                validator:
                                    (value) =>
                                        value?.isEmpty ?? true
                                            ? 'Requis'
                                            : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Color>(
                          value: selectedColor,
                          items:
                              [
                                Colors.blue,
                                Colors.green,
                                Colors.orange,
                                Colors.purple,
                                Colors.red,
                              ].map((color) {
                                return DropdownMenuItem(
                                  value: color,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        color: color,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(color.toString().split('.')[1]),
                                    ],
                                  ),
                                );
                              }).toList(),
                          onChanged: (color) {
                            if (color != null) {
                              setState(() => selectedColor = color);
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Couleur',
                            prefixIcon: Icon(Iconsax.colorfilter),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ExpansionTile(
                          title: const Text('Participants'),
                          children: [
                            ...users.docs.map((userDoc) {
                              final userId = userDoc.id;
                              final userData = userDoc.data();
                              final isSelected = selectedParticipants.contains(
                                userId,
                              );

                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedParticipants.add(userId);
                                    } else {
                                      selectedParticipants.remove(userId);
                                    }
                                  });
                                },
                                title: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundImage:
                                          userData['photoUrl'] != null
                                              ? CachedNetworkImageProvider(
                                                userData['photoUrl'],
                                              )
                                              : null,
                                      child:
                                          userData['photoUrl'] == null
                                              ? Text(
                                                userData['fullName']?.substring(
                                                      0,
                                                      1,
                                                    ) ??
                                                    'U',
                                              )
                                              : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(userData['fullName'] ?? 'Utilisateur'),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState?.validate() ?? false) {
                        await _updateEvent(
                          event.id,
                          title: titleController.text,
                          description: descriptionController.text,
                          date: selectedDate,
                          time: timeController.text,
                          color: selectedColor,
                          participants: selectedParticipants,
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdaptiveDrawer.primaryColor,
                    ),
                    child: const Text('Enregistrer'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _addEvent({
    required String title,
    required String description,
    required DateTime date,
    required String time,
    required Color color,
    required List<String> participants,
  }) async {
    try {
      await _firestore.collection('calendar_events').add({
        'title': title,
        'description': description,
        'date': Timestamp.fromDate(date),
        'time': time,
        'color': color.value,
        'creator': _currentUser?.uid,
        'participants': participants,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _showError('Erreur de création: $e');
    }
  }

  Future<void> _updateEvent(
    String eventId, {
    required String title,
    required String description,
    required DateTime date,
    required String time,
    required Color color,
    required List<String> participants,
  }) async {
    try {
      await _firestore.collection('calendar_events').doc(eventId).update({
        'title': title,
        'description': description,
        'date': Timestamp.fromDate(date),
        'time': time,
        'color': color.value,
        'participants': participants,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _showError('Erreur de mise à jour: $e');
    }
  }

  Future<void> _deleteEvent(CalendarEvent event) async {
    try {
      await _firestore.collection('calendar_events').doc(event.id).delete();
    } catch (e) {
      _showError('Erreur de suppression: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final Color color;
  final String creator;
  final List<String> participants;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.color,
    required this.creator,
    required this.participants,
  });

  factory CalendarEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarEvent(
      id: doc.id,
      title: data['title'] ?? 'Sans titre',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] ?? '00:00',
      color: Color(data['color'] ?? Colors.blue.value),
      creator: data['creator'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CalendarEvent event;
  final String? currentUserId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventCard({
    required this.event,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCreator = event.creator == currentUserId;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEventDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: event.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Iconsax.calendar_1, color: event.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('dd/MM/yyyy').format(event.date)} • ${event.time}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCreator)
                    PopupMenuButton(
                      icon: const Icon(Iconsax.more),
                      itemBuilder:
                          (context) => [
                            PopupMenuItem(
                              child: const Text('Modifier'),
                              onTap: onEdit,
                            ),
                            PopupMenuItem(
                              child: const Text(
                                'Supprimer',
                                style: TextStyle(color: Colors.red),
                              ),
                              onTap: onDelete,
                            ),
                          ],
                    ),
                ],
              ),
              if (event.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  event.description,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
              const SizedBox(height: 12),
              _buildParticipantsList(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantsList(bool isMobile) {
    return FutureBuilder<QuerySnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: event.participants)
              .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final participants = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participants (${participants.length})',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final user =
                      participants[index].data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Tooltip(
                      message: user['fullName'] ?? 'Utilisateur',
                      child: CircleAvatar(
                        radius: 20,
                        backgroundImage:
                            user['photoUrl'] != null
                                ? CachedNetworkImageProvider(user['photoUrl'])
                                : null,
                        child:
                            user['photoUrl'] == null
                                ? Text(user['fullName']?.substring(0, 1) ?? 'U')
                                : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEventDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            expand: false,
            maxChildSize: 0.9,
            initialChildSize: 0.5,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: event.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Iconsax.calendar_1,
                            size: 30,
                            color: event.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Iconsax.calendar, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat(
                              'EEEE dd MMMM yyyy',
                              'fr_FR',
                            ).format(event.date),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Iconsax.clock, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            event.time,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (event.description.isNotEmpty) ...[
                        Text(
                          'Description',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Text(
                        'Participants (${event.participants.length})',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailedParticipantsList(),
                      const SizedBox(height: 24),
                      if (event.creator == currentUserId)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: onEdit,
                                child: const Text('Modifier'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: onDelete,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Supprimer'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildDetailedParticipantsList() {
    return FutureBuilder<QuerySnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: event.participants)
              .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final participants = snapshot.data!.docs;

        return Column(
          children:
              participants.map((doc) {
                final user = doc.data() as Map<String, dynamic>;
                final isCreator = doc.id == event.creator;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        user['photoUrl'] != null
                            ? CachedNetworkImageProvider(user['photoUrl'])
                            : null,
                    child:
                        user['photoUrl'] == null
                            ? Text(user['fullName']?.substring(0, 1) ?? 'U')
                            : null,
                  ),
                  title: Text(user['fullName'] ?? 'Utilisateur'),
                  subtitle: Text(user['email'] ?? ''),
                  trailing:
                      isCreator
                          ? const Chip(
                            label: Text('Créateur'),
                            backgroundColor: Colors.green,
                            labelStyle: TextStyle(color: Colors.white),
                          )
                          : null,
                );
              }).toList(),
        );
      },
    );
  }
}
