// services/friend_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Envoyer une demande d'ami
  Future<void> sendFriendRequest(String senderId, String recipientId) async {
    final batch = _firestore.batch();

    // Ajouter à la liste des demandes envoyées
    batch.set(
      _firestore
          .collection('users')
          .doc(senderId)
          .collection('sent_requests')
          .doc(recipientId),
      {'timestamp': FieldValue.serverTimestamp()},
    );

    // Ajouter à la liste des demandes reçues
    batch.set(
      _firestore
          .collection('users')
          .doc(recipientId)
          .collection('received_requests')
          .doc(senderId),
      {'timestamp': FieldValue.serverTimestamp()},
    );

    await batch.commit();
  }

  // Accepter une demande d'ami
  Future<void> acceptFriendRequest(String userId, String friendId) async {
    final batch = _firestore.batch();
    final timestamp = FieldValue.serverTimestamp();

    // Supprimer des demandes reçues
    batch.delete(
      _firestore
          .collection('users')
          .doc(userId)
          .collection('received_requests')
          .doc(friendId),
    );

    // Supprimer des demandes envoyées (côté ami)
    batch.delete(
      _firestore
          .collection('users')
          .doc(friendId)
          .collection('sent_requests')
          .doc(userId),
    );

    // Ajouter à la liste d'amis des deux utilisateurs
    batch.set(
      _firestore
          .collection('users')
          .doc(userId)
          .collection('friends')
          .doc(friendId),
      {'addedAt': timestamp},
    );

    batch.set(
      _firestore
          .collection('users')
          .doc(friendId)
          .collection('friends')
          .doc(userId),
      {'addedAt': timestamp},
    );

    await batch.commit();
  }

  // Récupérer la liste d'amis
  Stream<QuerySnapshot> getFriends(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('friends')
        .orderBy('addedAt', descending: true)
        .snapshots();
  }

  // Vérifier si deux utilisateurs sont amis
  Future<bool> areFriends(String user1Id, String user2Id) async {
    final doc =
        await _firestore
            .collection('users')
            .doc(user1Id)
            .collection('friends')
            .doc(user2Id)
            .get();
    return doc.exists;
  }
}
