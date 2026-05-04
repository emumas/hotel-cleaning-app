import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hotel_cleaning_app/models/lost_item.dart';
import 'package:uuid/uuid.dart';

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

  Future<String> uploadPhoto(Uint8List photoData, String itemId) async {
    final ref = _storage
        .ref()
        .child('lost_items/$itemId/${_uuid.v4()}.jpg');
    await ref.putData(photoData);
    return await ref.getDownloadURL();
  }

  Future<LostItem> addLostItem({
    required String roomId,
    required String roomNumber,
    required String floorName,
    required Uint8List photo,
    required String registeredBy,
    String? description,
  }) async {
    final id = _uuid.v4();
    final photoUrl = await uploadPhoto(photo, id);
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
