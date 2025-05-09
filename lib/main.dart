// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './firebase/firebase_config.dart';
import 'views/auth/login.dart';
import 'views/auth/register.dart';
import 'views/home.dart';
// Imports pour les écrans du drawer
import 'views/friends.dart';
import 'views/chat/chatrooms.dart';
import 'views/calendar.dart';
import 'views/settings.dart';
import 'views/notifications.dart';
import 'views/shared/adaptive_drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseConfig.initialize(); // Initialisation Firebase depuis le fichier externe

  runApp(
    ChangeNotifierProvider(
      create: (context) => NavigationProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OCP Connect',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (ctx) => const LoginScreen(),
        '/register': (ctx) => const RegisterScreen(),
        '/home': (ctx) => const HomeScreen(),
        '/friends': (ctx) => const FriendsScreen(),
        '/chatrooms': (ctx) => const ChatroomsScreen(),
        '/calendar': (ctx) => const CalendarScreen(),
        '/settings': (ctx) => const SettingsScreen(),
        '/notifications': (ctx) => const NotificationsScreen(),
      },
      onUnknownRoute:
          (settings) =>
              MaterialPageRoute(builder: (ctx) => const LoginScreen()),
    );
  }
}
