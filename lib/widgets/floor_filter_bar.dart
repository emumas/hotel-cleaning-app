import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_cleaning_app/models/floor.dart';
import 'package:hotel_cleaning_app/providers/providers.dart';

class FloorFilterBar extends StatelessWidget {
  final bool showAll;
  final ValueChanged<bool> onShowAllChanged;

  const FloorFilterBar(
      {super.key, required this.showAll, required this.onShowAllChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('表示：'),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('フロア別'),
            selected: !showAll,
            onSelected: (_) => onShowAllChanged(false),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('全体'),
            selected: showAll,
            onSelected: (_) => onShowAllChanged(true),
          ),
        ],
      ),
    );
  }
}

class FloorTabBar extends ConsumerWidget {
  final List<Floor> floors;

  const FloorTabBar({super.key, required this.floors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedFloorIdProvider);
    if (floors.isEmpty) return const SizedBox.shrink();

    if (selectedId == null && floors.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedFloorIdProvider.notifier).state = floors.first.id;
      });
    }

    return Container(
      color: Colors.white,
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: floors.length,
        itemBuilder: (context, i) {
          final floor = floors[i];
          final selected = floor.id == selectedId;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: FilterChip(
              label: Text(floor.name),
              selected: selected,
              onSelected: (_) {
                ref.read(selectedFloorIdProvider.notifier).state = floor.id;
              },
            ),
          );
        },
      ),
    );
  }
}
