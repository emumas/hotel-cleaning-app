import 'package:flutter/material.dart';
import 'package:hotel_cleaning_app/core/constants/app_colors.dart';
import 'package:hotel_cleaning_app/models/room.dart';

class RoomStatusChip extends StatelessWidget {
  final RoomStatus status;
  final bool compact;

  const RoomStatusChip({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: compact ? 11 : 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
