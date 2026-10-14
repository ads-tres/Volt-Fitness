import 'package:material_ui/material_ui.dart';

import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/controls.dart';
import '../../../core/design/widgets/surfaces.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/language_menu.dart';

/// A tab whose feature arrives in a later phase (membership, QR and
/// payments in Phases 3 and 4).
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title, required this.photo, required this.message});

  final String title;

  /// An asset path under `assets/photos/`.
  final String photo;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SoftBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            ScreenHeader(title: title, trailing: const LanguageMenu()),
            const SizedBox(height: 28),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Image.asset(photo, height: 220, width: double.infinity, fit: BoxFit.cover),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                    child: Column(
                      children: [
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
          ],
        ),
      ),
    );
  }
}
