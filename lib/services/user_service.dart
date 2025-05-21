// services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer un utilisateur par son ID
  Future<DocumentSnapshot> getUser(String userId) async {
    return await _firestore.collection('users').doc(userId).get();
  }

  // Récupérer tous les utilisateurs (avec pagination optionnelle)
  Stream<QuerySnapshot> getAllUsers({int limit = 20}) {
    return _firestore.collection('users').limit(limit).snapshots();
  }

  // Rechercher des utilisateurs par nom ou email
  Future<QuerySnapshot> searchUsers(String query) {
    return _firestore
        .collection('users')
        .where('fullName', isGreaterThanOrEqualTo: query)
        .where('fullName', isLessThan: query + 'z')
        .get();
  }

  // Mettre à jour le profil utilisateur
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  // Créer un nouvel utilisateur dans Firestore après l'inscription
  Future<void> createUserRecord({
    required String userId,
    required String email,
    required String fullName,
    required String department,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'email': email,
      'fullName': fullName,
      'department': department,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'role': 'employee',
    });
  }
}
