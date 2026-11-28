import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/localization/l10n.dart';
import '../../core/push/push_service.dart';
import '../core/desk_push.dart';
import '../core/desk_session.dart';
import '../core/gym_paused.dart';
import '../features/messages/data/staff_inbox.dart';
import '../features/messages/presentation/inbox_page.dart';
import '../features/offline/data/door_list_controller.dart';
import '../features/scan/data/scan_outbox.dart';
import 'staff_routes.dart';

/// The desk's three tabs: the scanner, checking in at the desk, and today.
/// Each opens fresh, so the camera only runs on the scanner. While scans
/// wait for the internet, it tries sending them every [retryEvery] and when
/// the app comes back to the front. Messages are checked every
/// [checkMessagesEvery] and on coming back, for the bell. It keeps the
/// phone's push token on the server for staff pushes; one arriving while
/// the app is open shows as a banner, and a tapped one opens its message.
class DeskShell extends ConsumerStatefulWidget {
  const DeskShell({super.key, required this.location, required this.child});

  static const tabs = [StaffRoutes.scan, StaffRoutes.desk, StaffRoutes.today];
  static const retryEvery = Duration(seconds: 30);
  static const checkMessagesEvery = Duration(minutes: 2);

  /// How often the door list is downloaded again, as the API asks.
  static const refreshDoorListEvery = Duration(minutes: 15);

  final String location;
  final Widget child;

  @override
  ConsumerState<DeskShell> createState() => _DeskShellState();
}

class _DeskShellState extends ConsumerState<DeskShell> {
  late final Timer _retry;
  late final Timer _checkMessages;
  late final Timer _refreshDoorList;
  late final AppLifecycleListener _lifecycle;
  final _pushes = <StreamSubscription<PushMessage>>[];

  @override
  void initState() {
    super.initState();
    _retry = Timer.periodic(DeskShell.retryEvery, (_) => _sendWaiting());
    _checkMessages = Timer.periodic(DeskShell.checkMessagesEvery, (_) => _refreshMessages());
    _refreshDoorList = Timer.periodic(
      DeskShell.refreshDoorListEvery,
      (_) => unawaited(ref.read(doorListProvider.notifier).refresh()),
    );
    _lifecycle = AppLifecycleListener(
      onResume: () {
        _sendWaiting();
        _refreshMessages();
      },
    );
    final push = ref.read(pushServiceProvider);
    _pushes
      ..add(push.received.listen(_received))
      ..add(push.opened.listen((message) => unawaited(_open(message))));
    unawaited(
      push.takeLaunchMessage().then((message) {
        if (message != null && mounted) unawaited(_open(message));
      }),
    );
  }

  /// Whether [message] is for the gym the desk is at; others wait in that
  /// gym's inbox.
  bool _isHere(PushMessage message) => switch (ref.read(deskSessionProvider)) {
    DeskSignedIn(gym: final gym?) => message.organizationId == null || message.organizationId == gym.slug,
    _ => false,
  };

  void _received(PushMessage message) {
    _refreshMessages();
    if (!_isHere(message) || !mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message.title ?? l10n.deskInboxTitle),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(label: l10n.deskViewMessage, onPressed: () => unawaited(_open(message))),
        ),
      );
  }

  /// Opens the message a push is about, read fresh from the inbox; the
  /// inbox itself when it isn't there or is for another gym.
  Future<void> _open(PushMessage message) async {
    final inbox = ref.read(staffInboxProvider.notifier);
    await inbox.refresh();
    if (!mounted) return;
    final found = _isHere(message)
        ? ref.read(staffInboxProvider).messages.where((each) => each.id == message.notificationId).firstOrNull
        : null;
    if (found == null) {
      unawaited(context.push(StaffRoutes.inbox));
    } else {
      unawaited(showStaffMessage(context, found));
    }
  }

  void _sendWaiting() {
    if (ref.read(scanOutboxProvider).pending.isNotEmpty) unawaited(ref.read(scanOutboxProvider.notifier).flush());
  }

  void _refreshMessages() => unawaited(ref.read(staffInboxProvider.notifier).refresh());

  @override
  void dispose() {
    _retry.cancel();
    _checkMessages.cancel();
    _refreshDoorList.cancel();
    for (final subscription in _pushes) {
      unawaited(subscription.cancel());
    }
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..watch(deskPushTokenSyncProvider)
      // Keeps the door list loaded and fresh while the desk is open.
      ..listen(doorListProvider, (_, _) {});
    final l10n = context.l10n;
    final paused = ref.watch(deskGymPausedProvider);
    return Scaffold(
      body: paused
          ? Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: MaterialBanner(
                    key: const Key('gym-paused'),
                    leading: const Icon(Icons.pause_circle_outline_rounded),
                    content: Text(l10n.gymPausedStaff),
                    actions: const [SizedBox.shrink()],
                  ),
                ),
                Expanded(child: MediaQuery.removePadding(context: context, removeTop: true, child: widget.child)),
              ],
            )
          : widget.child,
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
