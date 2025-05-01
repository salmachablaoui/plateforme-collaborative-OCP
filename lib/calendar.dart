import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:table_calendar/table_calendar.dart';
import 'adaptive_drawer.dart';
import 'custom_app_bar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final User? _user = FirebaseAuth.instance.currentUser;
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final Map<DateTime, List<Event>> _events = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;

    // Événements de démonstration
    _events[DateTime.now()] = [
      Event('Réunion équipe', '10:00', Colors.blue),
      Event('Déjeuner client', '12:30', Colors.green),
    ];
    _events[DateTime.now().add(const Duration(days: 1))] = [
      Event('Revue de projet', '14:00', Colors.orange),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final eventsForSelectedDay =
        _selectedDay != null ? _events[_selectedDay] ?? [] : [];

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AdaptiveDrawer(),
      appBar: CustomAppBar(
        title: 'Agenda',
        scaffoldKey: _scaffoldKey,
        user: _user,
        showSearchButton: true,
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonDecoration: BoxDecoration(
                  border: Border.all(color: AdaptiveDrawer.primaryColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                formatButtonTextStyle: TextStyle(
                  color: AdaptiveDrawer.primaryColor,
                ),
              ),
              eventLoader: (day) => _events[day] ?? [],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: eventsForSelectedDay.length,
              itemBuilder: (context, index) {
                final event = eventsForSelectedDay[index];
                return _EventCard(event: event);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        backgroundColor: AdaptiveDrawer.primaryColor,
        child: const Icon(Iconsax.add, color: Colors.white),
      ),
    );
  }

  void _showAddEventDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Nouvel événement'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    prefixIcon: Icon(Iconsax.edit),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(
                    labelText: 'Heure (HH:MM)',
                    prefixIcon: Icon(Iconsax.clock),
                  ),
                  keyboardType: TextInputType.datetime,
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
                              Container(width: 16, height: 16, color: color),
                              const SizedBox(width: 8),
                              Text(color.toString().split('.')[1]),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (color) {
                    if (color != null) {
                      selectedColor = color;
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Couleur',
                    prefixIcon: Icon(Iconsax.colorfilter),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty &&
                      timeController.text.isNotEmpty &&
                      _selectedDay != null) {
                    setState(() {
                      _events[_selectedDay!] ??= [];
                      _events[_selectedDay!]!.add(
                        Event(
                          titleController.text,
                          timeController.text,
                          selectedColor,
                        ),
                      );
                    });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdaptiveDrawer.primaryColor,
                ),
                child: const Text('Ajouter'),
              ),
            ],
          ),
    );
  }
}

class Event {
  final String title;
  final String time;
  final Color color;

  const Event(this.title, this.time, this.color);
}

class _EventCard extends StatelessWidget {
  final Event event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: event.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Iconsax.calendar_1, color: event.color),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'À ${event.time}',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: const Icon(Iconsax.arrow_right_3),
        onTap: () => _showEventDetails(context),
      ),
    );
  }

  void _showEventDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: event.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Iconsax.calendar_1, size: 30, color: event.color),
                ),
                const SizedBox(height: 16),
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'À ${event.time}',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdaptiveDrawer.primaryColor,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ),
    );
  }
}
