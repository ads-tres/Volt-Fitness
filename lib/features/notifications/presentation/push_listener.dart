import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/auth/session.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/design/tokens.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/push/push_service.dart';
import '../../../core/push/push_token_sync.dart';
import '../../home/data/dashboard_repository.dart';
import '../data/inbox_controller.dart';
import '../domain/app_notification.dart';
import 'notification_routes.dart';
import 'notifications_page.dart';

/// Handles pushes while a member is signed in: keeps the token on the
/// server, opens what a tapped notification points at, and shows a banner
/// for one that arrives while the app is open.
class PushListener extends ConsumerStatefulWidget {
  const PushListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushListener> createState() => _PushListenerState();
}

class _PushListenerState extends ConsumerState<PushListener> {
  static const _bannerTime = Duration(seconds: 6);

  final _subscriptions = <StreamSubscription<PushMessage>>[];
  late final AppLifecycleListener _lifecycle;
  OverlayEntry? _banner;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    final push = ref.read(pushServiceProvider);
    _subscriptions
      ..add(push.received.listen(_received))
      ..add(push.opened.listen(_open));
    _lifecycle = AppLifecycleListener(onResume: _resumed);
    unawaited(
      push.takeLaunchMessage().then((message) {
        if (message != null && mounted) unawaited(_open(message));
      }),
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _lifecycle.dispose();
    _hideBanner();
    super.dispose();
  }

  /// Pushes that arrived in the background changed the unread count, and
  /// the member may have allowed notifications in the phone's settings.
  void _resumed() {
    unawaited(ref.read(inboxProvider.notifier).refresh());
    ref.invalidate(pushPermissionProvider);
  }

  void _received(PushMessage message) {
    _refreshFor(message);
    _showBanner(message);
  }

  /// The push's data may be stale by the time it is tapped, so the target
  /// screen loads fresh data; the push only says where to go. A push for
  /// another of the member's gyms switches to that gym first.
  Future<void> _open(PushMessage message) async {
    _hideBanner();
    final session = ref.read(sessionControllerProvider);
    if (session is! SignedIn) return;
    var route = notificationRoute(message.type, message.data) ?? AppRoutes.notifications;
    if (message.organizationId case final organizationId? when organizationId != session.organizationId) {
      if (session.profile.organization(organizationId) == null) {
        // A gym the member has left: nothing there to open.
        route = AppRoutes.notifications;
      } else {
        await ref.read(sessionControllerProvider.notifier).selectOrganization(organizationId);
      }
    }
    if (!mounted) return;
    final inbox = ref.read(inboxProvider.notifier);
    if (message.notificationId case final id?) {
      unawaited(inbox.markRead(id).then((_) => inbox.refresh()));
    }
    _refreshFor(message, inbox: false);
    context.go(route);
  }

  void _refreshFor(PushMessage message, {bool inbox = true}) {
    if (inbox) unawaited(ref.read(inboxProvider.notifier).refresh());
    if (topicOf(message.type) case NotificationTopic.membership || NotificationTopic.payments) {
      unawaited(ref.read(dashboardProvider.notifier).refresh());
    }
  }

  void _showBanner(PushMessage message) {
    _hideBanner();
    final entry = OverlayEntry(
      builder: (context) =>
          _PushBanner(message: message, onTap: () => unawaited(_open(message)), onDismiss: _hideBanner),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    _banner = entry;
    _bannerTimer = Timer(_bannerTime, _hideBanner);
  }

  void _hideBanner() {
    _bannerTimer?.cancel();
    _bannerTimer = null;
    _banner?.remove();
    _banner = null;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(pushTokenSyncProvider);
    return widget.child;
  }
}

/// A notification arriving while the app is open, sliding in at the top.
/// Tap to open it; swipe it up to dismiss.
class _PushBanner extends StatelessWidget {
  const _PushBanner({required this.message, required this.onTap, required this.onDismiss});

  final PushMessage message;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = message.title ?? context.l10n.notificationsTitle;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -1, end: 0),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            builder: (context, offset, child) => FractionalTranslation(translation: Offset(0, offset), child: child),
            child: Dismissible(
              key: const ValueKey('push-banner'),
              direction: DismissDirection.up,
              onDismissed: (_) => onDismiss(),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(AppRadii.card)),
                  boxShadow: AppShadows.raised,
                ),
                child: Material(
                  color: AppColors.surface,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadii.card))),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          TopicBadge(topic: topicOf(message.type), size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.titleSmall),
                                if (message.body case final body? when body.isNotEmpty)
                                  Text(
                                    body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
