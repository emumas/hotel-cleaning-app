import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_cleaning_app/core/constants/app_colors.dart';
import 'package:hotel_cleaning_app/models/room.dart';
import 'package:hotel_cleaning_app/providers/providers.dart';
import 'package:hotel_cleaning_app/widgets/floor_filter_bar.dart';
import 'package:hotel_cleaning_app/widgets/room_card.dart';

class StaffRoomListScreen extends ConsumerStatefulWidget {
  const StaffRoomListScreen({super.key});

  @override
  ConsumerState<StaffRoomListScreen> createState() =>
      _StaffRoomListScreenState();
}

class _StaffRoomListScreenState extends ConsumerState<StaffRoomListScreen> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final floors = ref.watch(floorsProvider);
    final selectedFloorId = ref.watch(selectedFloorIdProvider);
    final roomsAsync = ref.watch(roomsProvider(
      _showAll ? null : selectedFloorId,
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('清掃スタッフ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).state = null;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          FloorFilterBar(
            showAll: _showAll,
            onShowAllChanged: (v) => setState(() => _showAll = v),
          ),
          if (!_showAll)
            floors.when(
              data: (floorList) => FloorTabBar(floors: floorList),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          Expanded(
            child: roomsAsync.when(
              data: (rooms) {
                final active = rooms
                    .where((r) => r.status != RoomStatus.available)
                    .toList();
                if (active.isEmpty) {
                  return const Center(child: Text('担当客室はありません'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: active.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RoomCard(
                      room: active[i],
                      onTap: () => context.go('/staff/room/${active[i].id}'),
                    ),
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('エラー: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLostItemRoomPicker(context),
        icon: const Icon(Icons.search),
        label: const Text('忘れ物登録'),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  void _showLostItemRoomPicker(BuildContext context) {
    final roomsAsync = ref.read(roomsProvider(null));
    roomsAsync.whenData((rooms) {
      showModalBottomSheet(
        context: context,
        builder: (_) => _RoomPickerSheet(
          rooms: rooms,
          onSelect: (room) {
            Navigator.pop(context);
            context.go('/staff/lost-item/${room.id}', extra: {
              'roomNumber': room.number,
              'floorName': room.floorName,
            });
          },
        ),
      );
    });
  }
}

class _RoomPickerSheet extends StatelessWidget {
  final List<Room> rooms;
  final void Function(Room) onSelect;

  const _RoomPickerSheet({required this.rooms, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '部屋を選択',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: rooms.length,
            itemBuilder: (context, i) => ListTile(
              title: Text('${rooms[i].floorName} ${rooms[i].number}号室'),
              onTap: () => onSelect(rooms[i]),
            ),
          ),
        ),
      ],
    );
  }
}
