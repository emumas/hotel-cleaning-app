import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_cleaning_app/models/user_role.dart';

class AuthService {
  final FirebaseFirestore _db;

  AuthService(this._db);

  Future<UserRole?> verifyPin(String pin) async {
    final doc = await _db.collection('config').doc('pins').get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    if (data['staff_pin'] == pin) return UserRole.staff;
    if (data['inspector_pin'] == pin) return UserRole.inspector;
    if (data['admin_pin'] == pin) return UserRole.admin;
    return null;
  }

  Future<void> updatePin(UserRole role, String newPin) async {
    final field = switch (role) {
      UserRole.staff => 'staff_pin',
      UserRole.inspector => 'inspector_pin',
      UserRole.admin => 'admin_pin',
    };
    await _db.collection('config').doc('pins').set(
      {field: newPin},
      SetOptions(merge: true),
    );
  }

  Future<void> initializePinsIfNeeded() async {
    final doc = await _db.collection('config').doc('pins').get();
    if (!doc.exists) {
      await _db.collection('config').doc('pins').set({
        'staff_pin': '1111',
        'inspector_pin': '2222',
        'admin_pin': '3333',
      });
    }
  }
}
