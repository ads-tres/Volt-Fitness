import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/localization/l10n.dart';
import '../features/messages/data/staff_inbox.dart';
import '../features/scan/data/scan_outbox.dart';
import 'staff_routes.dart';

/// The desk's three tabs: the scanner, checking in at the desk, and today.
/// Each opens fresh, so the camera only runs on the scanner. While scans
/// wait for the internet, it tries sending them every [retryEvery] and when
/// the app comes back to the front. Messages are checked every
/// [checkMessagesEvery] and on coming back, for the bell.
class DeskShell extends ConsumerStatefulWidget {
  const DeskShell({super.key, required this.location, required this.child});

  static const tabs = [StaffRoutes.scan, StaffRoutes.desk, StaffRoutes.today];
  static const retryEvery = Duration(seconds: 30);
  static const checkMessagesEvery = Duration(minutes: 2);

  final String location;
  final Widget child;

  @override
  ConsumerState<DeskShell> createState() => _DeskShellState();
}

class _DeskShellState extends ConsumerState<DeskShell> {
  late final Timer _retry;
  late final Timer _checkMessages;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _retry = Timer.periodic(DeskShell.retryEvery, (_) => _sendWaiting());
    _checkMessages = Timer.periodic(DeskShell.checkMessagesEvery, (_) => _refreshMessages());
    _lifecycle = AppLifecycleListener(
      onResume: () {
        _sendWaiting();
        _refreshMessages();
      },
    );
  }

  void _sendWaiting() {
    if (ref.read(scanOutboxProvider).pending.isNotEmpty) unawaited(ref.read(scanOutboxProvider.notifier).flush());
  }

  void _refreshMessages() => unawaited(ref.read(staffInboxProvider.notifier).refresh());

  @override
  void dispose() {
    _retry.cancel();
    _checkMessages.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: DeskShell.tabs.indexWhere(widget.location.startsWith).clamp(0, DeskShell.tabs.length - 1),
        onDestinationSelected: (index) => context.go(DeskShell.tabs[index]),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.qr_code_scanner_rounded), label: l10n.deskTabScan),
          NavigationDestination(icon: const Icon(Icons.person_search_rounded), label: l10n.deskTabDesk),
          NavigationDestination(icon: const Icon(Icons.today_rounded), label: l10n.deskTabToday),
        ],
      ),
    );
  }
}
