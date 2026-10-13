import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/auth/session.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/controls.dart';
import '../../../core/design/widgets/surfaces.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/language_menu.dart';
import '../../../core/utils/ethiopian_phone.dart';
import '../../auth/presentation/sign_out.dart';

/// The code was right, but no gym has this number. Members are registered
/// by their gym, so the way forward is the front desk or another number.
class NoGymPage extends ConsumerWidget {
  const NoGymPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final phone = switch (ref.watch(sessionControllerProvider)) {
      SignedIn(:final profile) => EthiopianPhone.format(profile.user.phone),
      SignedOut() => '',
    };

    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Align(alignment: Alignment.centerRight, child: LanguageMenu()),
                const Spacer(),
                const Center(child: IconTile(icon: Icons.person_search_rounded, size: 72)),
                const SizedBox(height: 28),
                Text(l10n.noGymTitle, textAlign: TextAlign.center, style: textTheme.headlineMedium),
                const SizedBox(height: 10),
                Text(
                  l10n.noGymMessage(phone),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                ),
                const Spacer(),
                PrimaryButton(label: l10n.useAnotherNumber, onPressed: () => signOut(ref)),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
