import 'package:cloud_firestore/cloud_firestore.dart';

enum DefectLocation {
  bathroom,
  floor,
  wallCeiling,
  windowCurtain,
  furnitureEquipment,
  doorLock,
  other;

  String get displayName {
    switch (this) {
      case DefectLocation.bathroom:
        return 'バスルーム';
      case DefectLocation.floor:
        return '床・カーペット';
      case DefectLocation.wallCeiling:
        return '壁・天井';
      case DefectLocation.windowCurtain:
        return '窓・カーテン';
      case DefectLocation.furnitureEquipment:
        return '家具・設備';
      case DefectLocation.doorLock:
        return 'ドア・鍵';
      case DefectLocation.other:
        return 'その他';
    }
  }

  static DefectLocation fromString(String value) {
    return DefectLocation.values.firstWhere(
      (e) => e.displayName == value,
      orElse: () => DefectLocation.other,
    );
  }
}

enum DefectStatus {
  pending,
  inProgress,
  waitingRepair,
  repaired;

  String get displayName {
    switch (this) {
      case DefectStatus.pending:
        return '未対応';
      case DefectStatus.inProgress:
        return '対応中';
      case DefectStatus.waitingRepair:
        return '修繕待ち';
      case DefectStatus.repaired:
        return '修繕完了';
    }
  }

  static DefectStatus fromString(String value) {
    return DefectStatus.values.firstWhere(
      (e) => e.displayName == value,
      orElse: () => DefectStatus.pending,
    );
  }
}

class DefectReport {
  final String id;
  final String roomId;
  final String roomNumber;
  final String floorName;
  final DefectLocation location;
  final List<String> photoUrls;
  final String registeredBy;
  final DateTime registeredAt;
  final DefectStatus status;
  final String? completionPhotoUrl;
  final DateTime? completedAt;
  final String? notes;

  const DefectReport({
    required this.id,
    required this.roomId,
    required this.roomNumber,
    required this.floorName,
    required this.location,
    required this.photoUrls,
    required this.registeredBy,
    required this.registeredAt,
    required this.status,
    this.completionPhotoUrl,
    this.completedAt,
    this.notes,
  });

  factory DefectReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DefectReport(
      id: doc.id,
      roomId: data['roomId'] as String,
      roomNumber: data['roomNumber'] as String,
      floorName: data['floorName'] as String? ?? '',
      location: DefectLocation.fromString(data['location'] as String),
      photoUrls: List<String>.from(data['photoUrls'] as List? ?? []),
      registeredBy: data['registeredBy'] as String,
      registeredAt: (data['registeredAt'] as Timestamp).toDate(),
      status: DefectStatus.fromString(data['status'] as String? ?? '未対応'),
      completionPhotoUrl: data['completionPhotoUrl'] as String?,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'roomId': roomId,
        'roomNumber': roomNumber,
        'floorName': floorName,
        'location': location.displayName,
        'photoUrls': photoUrls,
        'registeredBy': registeredBy,
        'registeredAt': Timestamp.fromDate(registeredAt),
        'status': status.displayName,
        'completionPhotoUrl': completionPhotoUrl,
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'notes': notes,
      };

  DefectReport copyWith({
    DefectStatus? status,
    String? completionPhotoUrl,
    DateTime? completedAt,
    String? notes,
  }) =>
      DefectReport(
        id: id,
        roomId: roomId,
        roomNumber: roomNumber,
        floorName: floorName,
        location: location,
        photoUrls: photoUrls,
        registeredBy: registeredBy,
        registeredAt: registeredAt,
        status: status ?? this.status,
        completionPhotoUrl: completionPhotoUrl ?? this.completionPhotoUrl,
        completedAt: completedAt ?? this.completedAt,
        notes: notes ?? this.notes,
      );
}
