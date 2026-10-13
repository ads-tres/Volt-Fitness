import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/auth/session.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/design/brand.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/controls.dart';
import '../../../core/design/widgets/surfaces.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/language_menu.dart';

/// The member's start screen, in their gym's colours. Phase 3 adds the
/// membership summary, payment status and recent visits.
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

    return SoftBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.paddingOf(context).bottom + 24),
          children: [
            ScreenHeader(
              leading: GymAvatar(brand: brand),
              title: brand.name,
              trailing: const LanguageMenu(),
            ),
            const SizedBox(height: 28),
            Text(
              firstName == null ? l10n.greetingNoName : l10n.greeting(firstName),
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(l10n.welcomeBack(brand.name), style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            DarkActionCard(
              icon: Icons.qr_code_2_rounded,
              title: l10n.showQrTitle,
              subtitle: l10n.showQrSubtitle,
              onTap: () => context.go(AppRoutes.qr),
            ),
            const SizedBox(height: 28),
            SectionHeader(l10n.quickAccess),
            Row(
              children: [
                Expanded(
                  child: _QuickTile(
                    icon: Icons.card_membership_rounded,
                    label: l10n.navMembership,
                    onTap: () => context.go(AppRoutes.membership),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickTile(
                    icon: Icons.account_balance_wallet_rounded,
                    label: l10n.navPayments,
                    onTap: () => context.go(AppRoutes.payments),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickTile(
                    icon: Icons.person_rounded,
                    label: l10n.navProfile,
                    onTap: () => context.go(AppRoutes.profile),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SectionHeader(l10n.yourGym),
            AppCard(
              child: Row(
                children: [
                  GymAvatar(brand: brand, size: 52),
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
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
    child: Column(
      children: [
        IconTile(icon: icon, size: 46),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, maxLines: 1, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 13)),
        ),
      ],
    ),
  );
}
