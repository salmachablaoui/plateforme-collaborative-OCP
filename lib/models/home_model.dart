import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> createPost({
    required String userId,
    required String? userName,
    required String? userPhoto,
    required String content,
    required String? imageBase64,
  }) async {
    await _firestore.collection('posts').add({
      'userId': userId,
      'userName': userName ?? 'Anonyme',
      'userPhoto': userPhoto,
      'content': content,
      'imageBase64': imageBase64,
      'likes': [],
      'comments': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> likePost(
    String postId,
    String userId,
    List<dynamic> likes,
  ) async {
    if (likes.contains(userId)) {
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } else {
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayUnion([userId]),
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getPostsStream() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static String getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Il y a ${difference.inSeconds} secondes';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} heures';
    } else if (difference.inDays < 30) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Il y a $years ans';
    }
  }
}
