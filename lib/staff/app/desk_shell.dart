import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/localization/l10n.dart';
import 'staff_routes.dart';

/// The desk's three tabs: the scanner, checking in at the desk, and today.
/// Each opens fresh, so the camera only runs on the scanner.
class DeskShell extends StatelessWidget {
  const DeskShell({super.key, required this.location, required this.child});

  static const tabs = [StaffRoutes.scan, StaffRoutes.desk, StaffRoutes.today];

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabs.indexWhere(location.startsWith).clamp(0, tabs.length - 1),
        onDestinationSelected: (index) => context.go(tabs[index]),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.qr_code_scanner_rounded), label: l10n.deskTabScan),
          NavigationDestination(icon: const Icon(Icons.person_search_rounded), label: l10n.deskTabDesk),
          NavigationDestination(icon: const Icon(Icons.today_rounded), label: l10n.deskTabToday),
        ],
      ),
    );
  }
}
