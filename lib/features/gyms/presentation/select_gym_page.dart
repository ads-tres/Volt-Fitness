import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/auth/session.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/design/brand.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/surfaces.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/language_menu.dart';

/// Shown after sign-in when the member's number belongs to several gyms,
/// and from the profile to switch. Each gym is drawn in its own colours.
class SelectGymPage extends ConsumerWidget {
  const SelectGymPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final session = ref.watch(sessionControllerProvider);
    if (session is! SignedIn) return const SizedBox.shrink();

    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  if (context.canPop())
                    CircleButton(
                      tooltip: l10n.back,
                      onPressed: () => context.pop(),
                      child: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                    ),
                  const Spacer(),
                  const LanguageMenu(),
                ],
              ),
              const SizedBox(height: 32),
              const Align(alignment: Alignment.centerLeft, child: IconTile(icon: Icons.fitness_center_rounded, size: 56)),
              const SizedBox(height: 24),
              Text(l10n.selectGymTitle, style: textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(l10n.selectGymSubtitle, style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 28),
              for (final organization in session.profile.organizations)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: () async {
                      await ref.read(sessionControllerProvider.notifier).selectOrganization(organization.id);
                      if (context.mounted) context.go(AppRoutes.home);
                    },
                    child: Row(
                      children: [
                        GymAvatar(brand: Brand.of(organization), size: 52),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(organization.name, style: textTheme.titleMedium),
                              if (organization.branding.contactPhone case final phone?)
                                Text(phone, style: textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Icon(
                          organization.id == session.organizationId
                              ? Icons.check_circle_rounded
                              : Icons.chevron_right_rounded,
                          color: organization.id == session.organizationId
                              ? Brand.of(organization).primary
                              : AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
