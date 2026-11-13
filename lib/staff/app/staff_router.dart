import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/scan/presentation/scan_page.dart';
import 'staff_routes.dart';

export 'staff_routes.dart';

final staffRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: StaffRoutes.scan,
    routes: [
      GoRoute(path: '/', redirect: (context, state) => StaffRoutes.scan),
      GoRoute(path: StaffRoutes.scan, builder: (context, state) => const ScanPage()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
