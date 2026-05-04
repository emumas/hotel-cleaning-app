import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_cleaning_app/providers/providers.dart';
import 'package:hotel_cleaning_app/widgets/floor_filter_bar.dart';
import 'package:hotel_cleaning_app/widgets/room_card.dart';

class InspectorRoomListScreen extends ConsumerStatefulWidget {
  const InspectorRoomListScreen({super.key});

  @override
  ConsumerState<InspectorRoomListScreen> createState() =>
      _InspectorRoomListScreenState();
}

class _InspectorRoomListScreenState
    extends ConsumerState<InspectorRoomListScreen> {
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
        title: const Text('点検者'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).state = null,
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
                if (rooms.isEmpty) {
                  return const Center(child: Text('客室がありません'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rooms.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RoomCard(
                      room: rooms[i],
                      onTap: () =>
                          context.go('/inspector/room/${rooms[i].id}'),
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
    );
  }
}
