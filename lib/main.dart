import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_cleaning_app/app.dart';
import 'package:hotel_cleaning_app/firebase_options.dart';
import 'package:hotel_cleaning_app/providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Web環境での初期化をより確実にする設定
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(
    const ProviderScope(
      child: HotelCleaningApp(), // _AppInitを介さず直接起動して型エラーを回避
    ),
  );
}
