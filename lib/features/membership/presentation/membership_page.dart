import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/design/brand.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/controls.dart';
import '../../../core/design/widgets/feedback.dart';
import '../../../core/design/widgets/surfaces.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/language_menu.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_text.dart';
import '../../../l10n/app_localizations.dart';
import '../../attendance/presentation/visit_card.dart';
import '../../home/data/dashboard_repository.dart';
import '../domain/membership.dart';

/// The member's plan at the selected gym: status, dates, what is left and
/// where it works. Read from the same dashboard call as the home screen.
class MembershipPage extends ConsumerWidget {
  const MembershipPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final loaded = ref.watch(dashboardProvider);
    final dashboard = loaded.value;
    final controller = ref.read(dashboardProvider.notifier);

    return SoftBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              ScreenHeader(title: l10n.navMembership, trailing: const LanguageMenu()),
              const SizedBox(height: 24),
              if (loaded.failure != null && dashboard != null) ...[const OfflineNotice(), const SizedBox(height: 16)],
              if (dashboard == null && loaded.failure != null)
                LoadFailedCard(failure: loaded.failure!, onRetry: controller.refresh)
              else if (dashboard == null)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
                )
              else if (dashboard.membership case final membership?)
                _MembershipDetails(membership: membership)
              else
                PhotoMessageCard(
                  photo: 'assets/photos/onboarding_train.jpg',
                  title: l10n.noPlanTitle,
                  body: l10n.noPlanBody,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembershipDetails extends ConsumerWidget {
  const _MembershipDetails({required this.membership});

  final Membership membership;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final brand = context.brand;
    final dates = ref.watch(dateTextProvider);
    final today = ref.watch(todayProvider);
    final daysLeft = membership.daysLeft(today);
    final canRenew = membership.endsSoon(today) || membership.status == MembershipStatus.expired;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PlanBanner(membership: membership),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DateRow(label: l10n.startDate, value: dates.date(membership.startsOn)),
              const Divider(height: 24, color: AppColors.line),
              _DateRow(label: l10n.endDate, value: dates.date(membership.endsOn)),
              if (membership.status == MembershipStatus.active || membership.status == MembershipStatus.frozen) ...[
                const SizedBox(height: 18),
                Text(l10n.daysLeft(daysLeft), style: textTheme.titleSmall),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: membership.shareLeft(today),
                    minHeight: 8,
                    color: brand.primary,
                    backgroundColor: const Color(0xFFE9E4DD),
                  ),
                ),
              ],
              if (membership.visitsRemaining case final visits?) ...[
                const SizedBox(height: 12),
                Text(l10n.visitsLeft(visits), style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              ],
            ],
          ),
        ),
        if (membership.status == MembershipStatus.frozen && membership.frozenUntil != null)
          _Notice(text: l10n.frozenNotice(dates.date(membership.frozenUntil!)), icon: Icons.ac_unit_rounded),
        if (membership.graceEndsOn case final grace? when membership.status == MembershipStatus.expired)
          _Notice(text: l10n.graceNotice(dates.date(grace)), icon: Icons.schedule_rounded),
        if (membership.allowedBranches.isNotEmpty) ...[
          const SizedBox(height: 28),
          SectionHeader(l10n.allowedBranches),
          for (final branch in membership.allowedBranches)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    BranchPhoto(branch: branch, size: 44),
                    const SizedBox(width: 14),
                    Expanded(child: Text(branch.name, style: textTheme.titleMedium)),
                  ],
                ),
              ),
            ),
        ],
        if (canRenew) ...[
          const SizedBox(height: 20),
          PrimaryButton(label: l10n.renewPlan, onPressed: () => context.go(AppRoutes.payments)),
        ],
      ],
    );
  }
}

/// The plan's photo header: its name and status over a gym photo.
class _PlanBanner extends StatelessWidget {
  const _PlanBanner({required this.membership});

  final Membership membership;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.card + 4),
      child: SizedBox(
        height: 180,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/photos/onboarding_train.jpg', fit: BoxFit.cover, alignment: const Alignment(0, -0.3)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.35, 1],
                  colors: [Color(0x00000000), Color(0xCC000000)],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(membership.planName, style: textTheme.headlineSmall?.copyWith(color: Colors.white)),
                  ),
                  _StatusChip(status: membership.status, label: membershipStatusLabel(l10n, membership.status)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.label});

  final MembershipStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final dot = switch (status) {
      MembershipStatus.active => const Color(0xFF12B76A),
      MembershipStatus.frozen || MembershipStatus.pending => const Color(0xFF2E90FA),
      _ => AppColors.danger,
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              child: const SizedBox.square(dimension: 8),
            ),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(width: 16),
        Expanded(child: Text(value, textAlign: TextAlign.end, style: textTheme.titleSmall)),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: DecoratedBox(
      decoration: BoxDecoration(color: const Color(0xFFE9E4DD), borderRadius: BorderRadius.circular(AppRadii.control)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.ink),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      ),
    ),
  );
}

String membershipStatusLabel(AppLocalizations l10n, MembershipStatus status) => switch (status) {
  MembershipStatus.active => l10n.statusActive,
  MembershipStatus.frozen => l10n.statusFrozen,
  MembershipStatus.expired => l10n.statusExpired,
  MembershipStatus.pending => l10n.statusPending,
  MembershipStatus.cancelled => l10n.statusCancelled,
  MembershipStatus.unknown => l10n.statusUnknown,
};
