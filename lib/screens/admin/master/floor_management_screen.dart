import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_cleaning_app/models/floor.dart';
import 'package:hotel_cleaning_app/providers/providers.dart';

class FloorManagementScreen extends ConsumerWidget {
  const FloorManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final floorsAsync = ref.watch(floorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('フロア・客室管理'),
      ),
      body: floorsAsync.when(
        data: (floors) => _FloorList(floors: floors),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('エラー: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFloorDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('フロア追加'),
      ),
    );
  }

  void _showAddFloorDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('フロアを追加'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: '例: 1F, 2F, PH',
            labelText: 'フロア名',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await ref.read(roomServiceProvider).addFloor(ctrl.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }
}

class _FloorList extends ConsumerWidget {
  final List<Floor> floors;

  const _FloorList({required this.floors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (floors.isEmpty) {
      return const Center(child: Text('フロアがありません\n追加ボタンから作成してください'));
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: floors.length,
      onReorder: (oldIndex, newIndex) async {
        if (newIndex > oldIndex) newIndex -= 1;
        final reordered = List<Floor>.from(floors);
        final item = reordered.removeAt(oldIndex);
        reordered.insert(newIndex, item);
        await ref.read(roomServiceProvider).updateFloorOrder(reordered);
      },
      itemBuilder: (context, i) {
        final floor = floors[i];
        return _FloorTile(key: ValueKey(floor.id), floor: floor);
      },
    );
  }
}

class _FloorTile extends ConsumerWidget {
  final Floor floor;

  const _FloorTile({super.key, required this.floor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider(floor.id));
    final roomCount =
        roomsAsync.asData?.value.length ?? 0;

    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.drag_handle, color: Colors.grey),
        title: Text(floor.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$roomCount部屋'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showRenameDialog(context, ref),
            ),
            IconButton(
              icon: Icon(
                Icons.delete,
                size: 20,
                color: roomCount > 0 ? Colors.grey : Colors.red,
              ),
              onPressed: roomCount > 0
                  ? null
                  : () => _confirmDelete(context, ref),
            ),
          ],
        ),
        children: [
          _RoomList(floor: floor),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: floor.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('フロア名を変更'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'フロア名'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await ref
                  .read(roomServiceProvider)
                  .renameFloor(floor.id, ctrl.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('変更'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('フロアを削除'),
        content: Text('「${floor.name}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await ref.read(roomServiceProvider).deleteFloor(floor.id);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e')),
                  );
                }
              }
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}

class _RoomList extends ConsumerWidget {
  final Floor floor;

  const _RoomList({required this.floor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider(floor.id));

    return roomsAsync.when(
      data: (rooms) => Column(
        children: [
          ...rooms.map((room) => ListTile(
                title: Text('${room.number}号室'),
                subtitle: Text(room.status.displayName),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () =>
                          _showEditRoomDialog(context, ref, room.id, room.number),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      onPressed: () =>
                          _confirmDeleteRoom(context, ref, room.id, room.number),
                    ),
                  ],
                ),
              )),
          ListTile(
            leading: const Icon(Icons.add_circle, color: Colors.blue),
            title: const Text('部屋を追加'),
            onTap: () => _showAddRoomDialog(context, ref),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('エラー: $e'),
    );
  }

  void _showAddRoomDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${floor.name}に部屋を追加'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: '例: 101, 102A',
            labelText: '部屋番号',
          ),
          keyboardType: TextInputType.text,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              try {
                await ref.read(roomServiceProvider).addRoom(
                      floor.id,
                      floor.name,
                      ctrl.text.trim(),
                    );
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e')),
                  );
                }
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  void _showEditRoomDialog(
      BuildContext context, WidgetRef ref, String roomId, String currentNumber) {
    final ctrl = TextEditingController(text: currentNumber);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('部屋番号を変更'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: '部屋番号'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await ref
                  .read(roomServiceProvider)
                  .updateRoomNumber(roomId, ctrl.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('変更'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRoom(
      BuildContext context, WidgetRef ref, String roomId, String number) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('部屋を削除'),
        content: Text('「$number号室」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(roomServiceProvider).deleteRoom(roomId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
