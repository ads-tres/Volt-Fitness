import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/localization/l10n.dart';
import '../../../core/desk_session.dart';
import 'desk_menu.dart';

/// Where the front desk scans members' QR codes.
class ScanPage extends ConsumerWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.deskTitle),
            Text(deskPlace(ref.watch(deskSessionProvider)), style: textTheme.bodySmall),
          ],
        ),
        actions: const [DeskMenu()],
      ),
      body: const SizedBox.expand(),
    );
  }
}
