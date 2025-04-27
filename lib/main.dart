import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login.dart';
import 'register.dart';
import 'home.dart';

void main() async {
  // Initialisation synchrone nécessaire pour Firebase
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
    debugPrint("Erreur d'initialisation Firebase: $e");
  }

  runApp(const MyApp());
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
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.green,
        ).copyWith(
          secondary: const Color(0xFF2E7D32), // Couleur OCP
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home':
            (context) => HomeScreen(
              key: UniqueKey(),
            ), // Clé unique pour éviter les conflits
      },
      onUnknownRoute:
          (settings) => MaterialPageRoute(
            builder:
                (context) =>
                    const LoginScreen(), // Retour au login si route inconnue
          ),
    );
  }
}
