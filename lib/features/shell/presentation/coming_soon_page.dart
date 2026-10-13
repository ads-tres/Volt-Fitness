import 'package:material_ui/material_ui.dart';

import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/controls.dart';
import '../../../core/design/widgets/surfaces.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/language_menu.dart';

/// A tab whose feature arrives in a later phase (membership, QR and
/// payments in Phase 3 and 4).
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title, required this.icon, required this.message});

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SoftBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.paddingOf(context).bottom + 24),
          children: [
            ScreenHeader(title: title, trailing: const LanguageMenu()),
            const SizedBox(height: 28),
            AppCard(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                children: [
                  IconTile(icon: icon, size: 64),
                  const SizedBox(height: 20),
                  Text(context.l10n.comingSoonTitle, textAlign: TextAlign.center, style: textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
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
