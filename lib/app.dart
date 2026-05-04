import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_cleaning_app/core/router/app_router.dart';
import 'package:hotel_cleaning_app/core/theme/app_theme.dart';

class HotelCleaningApp extends ConsumerWidget {
  const HotelCleaningApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ホテル客室管理',
      theme: AppTheme.theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
