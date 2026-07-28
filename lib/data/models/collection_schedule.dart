import 'package:cloud_firestore/cloud_firestore.dart';

class CollectionSchedule {
  final String id;
  final String dayOfWeek;     // 'Monday', 'Tuesday', etc.
  final String wasteType;     // 'Organic Waste', 'Recyclable', 'No Collection'
  final String startTime;     // '08:00'
  final String endTime;       // '10:00'
  final String wardNumber;
  final bool reminderEnabled;

  const CollectionSchedule({
    required this.id,
    required this.dayOfWeek,
    required this.wasteType,
    required this.startTime,
    required this.endTime,
    required this.wardNumber,
    this.reminderEnabled = false,
  });

  CollectionSchedule copyWith({bool? reminderEnabled}) => CollectionSchedule(
    id: id, dayOfWeek: dayOfWeek, wasteType: wasteType,
    startTime: startTime, endTime: endTime, wardNumber: wardNumber,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
  );

  factory CollectionSchedule.fromMap(Map<String, dynamic> map) =>
    CollectionSchedule(
      id: map['id'] ?? '',
      dayOfWeek: map['dayOfWeek'] ?? '',
      wasteType: map['wasteType'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      wardNumber: map['wardNumber'] ?? '',
      reminderEnabled: map['reminderEnabled'] ?? false,
    );

  factory CollectionSchedule.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return CollectionSchedule.fromMap({...map, 'id': doc.id});
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'dayOfWeek': dayOfWeek, 'wasteType': wasteType,
    'startTime': startTime, 'endTime': endTime,
    'wardNumber': wardNumber, 'reminderEnabled': reminderEnabled,
  };

  Map<String, dynamic> toFirestore() => {
    'dayOfWeek': dayOfWeek,
    'wasteType': wasteType,
    'startTime': startTime,
    'endTime': endTime,
    'wardNumber': wardNumber,
    'reminderEnabled': reminderEnabled,
  };
}
