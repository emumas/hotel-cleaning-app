import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_cleaning_app/app.dart';
import 'package:hotel_cleaning_app/firebase_options.dart';
import 'package:hotel_cleaning_app/providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
    // Initialize default PINs on first launch
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authServiceProvider).initializePinsIfNeeded();
    });

    return const HotelCleaningApp();
  }
}
