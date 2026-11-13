import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/widgets/surfaces.dart';
import '../../../../core/localization/l10n.dart';
import '../../../core/desk_session.dart';

/// For staff who work at more than one gym.
class ChooseGymPage extends ConsumerWidget {
  const ChooseGymPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(deskSessionProvider);
    final gyms = session is DeskSignedIn ? session.gyms : const <DeskGym>[];
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.deskChooseGym)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final gym in gyms) ...[
            AppCard(
              onTap: () => ref.read(deskSessionProvider.notifier).selectGym(gym),
              child: Text(gym.name, style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
