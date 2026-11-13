import 'package:material_ui/material_ui.dart';

import '../../../../core/localization/l10n.dart';

/// Where the front desk scans members' QR codes.
class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.deskTitle)),
      body: const SizedBox.expand(),
    );
  }
}
