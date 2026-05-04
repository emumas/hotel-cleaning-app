import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hotel_cleaning_app/models/defect_report.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data'; // Add this import for Uint8List

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

  // Modified to accept Uint8List and fileName
  Future<String> uploadPhoto(Uint8List photoData, String reportId, String fileName) async {
    final ref = _storage
        .ref()
        .child('defects/$reportId/$fileName'); // Use fileName directly
    await ref.putData(photoData); // Use putData for Uint8List
    return await ref.getDownloadURL();
  }

  Future<DefectReport> addDefectReport({
    required String roomId,
    required String roomNumber,
    required String floorName,
    required DefectLocation location,
    required List<Uint8List> photosData, // Changed from List<File> to List<Uint8List>
    required String registeredBy,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final photoUrls = <String>[];
    for (int i = 0; i < photosData.length; i++) {
      final fileName = '${_uuid.v4()}.jpg'; // Generate a unique file name
      final url = await uploadPhoto(photosData[i], id, fileName); // Pass photoData and fileName
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
    Uint8List? completionPhotoData, // Changed from File? to Uint8List?
    String? notes,
  }) async {
    String? completionPhotoUrl;
    if (completionPhotoData != null) {
      final fileName = '${_uuid.v4()}.jpg';
      completionPhotoUrl = await uploadPhoto(completionPhotoData, '
          '
          '$reportId-done', fileName); // Pass photoData and fileName
    }
    await _db.collection('defect_reports').doc(reportId).update({
      'status': DefectStatus.repaired.displayName,
      'completionPhotoUrl': completionPhotoUrl,
      'completedAt': Timestamp.fromDate(DateTime.now()),
      'notes': notes,
    });
  }
}
