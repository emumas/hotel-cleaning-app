import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_cleaning_app/models/floor.dart';
import 'package:hotel_cleaning_app/models/room.dart';
import 'package:uuid/uuid.dart';

class RoomService {
  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  RoomService(this._db);

  // Floors
  Stream<List<Floor>> watchFloors() {
    return _db
        .collection('floors')
        .orderBy('order')
        .snapshots()
        .map((s) => s.docs.map(Floor.fromFirestore).toList());
  }

  Future<Floor> addFloor(String name) async {
    final snapshot = await _db.collection('floors').orderBy('order').get();
    final maxOrder = snapshot.docs.isEmpty
        ? 0
        : (snapshot.docs.last.data()['order'] as int) + 1;
    final id = _uuid.v4();
    final floor = Floor(
      id: id,
      name: name,
      order: maxOrder,
      createdAt: DateTime.now(),
    );
    await _db.collection('floors').doc(id).set(floor.toFirestore());
    return floor;
  }

  Future<void> updateFloorOrder(List<Floor> floors) async {
    final batch = _db.batch();
    for (var i = 0; i < floors.length; i++) {
      batch.update(
        _db.collection('floors').doc(floors[i].id),
        {'order': i},
      );
    }
    await batch.commit();
  }

  Future<void> deleteFloor(String floorId) async {
    final rooms = await _db
        .collection('rooms')
        .where('floorId', isEqualTo: floorId)
        .get();
    if (rooms.docs.isNotEmpty) {
      throw Exception('部屋が登録されているフロアは削除できません');
    }
    await _db.collection('floors').doc(floorId).delete();
  }

  Future<void> renameFloor(String floorId, String newName) async {
    await _db.collection('floors').doc(floorId).update({'name': newName});
  }

  // Rooms
  Stream<List<Room>> watchRooms({String? floorId}) {
    Query query = _db.collection('rooms');
    if (floorId != null) {
      query = query.where('floorId', isEqualTo: floorId);
    }
    return query
        .snapshots()
        .map((s) => s.docs.map(Room.fromFirestore).toList()
          ..sort((a, b) => a.number.compareTo(b.number)));
  }

  Future<Room> addRoom(String floorId, String floorName, String number) async {
    final existing = await _db
        .collection('rooms')
        .where('floorId', isEqualTo: floorId)
        .where('number', isEqualTo: number)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('同じ部屋番号が既に存在します');
    }
    final id = _uuid.v4();
    final room = Room(
      id: id,
      floorId: floorId,
      floorName: floorName,
      number: number,
      status: RoomStatus.notStarted,
    );
    await _db.collection('rooms').doc(id).set(room.toFirestore());
    return room;
  }

  Future<void> deleteRoom(String roomId) async {
    await _db.collection('rooms').doc(roomId).delete();
  }

  Future<void> updateRoomNumber(String roomId, String newNumber) async {
    await _db.collection('rooms').doc(roomId).update({'number': newNumber});
  }

  Future<void> updateRoomStatus(
    String roomId,
    RoomStatus newStatus,
    String updatedBy, {
    String? sendbackComment,
  }) async {
    await _db.collection('rooms').doc(roomId).update({
      'status': newStatus.displayName,
      'updatedBy': updatedBy,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'sendbackComment': sendbackComment,
    });
  }

  Future<void> resetAllRooms() async {
    final rooms = await _db.collection('rooms').get();
    final batch = _db.batch();
    for (final doc in rooms.docs) {
      batch.update(doc.reference, {
        'status': RoomStatus.notStarted.displayName,
        'updatedBy': null,
        'updatedAt': null,
        'sendbackComment': null,
      });
    }
    await batch.commit();
  }
}
