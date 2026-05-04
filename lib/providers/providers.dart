import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_cleaning_app/models/floor.dart';
import 'package:hotel_cleaning_app/models/room.dart';
import 'package:hotel_cleaning_app/models/defect_report.dart';
import 'package:hotel_cleaning_app/models/lost_item.dart';
import 'package:hotel_cleaning_app/models/user_role.dart';
import 'package:hotel_cleaning_app/services/auth_service.dart';
import 'package:hotel_cleaning_app/services/defect_service.dart';
import 'package:hotel_cleaning_app/services/lost_item_service.dart';
import 'package:hotel_cleaning_app/services/room_service.dart';

// Firebase
final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);
final storageProvider = Provider((ref) => FirebaseStorage.instance);

// Services
final authServiceProvider = Provider((ref) {
  return AuthService(ref.watch(firestoreProvider));
});

final roomServiceProvider = Provider((ref) {
  return RoomService(ref.watch(firestoreProvider));
});

final defectServiceProvider = Provider((ref) {
  return DefectService(
    ref.watch(firestoreProvider),
    ref.watch(storageProvider),
  );
});

final lostItemServiceProvider = Provider((ref) {
  return LostItemService(
    ref.watch(firestoreProvider),
    ref.watch(storageProvider),
  );
});

// Auth state
final authProvider = StateProvider<UserRole?>((ref) => null);
final currentUserNameProvider = StateProvider<String>((ref) {
  final role = ref.watch(authProvider);
  return role?.displayName ?? '';
});

// Selected floor filter
final selectedFloorIdProvider = StateProvider<String?>((ref) => null);

// Floors
final floorsProvider = StreamProvider<List<Floor>>((ref) {
  return ref.watch(roomServiceProvider).watchFloors();
});

// Rooms
final roomsProvider = StreamProvider.family<List<Room>, String?>((ref, floorId) {
  return ref.watch(roomServiceProvider).watchRooms(floorId: floorId);
});

// Defect reports
final defectReportsProvider =
    StreamProvider.family<List<DefectReport>, String?>((ref, roomId) {
  return ref.watch(defectServiceProvider).watchDefectReports(roomId: roomId);
});

final activeDefectsProvider = StreamProvider<List<DefectReport>>((ref) {
  return ref.watch(defectServiceProvider).watchActiveDefects();
});

// Lost items
final todayLostItemsProvider = StreamProvider<List<LostItem>>((ref) {
  return ref.watch(lostItemServiceProvider).watchTodayLostItems();
});

final allLostItemsProvider = StreamProvider<List<LostItem>>((ref) {
  return ref.watch(lostItemServiceProvider).watchAllLostItems();
});
