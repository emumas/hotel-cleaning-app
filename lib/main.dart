import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_cleaning_app/app.dart';
import 'package:hotel_cleaning_app/firebase_options.dart';
import 'package:hotel_cleaning_app/providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebaseの設定が完了するまで、初期化をスキップします
  try {
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase initialization skipped: $e');
  }

  runApp(
    const ProviderScope(
      child: _AppInit(),
    ),
  );
}

class _AppInit extends ConsumerWidget {
  const _AppInit();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Firebaseがない場合、この初期化処理もエラーになる可能性があるため、
    // 必要に応じてサービス側でエラーハンドリングを行う必要があります。
    return const HotelCleaningApp();
  }
}
