import 'dart:convert';
import 'dart:io';
import 'package:app_stage/models/user.dart' as LocalUser;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app_stage/models/home_model.dart';

class HomeViewModel with ChangeNotifier {
  final HomeModel _model = HomeModel();
  final TextEditingController postController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  String _visibility = 'public';

  User? get user => _model.currentUser;
  File? get imageFile => _imageFile;
  bool get isLoading => _isLoading;
  String get visibility => _visibility;

  Stream<QuerySnapshot<Map<String, dynamic>>> get postsStream =>
      _model.getPostsStream();

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      _imageFile = File(pickedFile.path);
      notifyListeners();
    }
  }

  Future<void> createPost() async {
    if (postController.text.isEmpty && _imageFile == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      String? imageBase64;
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        imageBase64 = base64Encode(bytes);
      }

      await _model.createPost(
        userId: user!.uid,
        userName: user!.displayName,
        userPhoto: user!.photoURL,
        content: postController.text,
        imageBase64: imageBase64,
      );

      postController.clear();
      _imageFile = null;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> likePost(String postId, List<dynamic> likes) async {
    try {
      await _model.likePost(postId, user!.uid, likes);
    } catch (e) {
      rethrow;
    }
  }

  void removeImage() {
    _imageFile = null;
    notifyListeners();
  }

  void setVisibility(String value) {
    _visibility = value;
    notifyListeners();
  }

  @override
  void dispose() {
    postController.dispose();
    super.dispose();
  }
}
