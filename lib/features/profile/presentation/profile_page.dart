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
import '../../../core/device/app_info.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/language_menu.dart';
import '../../../core/utils/ethiopian_phone.dart';
import '../../../core/time/date_text.dart';
import '../../auth/presentation/sign_out.dart';
import 'calendar_sheet.dart';

/// The member, their gym and sign-out. Notification and calendar settings
/// and the device list arrive with Phase 3.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final brand = context.brand;
    final appInfo = ref.watch(appInfoProvider);
    final session = ref.watch(sessionControllerProvider);
    if (session is! SignedIn) return const SizedBox.shrink();
    final user = session.profile.user;
    final initials = (user.name ?? '')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word.characters.first.toUpperCase())
        .join();
    final (light, deep) = brand.gradient;

    return SoftBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            ScreenHeader(title: l10n.navProfile, trailing: const LanguageMenu()),
            const SizedBox(height: 28),
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [light, deep]),
                    ),
                    alignment: Alignment.center,
                    child: initials.isEmpty
                        ? Icon(Icons.person_rounded, color: brand.onPrimary)
                        : Text(initials, style: textTheme.titleMedium?.copyWith(color: brand.onPrimary)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user.name case final name?) Text(name, style: textTheme.titleMedium),
                        Text(
                          EthiopianPhone.format(user.phone),
                          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SectionHeader(l10n.yourGym),
            AppCard(
              child: Row(
                children: [
                  GymAvatar(brand: brand, round: true),
                  const SizedBox(width: 14),
                  Expanded(child: Text(brand.name, style: textTheme.titleMedium)),
                  if (session.profile.organizations.length > 1)
                    TextButton(onPressed: () => context.push(AppRoutes.selectGym), child: Text(l10n.switchGym)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SectionHeader(l10n.settings),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  _SettingRow(
                    icon: Icons.calendar_month_rounded,
                    label: l10n.calendar,
                    value: calendarName(l10n, ref.watch(calendarProvider)),
                    onTap: () => showCalendarSheet(context),
                  ),
                  const Divider(height: 1, indent: 60, color: AppColors.line),
                  _SettingRow(
                    icon: Icons.devices_rounded,
                    label: l10n.devices,
                    onTap: () => context.go(AppRoutes.devices),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => signOut(ref),
              icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
              label: Text(l10n.signOut, style: const TextStyle(color: AppColors.danger)),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.appVersion(appInfo.version, appInfo.buildNumber),
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.icon, required this.label, required this.onTap, this.value});

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: const Color(0xFFF2EEE8), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: AppColors.ink),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: textTheme.titleSmall)),
            if (value case final value?)
              Text(value, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
