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
import '../../auth/presentation/sign_out.dart';

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
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.paddingOf(context).bottom + 24),
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
                  GymAvatar(brand: brand),
                  const SizedBox(width: 14),
                  Expanded(child: Text(brand.name, style: textTheme.titleMedium)),
                  if (session.profile.organizations.length > 1)
                    TextButton(onPressed: () => context.push(AppRoutes.selectGym), child: Text(l10n.switchGym)),
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
