import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hotel_cleaning_app/models/defect_report.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';

class DefectService {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  DefectService(this._db, this._storage);

  Stream<List<DefectReport>> watchDefectReports({String? roomId}) {
    Query query = _db.collection('defect_reports');
    if (roomId != null) {
      query = query.where('roomId', isEqualTo: roomId);
    }
    return query
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(DefectReport.fromFirestore).toList());
  }

  Stream<List<DefectReport>> watchActiveDefects() {
    return _db
        .collection('defect_reports')
        .where('status', isNotEqualTo: DefectStatus.repaired.displayName)
        .orderBy('status')
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(DefectReport.fromFirestore).toList());
  }

  Future<String> uploadPhoto(Uint8List photoData, String reportId, String fileName) async {
    final ref = _storage
        .ref()
        .child('defects/$reportId/$fileName');
    await ref.putData(photoData, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  Future<DefectReport> addDefectReport({
    required String roomId,
    required String roomNumber,
    required String floorName,
    required DefectLocation location,
    required List<Uint8List> photosData,
    required String registeredBy,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final photoUrls = <String>[];
    for (int i = 0; i < photosData.length; i++) {
      final fileName = '${_uuid.v4()}.jpg';
      final url = await uploadPhoto(photosData[i], id, fileName);
      photoUrls.add(url);
    }
    final report = DefectReport(
      id: id,
      roomId: roomId,
      roomNumber: roomNumber,
      floorName: floorName,
      location: location,
      photoUrls: photoUrls,
      registeredBy: registeredBy,
      registeredAt: DateTime.now(),
      status: DefectStatus.pending,
      notes: notes,
    );
    try {
      await _db.collection('defect_reports').doc(id).set(report.toFirestore());
    } catch (e) {
      print("Error adding defect report to Firestore: $e");
      rethrow;
    }
    return report;
  }

  Future<void> updateDefectStatus(
    String reportId,
    DefectStatus newStatus,
  ) async {
    await _db.collection('defect_reports').doc(reportId).update({
      'status': newStatus.displayName,
    });
  }

  Future<void> completeDefect(
    String reportId, {
    Uint8List? completionPhotoData,
    String? notes,
  }) async {
    String? completionPhotoUrl;
    if (completionPhotoData != null) {
      final fileName = '${_uuid.v4()}.jpg';
      completionPhotoUrl = await uploadPhoto(completionPhotoData, reportId, fileName);
    }
    await _db.collection('defect_reports').doc(reportId).update({
      'status': DefectStatus.repaired.displayName,
      'completionPhotoUrl': completionPhotoUrl,
      'completedAt': Timestamp.fromDate(DateTime.now()),
      'notes': notes,
    });
  }
}
