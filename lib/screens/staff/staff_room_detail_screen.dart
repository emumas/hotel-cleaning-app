import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_cleaning_app/models/room.dart';
import 'package:hotel_cleaning_app/providers/providers.dart';
import 'package:hotel_cleaning_app/services/room_service.dart';
import 'package:hotel_cleaning_app/widgets/room_status_chip.dart';

class StaffRoomDetailScreen extends ConsumerWidget {
  final String roomId;

  const StaffRoomDetailScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider(null));

    return roomsAsync.when(
      data: (rooms) {
        final room = rooms.where((r) => r.id == roomId).firstOrNull;
        if (room == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('客室詳細')),
            body: const Center(child: Text('部屋が見つかりません')),
          );
        }
        return _RoomDetailView(room: room);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('エラー: $e')),
      ),
    );
  }
}

class _RoomDetailView extends ConsumerWidget {
  final Room room;

  const _RoomDetailView({required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(roomServiceProvider);
    final userName = ref.read(currentUserNameProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${room.floorName} ${room.number}号室'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/staff'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: RoomStatusChip(status: room.status)),
            const SizedBox(height: 24),
            if (room.sendbackComment != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '差し戻しコメント',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 4),
                    Text(room.sendbackComment!),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            const Spacer(),
            _ActionButtons(room: room, service: service, userName: userName),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Room room;
  final RoomService service;
  final String userName;

  const _ActionButtons({
    required this.room,
    required this.service,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (room.status == RoomStatus.notStarted ||
            room.status == RoomStatus.cleaning) ...[
          ElevatedButton.icon(
            icon: const Icon(Icons.cleaning_services),
            label: Text(room.status == RoomStatus.notStarted
                ? '清掃開始'
                : '清掃完了（点検待ちにする）'),
            onPressed: () async {
              final nextStatus = room.status == RoomStatus.notStarted
                  ? RoomStatus.cleaning
                  : RoomStatus.waitingInspection;
              await service.updateRoomStatus(room.id, nextStatus, userName);
              if (context.mounted) context.go('/staff');
            },
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.search),
          label: const Text('忘れ物を登録'),
          onPressed: () {
            context.go('/staff/lost-item/${room.id}', extra: {
              'roomNumber': room.number,
              'floorName': room.floorName,
            });
          },
        ),
      ],
    );
  }
}
