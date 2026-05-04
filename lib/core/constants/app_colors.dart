import 'package:flutter/material.dart';
import 'package:hotel_cleaning_app/models/room.dart';

class AppColors {
  static const primary = Color(0xFF1A3A5C);
  static const accent = Color(0xFF2196F3);
  static const background = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const error = Color(0xFFE53935);
  static const success = Color(0xFF43A047);
  static const warning = Color(0xFFFB8C00);

  static Color statusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.notStarted:
        return const Color(0xFF9E9E9E);
      case RoomStatus.cleaning:
        return const Color(0xFF2196F3);
      case RoomStatus.waitingInspection:
        return const Color(0xFFFF9800);
      case RoomStatus.inspectionOk:
        return const Color(0xFF8BC34A);
      case RoomStatus.available:
        return const Color(0xFF43A047);
    }
  }
}
