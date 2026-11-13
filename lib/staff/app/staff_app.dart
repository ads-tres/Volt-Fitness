import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/brand.dart';
import '../../core/localization/locale_controller.dart';
import '../../l10n/app_localizations.dart';
import 'staff_router.dart';

/// The front desk app: staff sign in, choose their branch and let members
/// in by their QR code or at the desk. Drawn in Volt's colours.
class StaffApp extends ConsumerWidget {
  const StaffApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: ref.watch(staffRouterProvider),
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).deskTitle,
      theme: AppTheme.of(Brand.volt),
      locale: ref.watch(localeControllerProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      // As in the member app: material_ui's localizations, not the
      // generated list's.
      localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
    );
  }
}
