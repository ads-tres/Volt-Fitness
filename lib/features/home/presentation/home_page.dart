import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/auth/session.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/design/brand.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/controls.dart';
import '../../../core/design/widgets/feedback.dart';
import '../../../core/design/widgets/surfaces.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_text.dart';
import '../../../core/time/local_date.dart';
import '../../../l10n/app_localizations.dart';
import '../../attendance/presentation/visit_card.dart';
import '../../membership/domain/membership.dart';
import '../../notifications/data/inbox_controller.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../../notifications/presentation/push_permission_card.dart';
import '../../payments/presentation/payments_page.dart';
import '../data/dashboard_repository.dart';
import 'membership_gauge.dart';

/// The member's start screen, in their gym's colours: how much of the plan
/// is left, the way to the QR, and the latest visits.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final brand = context.brand;
    final session = ref.watch(sessionControllerProvider);
    if (session is! SignedIn) return const SizedBox.shrink();
    final firstName = session.profile.user.firstName;
    final contactPhone = session.organization?.branding.contactPhone;
    final loaded = ref.watch(dashboardProvider);
    final dashboard = loaded.value;
    final today = ref.watch(todayProvider);
    final membership = dashboard?.membership;
    final canRenew =
        membership != null && (membership.endsSoon(today) || membership.status == MembershipStatus.expired);

    return SoftBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () =>
              Future.wait([ref.read(dashboardProvider.notifier).refresh(), ref.read(inboxProvider.notifier).refresh()]),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              ScreenHeader(
                leading: GymAvatar(brand: brand),
                title: brand.name,
                trailing: const NotificationBell(),
              ),
              const SizedBox(height: 20),
              Text(firstName == null ? l10n.greetingNoName : l10n.greeting(firstName), style: textTheme.headlineSmall),
              if (loaded.failure != null && dashboard != null) ...[const SizedBox(height: 12), const OfflineNotice()],
              const SizedBox(height: 12),
              if (dashboard == null && loaded.failure != null)
                LoadFailedCard(failure: loaded.failure!, onRetry: () => ref.read(dashboardProvider.notifier).refresh())
              else ...[
                if (dashboard == null)
                  const MembershipGauge(
                    share: 0,
                    color: MembershipGauge.emptyColor,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
                  )
                else
                  _Gauge(membership: membership, today: today),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _PillButton(
                        icon: Icons.qr_code_scanner_rounded,
                        label: l10n.showQrTitle,
                        onTap: () => context.go(AppRoutes.qr),
                      ),
                    ),
                    if (canRenew) ...[
                      const SizedBox(width: 10),
                      _PillButton(
                        icon: Icons.autorenew_rounded,
                        label: l10n.renew,
                        filled: true,
                        onTap: () => context.go(AppRoutes.payments),
                      ),
                    ],
                  ],
                ),
                if (dashboard?.outstanding case final outstanding?) ...[
                  const SizedBox(height: 16),
                  DueCard(outstanding: outstanding, compact: true),
                ],
                if (!ref.watch(pushOfferDismissedProvider))
                  PushPermissionCard(
                    padding: const EdgeInsets.only(top: 16),
                    onNotNow: ref.read(pushOfferDismissedProvider.notifier).dismiss,
                  ),
                const SizedBox(height: 28),
                SectionHeader(
                  l10n.recentVisits,
                  action: TextButton(onPressed: () => context.go(AppRoutes.visits), child: Text(l10n.seeAll)),
                ),
                if (dashboard != null && dashboard.recentVisits.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      l10n.noVisitsYet,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                for (final visit in dashboard?.recentVisits.take(3) ?? const <Never>[])
                  Padding(padding: const EdgeInsets.only(bottom: 12), child: VisitCard(visit: visit)),
              ],
              const SizedBox(height: 16),
              SectionHeader(l10n.yourGym),
              AppCard(
                child: Row(
                  children: [
                    GymAvatar(brand: brand, size: 52, round: true),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(brand.name, style: textTheme.titleMedium),
                          if (contactPhone != null) ...[
                            const SizedBox(height: 2),
                            Text('${l10n.frontDesk} · $contactPhone', style: textTheme.bodySmall),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Gauge extends ConsumerWidget {
  const _Gauge({required this.membership, required this.today});

  final Membership? membership;
  final LocalDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final brand = context.brand;
    final dates = ref.watch(dateTextProvider);
    final membership = this.membership;
    final (:share, :color, :top, :big, :caption, :captionIsWarning) = _describe(l10n, dates, brand.primary, membership);
    final textTheme = Theme.of(context).textTheme;

    return MembershipGauge(
      share: share,
      color: color,
      child: Column(
        children: [
          Icon(Icons.bolt_rounded, color: brand.primary, size: 24),
          if (top != null) Text(top, style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 13)),
          Text(big, style: textTheme.headlineMedium?.copyWith(fontSize: 32, letterSpacing: -0.6)),
          if (caption != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 52),
              child: Text(
                caption,
                textAlign: TextAlign.center,
                style: textTheme.labelLarge?.copyWith(
                  color: captionIsWarning ? AppColors.danger : brand.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  ({double share, Color color, String? top, String big, String? caption, bool captionIsWarning}) _describe(
    AppLocalizations l10n,
    DateText dates,
    Color primary,
    Membership? membership,
  ) {
    if (membership == null) {
      return (share: 0, color: primary, top: null, big: l10n.gaugeNoPlan, caption: l10n.gaugeNoPlanHint, captionIsWarning: false);
    }
    final daysLeft = membership.daysLeft(today);
    final faded = Color.lerp(primary, Colors.white, 0.55)!;
    return switch (membership.status) {
      MembershipStatus.expired => (
        share: 0,
        color: primary,
        top: l10n.gaugeEnded(dates.dayMonth(membership.endsOn)),
        big: l10n.gaugeExpired,
        caption: membership.planName,
        captionIsWarning: false,
      ),
      MembershipStatus.frozen => (
        share: membership.shareLeft(today),
        color: faded,
        top: l10n.gaugeUntil(dates.dayMonth(membership.frozenUntil ?? membership.endsOn)),
        big: l10n.gaugeFrozen,
        caption: membership.planName,
        captionIsWarning: false,
      ),
      MembershipStatus.pending => (
        share: 1,
        color: faded,
        top: l10n.gaugeStarts(dates.dayMonth(membership.startsOn)),
        big: l10n.gaugeStartsSoon,
        caption: membership.planName,
        captionIsWarning: false,
      ),
      MembershipStatus.cancelled => (
        share: 0,
        color: primary,
        top: null,
        big: l10n.gaugeCancelled,
        caption: membership.planName,
        captionIsWarning: false,
      ),
      MembershipStatus.active || MembershipStatus.unknown => (
        share: membership.shareLeft(today),
        color: primary,
        top: daysLeft == 0 ? l10n.gaugeEndsToday : l10n.gaugeEnds(dates.dayMonth(membership.endsOn)),
        big: daysLeft == 0 ? l10n.gaugeLastDay : l10n.gaugeDays(daysLeft),
        caption: membership.endsSoon(today) ? l10n.gaugeRenewSoon : membership.planName,
        captionIsWarning: membership.endsSoon(today),
      ),
    };
  }
}

/// A wide rounded button under the gauge.
class _PillButton extends StatelessWidget {
  const _PillButton({required this.icon, required this.label, required this.onTap, this.filled = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final foreground = filled ? brand.onPrimary : AppColors.ink;
    return Material(
      color: filled ? brand.primary : const Color(0xFFE9E4DD),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: foreground),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
