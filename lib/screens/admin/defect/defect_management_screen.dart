import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hotel_cleaning_app/models/defect_report.dart';
import 'package:hotel_cleaning_app/providers/providers.dart';
import 'package:intl/intl.dart';

class DefectManagementScreen extends ConsumerStatefulWidget {
  const DefectManagementScreen({super.key});

  @override
  ConsumerState<DefectManagementScreen> createState() =>
      _DefectManagementScreenState();
}

class _DefectManagementScreenState
    extends ConsumerState<DefectManagementScreen> {
  DefectStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final defectsAsync = ref.watch(activeDefectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('不具合・故障台帳'),
      ),
      body: Column(
        children: [
          _FilterBar(
            selected: _filterStatus,
            onChanged: (v) => setState(() => _filterStatus = v),
          ),
          Expanded(
            child: defectsAsync.when(
              data: (defects) {
                final filtered = _filterStatus == null
                    ? defects
                    : defects
                        .where((d) => d.status == _filterStatus)
                        .toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('不具合報告はありません'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _DefectCard(defect: filtered[i]),
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
  final DefectStatus? selected;
  final ValueChanged<DefectStatus?> onChanged;

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
          ...DefectStatus.values
              .where((s) => s != DefectStatus.repaired)
              .map((s) => Padding(
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

class _DefectCard extends ConsumerWidget {
  final DefectReport defect;

  const _DefectCard({required this.defect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat('MM/dd HH:mm').format(defect.registeredAt);
    final statusColor = _statusColor(defect.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                '${defect.floorName} ${defect.roomNumber}号室 - ${defect.location.displayName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                defect.status.displayName,
                style: TextStyle(color: statusColor, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Text(dateStr,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (defect.photoUrls.isNotEmpty) ...[
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: defect.photoUrls.length,
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => _showPhoto(context, defect.photoUrls[i]),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: defect.photoUrls[i],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (defect.notes != null) ...[
                  Text('メモ: ${defect.notes}',
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                ],
                Text('登録者: ${defect.registeredBy}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                _StatusActions(defect: defect),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPhoto(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: CachedNetworkImage(imageUrl: url),
      ),
    );
  }

  Color _statusColor(DefectStatus status) {
    switch (status) {
      case DefectStatus.pending:
        return Colors.red;
      case DefectStatus.inProgress:
        return Colors.orange;
      case DefectStatus.waitingRepair:
        return Colors.purple;
      case DefectStatus.repaired:
        return Colors.green;
    }
  }
}

class _StatusActions extends ConsumerStatefulWidget {
  final DefectReport defect;

  const _StatusActions({required this.defect});

  @override
  ConsumerState<_StatusActions> createState() => _StatusActionsState();
}

class _StatusActionsState extends ConsumerState<_StatusActions> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final service = ref.read(defectServiceProvider);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (widget.defect.status == DefectStatus.pending)
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              await service.updateDefectStatus(
                  widget.defect.id, DefectStatus.inProgress);
            },
            child: const Text('対応中にする'),
          ),
        if (widget.defect.status == DefectStatus.inProgress)
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: () async {
              await service.updateDefectStatus(
                  widget.defect.id, DefectStatus.waitingRepair);
            },
            child: const Text('修繕待ちにする'),
          ),
        if (widget.defect.status != DefectStatus.repaired)
          OutlinedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text('完了写真を撮影して修繕完了'),
            onPressed: _completeWithPhoto,
          ),
      ],
    );
  }

  Future<void> _completeWithPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.camera, imageQuality: 80);
    if (picked == null) return;

    setState(() => _isLoading = true);
    try {
      final service = ref.read(defectServiceProvider);
      final bytes = await picked.readAsBytes();
      await service.completeDefect(
        widget.defect.id,
        completionPhoto: bytes,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
