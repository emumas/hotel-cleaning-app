import 'package:cloud_firestore/cloud_firestore.dart';

enum LostItemStatus {
  storing,
  returned,
  disposed;

  String get displayName {
    switch (this) {
      case LostItemStatus.storing:
        return '保管中';
      case LostItemStatus.returned:
        return '返却済み';
      case LostItemStatus.disposed:
        return '廃棄済み';
    }
  }

  static LostItemStatus fromString(String value) {
    return LostItemStatus.values.firstWhere(
      (e) => e.displayName == value,
      orElse: () => LostItemStatus.storing,
    );
  }
}

class LostItem {
  final String id;
  final String roomId;
  final String roomNumber;
  final String floorName;
  final String photoUrl;
  final String registeredBy;
  final DateTime registeredAt;
  final String date;
  final LostItemStatus status;
  final DateTime? completedAt;
  final String? description;

  const LostItem({
    required this.id,
    required this.roomId,
    required this.roomNumber,
    required this.floorName,
    required this.photoUrl,
    required this.registeredBy,
    required this.registeredAt,
    required this.date,
    required this.status,
    this.completedAt,
    this.description,
  });

  factory LostItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LostItem(
      id: doc.id,
      roomId: data['roomId'] as String,
      roomNumber: data['roomNumber'] as String,
      floorName: data['floorName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String,
      registeredBy: data['registeredBy'] as String,
      registeredAt: (data['registeredAt'] as Timestamp).toDate(),
      date: data['date'] as String,
      status: LostItemStatus.fromString(data['status'] as String? ?? '保管中'),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      description: data['description'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'roomId': roomId,
        'roomNumber': roomNumber,
        'floorName': floorName,
        'photoUrl': photoUrl,
        'registeredBy': registeredBy,
        'registeredAt': Timestamp.fromDate(registeredAt),
        'date': date,
        'status': status.displayName,
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'description': description,
      };

  LostItem copyWith({
    LostItemStatus? status,
    DateTime? completedAt,
    String? description,
  }) =>
      LostItem(
        id: id,
        roomId: roomId,
        roomNumber: roomNumber,
        floorName: floorName,
        photoUrl: photoUrl,
        registeredBy: registeredBy,
        registeredAt: registeredAt,
        date: date,
        status: status ?? this.status,
        completedAt: completedAt ?? this.completedAt,
        description: description ?? this.description,
      );

  bool get isToday {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return date == today;
  }
}
