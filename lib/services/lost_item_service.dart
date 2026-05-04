import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hotel_cleaning_app/models/lost_item.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data'; // Add this import for Uint8List

class LostItemService {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  LostItemService(this._db, this._storage);

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Stream<List<LostItem>> watchTodayLostItems() {
    final today = _todayString();
    return _db
        .collection('lost_items')
        .where('date', isEqualTo: today)
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(LostItem.fromFirestore).toList());
  }

  Stream<List<LostItem>> watchAllLostItems() {
    return _db
        .collection('lost_items')
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(LostItem.fromFirestore).toList());
  }

  // Modified to accept Uint8List and fileName
  Future<String> uploadPhoto(Uint8List photoData, String itemId, String fileName) async {
    final ref = _storage
        .ref()
        .child('lost_items/$itemId/$fileName'); // Use fileName directly
    await ref.putData(photoData); // Use putData for Uint8List
    return await ref.getDownloadURL();
  }

  Future<LostItem> addLostItem({
    required String roomId,
    required String roomNumber,
    required String floorName,
    required Uint8List photoData, // Changed from File to Uint8List
    required String registeredBy,
    String? description,
  }) async {
    final id = _uuid.v4();
    final fileName = '${_uuid.v4()}.jpg'; // Generate a unique file name
    final photoUrl = await uploadPhoto(photoData, id, fileName); // Pass photoData and fileName
    final now = DateTime.now();
    final today = _todayString();
    final item = LostItem(
      id: id,
      roomId: roomId,
      roomNumber: roomNumber,
      floorName: floorName,
      photoUrl: photoUrl,
      registeredBy: registeredBy,
      registeredAt: now,
      date: today,
      status: LostItemStatus.storing,
      description: description,
    );
    await _db.collection('lost_items').doc(id).set(item.toFirestore());
    return item;
  }

  Future<void> completeLostItem(String itemId, LostItemStatus status) async {
    await _db.collection('lost_items').doc(itemId).update({
      'status': status.displayName,
      'completedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
