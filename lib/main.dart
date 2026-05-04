import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_cleaning_app/app.dart';
import 'package:hotel_cleaning_app/firebase_options.dart';
import 'package:hotel_cleaning_app/providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(authServiceProvider).initializePinsIfNeeded();
      } catch (e) {
        debugPrint('PIN initialization error: $e');
      }
    });

    return const HotelCleaningApp();
  }
}
