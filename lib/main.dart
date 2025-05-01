import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login.dart';
import 'register.dart';
import 'home.dart';
import 'package:provider/provider.dart';
// Imports ajoutés pour tes écrans liés au drawer
import 'friends.dart';
import 'chatrooms.dart';
import 'calendar.dart';
import 'settings.dart';
import 'notifications.dart';
import 'adaptive_drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAp231bOnYw8WQLrgJm_aBqXTFclmUfiXk",
        appId: "1:1033394801561:android:3a810c70940b2819732108",
        messagingSenderId: "1033394801561",
        projectId: "app-stage-2f629",
        authDomain: "app-stage-21629.firebaseapp.com",
        storageBucket: "app-stage-21629.appspot.com",
      ),
    );
  } catch (e) {
    debugPrint("Erreur Firebase: $e");
  }

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
