import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static const FirebaseOptions androidConfig = FirebaseOptions(
    apiKey: "AIzaSyAp231bOnYw8WQLrgJm_aBqXTFclmUfiXk",
    appId: "1:1033394801561:android:3a810c70940b2819732108",
    messagingSenderId: "1033394801561",
    projectId: "app-stage-2f629",
    authDomain: "app-stage-21629.firebaseapp.com",
    storageBucket: "app-stage-21629.appspot.com",
  );

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(options: androidConfig);
      if (kDebugMode) print("✅ Firebase initialisé !");
    } catch (e) {
      debugPrint("❌ Erreur Firebase: $e");
      rethrow;
    }
  }
}
