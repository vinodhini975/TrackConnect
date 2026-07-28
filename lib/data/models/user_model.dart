import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String wardNumber;
  final int ecoPoints;
  final String? profilePhotoUrl;

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.wardNumber,
    required this.ecoPoints,
    this.profilePhotoUrl,
  });

  UserModel copyWith({
    String? fullName,
    String? wardNumber,
    int? ecoPoints,
    String? profilePhotoUrl,
  }) => UserModel(
    uid: uid,
    fullName: fullName ?? this.fullName,
    email: email,
    wardNumber: wardNumber ?? this.wardNumber,
    ecoPoints: ecoPoints ?? this.ecoPoints,
    profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
  );

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      wardNumber: map['wardNumber'] ?? 'Ward 195',
      ecoPoints: map['ecoPoints'] ?? 0,
      profilePhotoUrl: map['profilePhotoUrl'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'fullName': fullName,
    'email': email,
    'wardNumber': wardNumber,
    'ecoPoints': ecoPoints,
    'profilePhotoUrl': profilePhotoUrl,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
