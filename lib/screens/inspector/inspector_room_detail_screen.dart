import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_cleaning_app/models/defect_report.dart';
import 'package:hotel_cleaning_app/models/room.dart';
import 'package:hotel_cleaning_app/providers/providers.dart';
import 'package:hotel_cleaning_app/widgets/room_status_chip.dart';

class InspectorRoomDetailScreen extends ConsumerWidget {
  final String roomId;

  const InspectorRoomDetailScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(roomsProvider(null));
    final defectsAsync = ref.watch(defectReportsProvider(roomId));

    return roomsAsync.when(
      data: (rooms) {
        final room = rooms.where((r) => r.id == roomId).firstOrNull;
        if (room == null) {
          return Scaffold(
              appBar: AppBar(title: const Text('点検')),
              body: const Center(child: Text('部屋が見つかりません')));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text('${room.floorName} ${room.number}号室'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/inspector'),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: RoomStatusChip(status: room.status)),
                const SizedBox(height: 24),
                // Defect reports section
                defectsAsync.when(
                  data: (defects) {
                    final active = defects
                        .where((d) => d.status != DefectStatus.repaired)
                        .toList();
                    if (active.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '未対応の不具合 (${active.length}件)',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        ...active.map((d) => _DefectCard(defect: d)),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                _InspectorActions(room: room, ref: ref),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('エラー: $e'))),
    );
  }
}

class _DefectCard extends StatelessWidget {
  final DefectReport defect;

  const _DefectCard({required this.defect});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: ListTile(
        leading: const Icon(Icons.warning, color: Colors.red),
        title: Text(defect.location.displayName),
        subtitle: Text(defect.status.displayName),
      ),
    );
  }
}

class _InspectorActions extends StatefulWidget {
  final Room room;
  final WidgetRef ref;

  const _InspectorActions({required this.room, required this.ref});

  @override
  State<_InspectorActions> createState() => _InspectorActionsState();
}

class _InspectorActionsState extends State<_InspectorActions> {
  @override
  Widget build(BuildContext context) {
    final service = widget.ref.read(roomServiceProvider);
    final userName = widget.ref.read(currentUserNameProvider);

    return Column(
      children: [
        if (widget.room.status == RoomStatus.waitingInspection) ...[
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle),
            label: const Text('点検OK'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              await service.updateRoomStatus(
                  widget.room.id, RoomStatus.inspectionOk, userName);
              if (context.mounted) context.go('/inspector');
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.undo, color: Colors.red),
            label: const Text('差し戻し', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
            onPressed: () => _showSendbackDialog(context, service, userName),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.room.status == RoomStatus.inspectionOk) ...[
          ElevatedButton.icon(
            icon: const Icon(Icons.sell),
            label: const Text('販売可にする'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              await service.updateRoomStatus(
                  widget.room.id, RoomStatus.available, userName);
              if (context.mounted) context.go('/inspector');
            },
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          icon: const Icon(Icons.report_problem),
          label: const Text('不具合報告'),
          onPressed: () {
            context.go('/inspector/defect/${widget.room.id}', extra: {
              'roomNumber': widget.room.number,
              'floorName': widget.room.floorName,
            });
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.search),
          label: const Text('忘れ物登録'),
          onPressed: () {
            context.go('/inspector/lost-item/${widget.room.id}', extra: {
              'roomNumber': widget.room.number,
              'floorName': widget.room.floorName,
            });
          },
        ),
      ],
    );
  }

  void _showSendbackDialog(
      BuildContext context, dynamic service, String userName) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('差し戻しコメント'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'コメントを入力してください'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await service.updateRoomStatus(
                widget.room.id,
                RoomStatus.cleaning,
                userName,
                sendbackComment: controller.text.trim(),
              );
              if (context.mounted) context.go('/inspector');
            },
            child: const Text('差し戻し'),
          ),
        ],
      ),
    );
  }
}
