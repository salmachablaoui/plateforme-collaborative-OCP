import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Envoyer une notification
  Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Vérification si l'utilisateur est authentifié
      if (_auth.currentUser == null) {
        throw Exception("Utilisateur non authentifié.");
      }

      // Ajouter la notification dans Firestore
      await _firestore.collection('notifications').add({
        'userId': recipientId,
        'senderId': _auth.currentUser!.uid,
        'title': title,
        'message': message,
        'type': type,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': data ?? {},
      });
    } catch (e) {
      print("Erreur lors de l'envoi de la notification: $e");
      // Tu peux aussi afficher un message d'erreur à l'utilisateur ici
      throw e; // Propager l'erreur après l'avoir loguée
    }
  }

  // Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      // Mise à jour de la notification pour la marquer comme lue
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
      });
    } catch (e) {
      print("Erreur lors de la mise à jour de la notification: $e");
      // Tu peux aussi afficher un message d'erreur à l'utilisateur ici
      throw e; // Propager l'erreur après l'avoir loguée
    }
  }

  // Récupérer les notifications de l'utilisateur
  Stream<QuerySnapshot> getUserNotifications() {
    try {
      // Récupération des notifications de l'utilisateur triées par date
      return _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      print("Erreur lors de la récupération des notifications: $e");
      // Tu peux aussi afficher un message d'erreur à l'utilisateur ici
      throw e; // Propager l'erreur après l'avoir loguée
    }
  }
}
