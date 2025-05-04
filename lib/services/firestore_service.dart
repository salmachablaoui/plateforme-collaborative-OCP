import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      final doc = await _firestore.collection(collection).doc(docId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Erreur getDocument: $e');
      return null;
    }
  }

  Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).update(data);
    } catch (e) {
      print('Erreur updateDocument: $e');
    }
  }
}
