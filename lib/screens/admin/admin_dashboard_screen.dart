import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_cleaning_app/core/constants/app_colors.dart';
import 'package:hotel_cleaning_app/models/room.dart';
import 'package:hotel_cleaning_app/models/user_role.dart';
import 'package:hotel_cleaning_app/providers/providers.dart';
import 'package:hotel_cleaning_app/widgets/floor_filter_bar.dart';
import 'package:hotel_cleaning_app/widgets/room_card.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理者'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).state = null,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '客室'),
            Tab(text: 'マスター'),
            Tab(text: '不具合'),
            Tab(text: '忘れ物'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RoomTab(
            showAll: _showAll,
            onShowAllChanged: (v) => setState(() => _showAll = v),
          ),
          const _MasterTab(),
          const _DefectTab(),
          const _LostItemTab(),
        ],
      ),
    );
  }
}

class _RoomTab extends ConsumerWidget {
  final bool showAll;
  final ValueChanged<bool> onShowAllChanged;

  const _RoomTab({required this.showAll, required this.onShowAllChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final floors = ref.watch(floorsProvider);
    final selectedFloorId = ref.watch(selectedFloorIdProvider);
    final roomsAsync =
        ref.watch(roomsProvider(showAll ? null : selectedFloorId));

    return Column(
      children: [
        FloorFilterBar(showAll: showAll, onShowAllChanged: onShowAllChanged),
        if (!showAll)
          floors.when(
            data: (fl) => FloorTabBar(floors: fl),
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
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AdminRoomCard(room: rooms[i]),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('エラー: $e')),
          ),
        ),
      ],
    );
  }
}

class _AdminRoomCard extends ConsumerWidget {
  final Room room;

  const _AdminRoomCard({required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RoomCard(
      room: room,
      onTap: () => _showAdminActions(context, ref),
    );
  }

  void _showAdminActions(BuildContext context, WidgetRef ref) {
    final service = ref.read(roomServiceProvider);
    final userName = ref.read(currentUserNameProvider);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                '${room.floorName} ${room.number}号室',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(room.status.displayName),
            ),
            const Divider(),
            if (room.status == RoomStatus.inspectionOk)
              ListTile(
                leading: const Icon(Icons.sell, color: Colors.teal),
                title: const Text('販売可にする'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await service.updateRoomStatus(
                      room.id, RoomStatus.available, userName);
                },
              ),
            ListTile(
              leading: const Icon(Icons.restart_alt, color: Colors.orange),
              title: const Text('未着手に戻す'),
              onTap: () async {
                Navigator.pop(ctx);
                await service.updateRoomStatus(
                    room.id, RoomStatus.notStarted, userName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem, color: Colors.red),
              title: const Text('不具合報告'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/admin/defect-report/${room.id}', extra: {
                  'roomNumber': room.number,
                  'floorName': room.floorName,
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.search, color: Colors.blue),
              title: const Text('忘れ物登録'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/admin/lost-item/${room.id}', extra: {
                  'roomNumber': room.number,
                  'floorName': room.floorName,
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MasterTab extends ConsumerWidget {
  const _MasterTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AdminMenuCard(
          icon: Icons.apartment,
          title: 'フロア・客室管理',
          subtitle: 'フロアや客室の追加・編集・削除',
          color: AppColors.primary,
          onTap: () => context.go('/admin/floors'),
        ),
        const SizedBox(height: 12),
        _AdminMenuCard(
          icon: Icons.pin,
          title: 'PINコード管理',
          subtitle: '各ロールのPINコードを変更',
          color: Colors.purple,
          onTap: () => showDialog(
            context: context,
            builder: (_) => const _PinManagementDialog(),
          ),
        ),
        const SizedBox(height: 12),
        _AdminMenuCard(
          icon: Icons.restart_alt,
          title: '全客室リセット',
          subtitle: '全客室のステータスを未着手に戻す',
          color: Colors.orange,
          onTap: () => _confirmResetAll(context, ref),
        ),
      ],
    );
  }

  void _confirmResetAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('全客室リセット'),
        content: const Text('全客室のステータスを「未着手」に戻しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(roomServiceProvider).resetAllRooms();
            },
            child: const Text('リセット'),
          ),
        ],
      ),
    );
  }
}

class _DefectTab extends StatelessWidget {
  const _DefectTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _AdminMenuCard(
        icon: Icons.build,
        title: '不具合・故障台帳',
        subtitle: '不具合の対応状況を管理',
        color: Colors.red,
        onTap: () => context.go('/admin/defects'),
      ),
    );
  }
}

class _LostItemTab extends StatelessWidget {
  const _LostItemTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _AdminMenuCard(
        icon: Icons.luggage,
        title: '忘れ物台帳',
        subtitle: '忘れ物の保管・返却・廃棄を管理',
        color: Colors.indigo,
        onTap: () => context.go('/admin/lost-items'),
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinManagementDialog extends ConsumerStatefulWidget {
  const _PinManagementDialog();

  @override
  ConsumerState<_PinManagementDialog> createState() =>
      _PinManagementDialogState();
}

class _PinManagementDialogState extends ConsumerState<_PinManagementDialog> {
  final _staffCtrl = TextEditingController();
  final _inspectorCtrl = TextEditingController();
  final _adminCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('PINコード管理'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('変更したいPINを入力してください（4〜6桁）',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: _staffCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: '清掃スタッフ PIN'),
              obscureText: true,
            ),
            TextField(
              controller: _inspectorCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: '点検者 PIN'),
              obscureText: true,
            ),
            TextField(
              controller: _adminCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: '管理者 PIN'),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('保存'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final service = ref.read(authServiceProvider);
      if (_staffCtrl.text.length >= 4) {
        await service.updatePin(UserRole.staff, _staffCtrl.text);
      }
      if (_inspectorCtrl.text.length >= 4) {
        await service.updatePin(UserRole.inspector, _inspectorCtrl.text);
      }
      if (_adminCtrl.text.length >= 4) {
        await service.updatePin(UserRole.admin, _adminCtrl.text);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
