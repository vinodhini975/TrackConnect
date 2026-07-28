class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'COLLECTION', 'TRUCK_ARRIVING', 'REWARD'

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.type,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id, title: title, message: message,
    timestamp: timestamp, type: type,
    isRead: isRead ?? this.isRead,
  );
}
