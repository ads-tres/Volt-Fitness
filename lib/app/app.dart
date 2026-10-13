import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/design/app_theme.dart';
import '../core/design/brand.dart';
import '../core/localization/locale_controller.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';

class VoltApp extends ConsumerWidget {
  const VoltApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: ref.watch(routerProvider),
      // The flavor's app name ("Volt Dev") already marks non-prod builds.
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      // Volt's colours until a gym is chosen, then the gym's.
      theme: AppTheme.of(ref.watch(brandProvider)),
      locale: ref.watch(localeControllerProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      // Not AppLocalizations.localizationsDelegates: the generated list
      // points at flutter/material's localizations, and this app (like
      // go_router) uses material_ui's.
      localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
    );
  }
}
