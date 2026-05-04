import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_cleaning_app/models/user_role.dart';
import 'package:hotel_cleaning_app/providers/providers.dart';
import 'package:hotel_cleaning_app/screens/auth/pin_login_screen.dart';
import 'package:hotel_cleaning_app/screens/staff/staff_room_list_screen.dart';
import 'package:hotel_cleaning_app/screens/staff/staff_room_detail_screen.dart';
import 'package:hotel_cleaning_app/screens/inspector/inspector_room_list_screen.dart';
import 'package:hotel_cleaning_app/screens/inspector/inspector_room_detail_screen.dart';
import 'package:hotel_cleaning_app/screens/admin/admin_dashboard_screen.dart';
import 'package:hotel_cleaning_app/screens/admin/master/floor_management_screen.dart';
import 'package:hotel_cleaning_app/screens/admin/defect/defect_management_screen.dart';
import 'package:hotel_cleaning_app/screens/admin/lost_item/lost_item_ledger_screen.dart';
import 'package:hotel_cleaning_app/screens/shared/defect_report_screen.dart';
import 'package:hotel_cleaning_app/screens/shared/lost_item_register_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final role = _ref.read(authProvider);
    final isLogin = state.matchedLocation == '/login';
    if (role == null && !isLogin) return '/login';
    if (role != null && isLogin) {
      return switch (role) {
        UserRole.staff => '/staff',
        UserRole.inspector => '/inspector',
        UserRole.admin => '/admin',
      };
    }
    return null;
  }
}

final routerNotifierProvider = Provider((ref) => RouterNotifier(ref));

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  return GoRouter(
    initialLocation: '/login',
    redirect: notifier.redirect,
    refreshListenable: notifier,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const PinLoginScreen(),
      ),

      // Staff routes
      GoRoute(
        path: '/staff',
        builder: (context, state) => const StaffRoomListScreen(),
        routes: [
          GoRoute(
            path: 'room/:roomId',
            builder: (context, state) => StaffRoomDetailScreen(
              roomId: state.pathParameters['roomId']!,
            ),
          ),
          GoRoute(
            path: 'lost-item/:roomId',
            builder: (context, state) => LostItemRegisterScreen(
              roomId: state.pathParameters['roomId']!,
              extra: state.extra as Map<String, dynamic>?,
            ),
          ),
        ],
      ),

      // Inspector routes
      GoRoute(
        path: '/inspector',
        builder: (context, state) => const InspectorRoomListScreen(),
        routes: [
          GoRoute(
            path: 'room/:roomId',
            builder: (context, state) => InspectorRoomDetailScreen(
              roomId: state.pathParameters['roomId']!,
            ),
          ),
          GoRoute(
            path: 'defect/:roomId',
            builder: (context, state) => DefectReportScreen(
              roomId: state.pathParameters['roomId']!,
              extra: state.extra as Map<String, dynamic>?,
            ),
          ),
          GoRoute(
            path: 'lost-item/:roomId',
            builder: (context, state) => LostItemRegisterScreen(
              roomId: state.pathParameters['roomId']!,
              extra: state.extra as Map<String, dynamic>?,
            ),
          ),
        ],
      ),

      // Admin routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'floors',
            builder: (context, state) => const FloorManagementScreen(),
          ),
          GoRoute(
            path: 'defects',
            builder: (context, state) => const DefectManagementScreen(),
          ),
          GoRoute(
            path: 'lost-items',
            builder: (context, state) => const LostItemLedgerScreen(),
          ),
          GoRoute(
            path: 'defect-report/:roomId',
            builder: (context, state) => DefectReportScreen(
              roomId: state.pathParameters['roomId']!,
              extra: state.extra as Map<String, dynamic>?,
            ),
          ),
          GoRoute(
            path: 'lost-item/:roomId',
            builder: (context, state) => LostItemRegisterScreen(
              roomId: state.pathParameters['roomId']!,
              extra: state.extra as Map<String, dynamic>?,
            ),
          ),
        ],
      ),
    ],
  );
});
