import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomStatus {
  notStarted,
  cleaning,
  waitingInspection,
  inspectionOk,
  available;

  String get displayName {
    switch (this) {
      case RoomStatus.notStarted:
        return '未着手';
      case RoomStatus.cleaning:
        return '清掃中';
      case RoomStatus.waitingInspection:
        return '点検待ち';
      case RoomStatus.inspectionOk:
        return '点検OK';
      case RoomStatus.available:
        return '販売可';
    }
  }

  static RoomStatus fromString(String value) {
    switch (value) {
      case '清掃中':
        return RoomStatus.cleaning;
      case '点検待ち':
        return RoomStatus.waitingInspection;
      case '点検OK':
        return RoomStatus.inspectionOk;
      case '販売可':
        return RoomStatus.available;
      default:
        return RoomStatus.notStarted;
    }
  }
}

class Room {
  final String id;
  final String floorId;
  final String floorName;
  final String number;
  final RoomStatus status;
  final String? updatedBy;
  final DateTime? updatedAt;
  final String? sendbackComment;

  const Room({
    required this.id,
    required this.floorId,
    required this.floorName,
    required this.number,
    required this.status,
    this.updatedBy,
    this.updatedAt,
    this.sendbackComment,
  });

  factory Room.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Room(
      id: doc.id,
      floorId: data['floorId'] as String,
      floorName: data['floorName'] as String,
      number: data['number'] as String,
      status: RoomStatus.fromString(data['status'] as String? ?? '未着手'),
      updatedBy: data['updatedBy'] as String?,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      sendbackComment: data['sendbackComment'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'floorId': floorId,
        'floorName': floorName,
        'number': number,
        'status': status.displayName,
        'updatedBy': updatedBy,
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
        'sendbackComment': sendbackComment,
      };

  Room copyWith({
    String? floorId,
    String? floorName,
    String? number,
    RoomStatus? status,
    String? updatedBy,
    DateTime? updatedAt,
    String? sendbackComment,
  }) =>
      Room(
        id: id,
        floorId: floorId ?? this.floorId,
        floorName: floorName ?? this.floorName,
        number: number ?? this.number,
        status: status ?? this.status,
        updatedBy: updatedBy ?? this.updatedBy,
        updatedAt: updatedAt ?? this.updatedAt,
        sendbackComment: sendbackComment ?? this.sendbackComment,
      );
}
