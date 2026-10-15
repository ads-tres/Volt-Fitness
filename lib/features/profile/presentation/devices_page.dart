import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/brand.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/controls.dart';
import '../../../core/design/widgets/feedback.dart';
import '../../../core/design/widgets/surfaces.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/time/date_text.dart';
import '../../../core/time/local_date.dart';
import '../data/devices.dart';

/// The phones signed in to the member's account. Another phone can be
/// signed out from here, for example a lost one.
class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final devices = ref.watch(devicesProvider);

    return SoftBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(devicesProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              ScreenHeader(
                leading: HeaderButton(
                  tooltip: l10n.back,
                  onPressed: () => context.pop(),
                  child: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                ),
                title: l10n.devices,
              ),
              const SizedBox(height: 24),
              switch (devices) {
                AsyncData(:final value) => Column(
                  children: [
                    for (final device in value)
                      Padding(padding: const EdgeInsets.only(bottom: 12), child: _DeviceCard(device: device)),
                  ],
                ),
                AsyncError(:final error) => LoadFailedCard(
                  failure: error is Failure ? error : const UnexpectedFailure(),
                  onRetry: () => ref.invalidate(devicesProvider),
                ),
                _ => const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceCard extends ConsumerWidget {
  const _DeviceCard({required this.device});

  final SignedInDevice device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final dates = ref.watch(dateTextProvider);
    final lastSeen = device.lastSeenAt;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: const Color(0xFFF2EEE8), borderRadius: BorderRadius.circular(AppRadii.tile)),
            child: Icon(
              device.platform == 'ios' ? Icons.phone_iphone_rounded : Icons.phone_android_rounded,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name, style: textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  device.isCurrent
                      ? l10n.thisPhone
                      : (lastSeen == null ? '' : l10n.lastActive(dates.date(LocalDate.of(lastSeen.toLocal())))),
                  style: textTheme.bodySmall?.copyWith(color: device.isCurrent ? context.brand.primary : null),
                ),
              ],
            ),
          ),
          if (!device.isCurrent)
            TextButton(
              onPressed: () => _confirmSignOut(context, ref),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: Text(l10n.signOut),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.signOutDeviceTitle(device.name)),
        content: Text(l10n.signOutDeviceBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.ink),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await removeDevice(ref, device.id);
    } on Failure catch (failure) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failureMessage(l10n, failure))));
      }
    }
  }
}
