import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/brand.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/surfaces.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/push/push_service.dart';
import '../../../core/storage/preferences_store.dart';

/// The member answered "Not now" to the home screen's offer. Kept on the
/// phone across sign-ins, like the system's own answer.
final class PushOfferDismissed extends Notifier<bool> {
  static const _key = 'push.offer_dismissed';

  @override
  bool build() => ref.watch(preferencesStoreProvider).getString(_key) == 'true';

  Future<void> dismiss() async {
    await ref.read(preferencesStoreProvider).setString(_key, 'true');
    state = true;
  }
}

final pushOfferDismissedProvider = NotifierProvider<PushOfferDismissed, bool>(PushOfferDismissed.new);

/// Says why notifications help before the system prompt asks, or, once the
/// member has blocked them, how to turn them back on. Shows nothing when
/// notifications are allowed or the build can't receive them.
class PushPermissionCard extends ConsumerWidget {
  const PushPermissionCard({super.key, this.onNotNow, this.padding = EdgeInsets.zero});

  /// Makes it a one-time offer with a "Not now" button, for the home
  /// screen. An offer is never shown to a member who already said no.
  final VoidCallback? onNotNow;

  /// Around the card when it shows, so a hidden card leaves no gap.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(pushServiceProvider).isAvailable) return const SizedBox.shrink();
    final permission = ref.watch(pushPermissionProvider).value;
    final blocked = permission == PushPermission.denied;
    if (permission == null || permission == PushPermission.granted || (blocked && onNotNow != null)) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final brand = context.brand;
    final controller = ref.read(pushPermissionProvider.notifier);
    return Padding(
      padding: padding,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconTile(
                  icon: blocked ? Icons.notifications_off_rounded : Icons.notifications_active_rounded,
                  size: 44,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(blocked ? l10n.pushBlockedTitle : l10n.pushPromptTitle, style: textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        blocked ? l10n.pushBlockedBody : l10n.pushPromptBody,
                        style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onNotNow case final onNotNow?) TextButton(onPressed: onNotNow, child: Text(l10n.notNow)),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    backgroundColor: brand.primary,
                    foregroundColor: brand.onPrimary,
                  ),
                  onPressed: blocked ? controller.openSettings : controller.request,
                  child: Text(blocked ? l10n.openSettings : l10n.turnOn),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
