import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String fullName;
  final String professionalEmail;
  final String password; // À hasher avant stockage
  final DateTime birthDate;
  final String department;
  final String phone;
  final String gender;

  User({
    required this.uid,
    required this.fullName,
    required this.professionalEmail,
    required this.password,
    required this.birthDate,
    required this.department,
    required this.phone,
    required this.gender,
  }) {
    // Validations
    if (professionalEmail.isEmpty || !professionalEmail.contains('@')) {
      throw ArgumentError('Email professionnel invalide');
    }
    if (birthDate.isAfter(DateTime.now())) {
      throw ArgumentError('Date de naissance invalide');
    }
  }

  // Convertir en Map pour Firebase (sans le mot de passe)
  Map<String, dynamic> toFirebaseMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'professionalEmail': professionalEmail,
      'birthDate': birthDate.toIso8601String(),
      'department': department,
      'phone': phone,
      'gender': gender,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Factory pour création depuis Firebase
  factory User.fromFirebase(Map<String, dynamic> data) {
    return User(
      uid: data['uid'] as String,
      fullName: data['fullName'] as String,
      professionalEmail: data['professionalEmail'] as String,
      password: '', // Mot de passe non stocké en clair
      birthDate: DateTime.parse(data['birthDate'] as String),
      department: data['department'] as String,
      phone: data['phone'] as String,
      gender: data['gender'] as String,
    );
  }

  // Utilisateur vide
  static User empty() => User(
    uid: '',
    fullName: '',
    professionalEmail: '',
    password: '',
    birthDate: DateTime(2000),
    department: '',
    phone: '',
    gender: '',
  );

  // Vérification
  bool get isEmpty => uid.isEmpty;
  bool get isNotEmpty => !isEmpty;

  get displayName => null;

  get photoURL => null;

  // Copie avec modifications
  User copyWith({
    String? uid,
    String? fullName,
    String? professionalEmail,
    String? password,
    DateTime? birthDate,
    String? department,
    String? phone,
    String? gender,
  }) {
    return User(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      professionalEmail: professionalEmail ?? this.professionalEmail,
      password: password ?? this.password,
      birthDate: birthDate ?? this.birthDate,
      department: department ?? this.department,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
    );
  }

  // Pour debug
  @override
  String toString() {
    return 'User($fullName, $professionalEmail, ${birthDate.year})';
  }
}
