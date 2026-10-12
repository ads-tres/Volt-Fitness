import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/language_menu.dart';

/// Placeholder until the dashboard is designed (Phase 3).
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.home), actions: const [LanguageMenu()]),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              Text(l10n.placeholderNotice, textAlign: TextAlign.center),
              OutlinedButton(
                onPressed: () => ref.read(sessionControllerProvider.notifier).signOut(),
                child: Text(l10n.signOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
