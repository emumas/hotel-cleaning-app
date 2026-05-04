import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hotel_cleaning_app/models/defect_report.dart';
import 'package:uuid/uuid.dart';

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

  Future<String> uploadPhoto(File file, String reportId) async {
    final ref = _storage
        .ref()
        .child('defects/$reportId/${_uuid.v4()}.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<DefectReport> addDefectReport({
    required String roomId,
    required String roomNumber,
    required String floorName,
    required DefectLocation location,
    required List<File> photos,
    required String registeredBy,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final photoUrls = <String>[];
    for (final photo in photos) {
      final url = await uploadPhoto(photo, id);
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
    await _db.collection('defect_reports').doc(id).set(report.toFirestore());
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
    File? completionPhoto,
    String? notes,
  }) async {
    String? completionPhotoUrl;
    if (completionPhoto != null) {
      completionPhotoUrl = await uploadPhoto(completionPhoto, '$reportId-done');
    }
    await _db.collection('defect_reports').doc(reportId).update({
      'status': DefectStatus.repaired.displayName,
      'completionPhotoUrl': completionPhotoUrl,
      'completedAt': Timestamp.fromDate(DateTime.now()),
      'notes': notes,
    });
  }
}
