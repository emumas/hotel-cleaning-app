import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_cleaning_app/models/lost_item.dart';
import 'package:hotel_cleaning_app/providers/providers.dart';
import 'package:intl/intl.dart';

class LostItemLedgerScreen extends ConsumerStatefulWidget {
  const LostItemLedgerScreen({super.key});

  @override
  ConsumerState<LostItemLedgerScreen> createState() =>
      _LostItemLedgerScreenState();
}

class _LostItemLedgerScreenState extends ConsumerState<LostItemLedgerScreen> {
  LostItemStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(allLostItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('忘れ物台帳'),
      ),
      body: Column(
        children: [
          _FilterBar(
            selected: _filterStatus,
            onChanged: (v) => setState(() => _filterStatus = v),
          ),
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                final filtered = _filterStatus == null
                    ? items
                    : items.where((i) => i.status == _filterStatus).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('忘れ物の記録はありません'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _LostItemCard(item: filtered[i]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('エラー: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final LostItemStatus? selected;
  final ValueChanged<LostItemStatus?> onChanged;

  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('全て'),
            selected: selected == null,
            onSelected: (_) => onChanged(null),
          ),
          const SizedBox(width: 8),
          ...LostItemStatus.values.map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(s.displayName),
                  selected: selected == s,
                  onSelected: (_) => onChanged(s),
                ),
              )),
        ],
      ),
    );
  }
}

class _LostItemCard extends ConsumerWidget {
  final LostItem item;

  const _LostItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat('yyyy/MM/dd HH:mm').format(item.registeredAt);
    final statusColor = _statusColor(item.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _showPhoto(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.photoUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.floorName} ${item.roomNumber}号室',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (item.description != null)
                    Text(item.description!,
                        style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(dateStr,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                  Text('登録: ${item.registeredBy}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      item.status.displayName,
                      style: TextStyle(color: statusColor, fontSize: 12),
                    ),
                  ),
                  if (item.completedAt != null)
                    Text(
                      '完了: ${DateFormat('yyyy/MM/dd').format(item.completedAt!)}',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ),
            if (item.status == LostItemStatus.storing)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(lostItemServiceProvider)
                          .completeLostItem(item.id, LostItemStatus.returned);
                    },
                    child: const Text('返却済み'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () async {
                      await ref
                          .read(lostItemServiceProvider)
                          .completeLostItem(item.id, LostItemStatus.disposed);
                    },
                    child: const Text('廃棄済み'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showPhoto(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: CachedNetworkImage(imageUrl: item.photoUrl),
      ),
    );
  }

  Color _statusColor(LostItemStatus status) {
    switch (status) {
      case LostItemStatus.storing:
        return Colors.orange;
      case LostItemStatus.returned:
        return Colors.green;
      case LostItemStatus.disposed:
        return Colors.grey;
    }
  }
}
