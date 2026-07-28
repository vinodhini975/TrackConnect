import 'package:cloud_firestore/cloud_firestore.dart';

class EcoReport {
  final String userId;
  final int totalEcoPoints;
  final String level;
  final double wasteSavedKg;
  final double co2SavedKg;
  final double recycledKg;
  final double treesEquivalent;
  final List<bool> weeklyConsistency; // 7 items Mon–Sun

  const EcoReport({
    required this.userId,
    required this.totalEcoPoints,
    required this.level,
    required this.wasteSavedKg,
    required this.co2SavedKg,
    required this.recycledKg,
    required this.treesEquivalent,
    required this.weeklyConsistency,
  });

  factory EcoReport.fromMap(Map<String, dynamic> map) => EcoReport(
    userId: map['userId'] ?? '',
    totalEcoPoints: map['totalEcoPoints'] ?? 0,
    level: map['level'] ?? '',
    wasteSavedKg: (map['wasteSavedKg'] ?? 0.0).toDouble(),
    co2SavedKg: (map['co2SavedKg'] ?? 0.0).toDouble(),
    recycledKg: (map['recycledKg'] ?? 0.0).toDouble(),
    treesEquivalent: (map['treesEquivalent'] ?? 0.0).toDouble(),
    weeklyConsistency: List<bool>.from(map['weeklyConsistency'] ?? [false, false, false, false, false, false, false]),
  );

  factory EcoReport.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return EcoReport.fromMap({...map, 'userId': doc.id});
  }
}
