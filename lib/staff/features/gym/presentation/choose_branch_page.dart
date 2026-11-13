import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/widgets/feedback.dart';
import '../../../../core/design/widgets/surfaces.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/l10n.dart';
import '../../../core/desk_session.dart';
import '../data/branches_repository.dart';

/// Which branch's door this phone is at. A staff member at one branch has
/// it chosen for them.
class ChooseBranchPage extends ConsumerWidget {
  const ChooseBranchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(deskSessionProvider);
    ref.listen(deskBranchesProvider, (_, next) {
      if (next.value case [final only]) ref.read(deskSessionProvider.notifier).selectBranch(only);
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deskChooseBranch),
        actions: [
          if (session case DeskSignedIn(gyms: [_, _, ...]))
            TextButton(
              onPressed: () => ref.read(deskSessionProvider.notifier).chooseAgain(gym: true),
              child: Text(l10n.deskChooseGym),
            ),
        ],
      ),
      body: switch (ref.watch(deskBranchesProvider)) {
        AsyncData(value: []) => Padding(padding: const EdgeInsets.all(24), child: Text(l10n.deskNoBranches)),
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final branch in value) ...[
              AppCard(
                onTap: () => ref.read(deskSessionProvider.notifier).selectBranch(branch),
                child: Text(branch.name, style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
        AsyncError(:final error) => Padding(
          padding: const EdgeInsets.all(20),
          child: LoadFailedCard(
            failure: error is Failure ? error : const UnexpectedFailure(),
            onRetry: () => ref.invalidate(deskBranchesProvider),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      },
    );
  }
}
