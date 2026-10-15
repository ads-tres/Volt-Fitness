import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/controls.dart';
import '../../../core/design/widgets/feedback.dart';
import '../../../core/design/widgets/surfaces.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_text.dart';
import '../../../core/time/local_date.dart';
import '../data/visits_controller.dart';
import '../domain/visit.dart';
import 'visit_card.dart';

/// Every visit at the selected gym, newest first, grouped by day. Older
/// pages load as the list nears its end.
class VisitsPage extends ConsumerWidget {
  const VisitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(visitsProvider);
    final dates = ref.watch(dateTextProvider);
    final today = ref.watch(todayProvider);
    final controller = ref.read(visitsProvider.notifier);

    // One row per day header or visit.
    final rows = <Object>[];
    LocalDate? previousDay;
    for (final visit in state.visits) {
      final day = LocalDate.of(visit.checkedInAt.toLocal());
      if (day != previousDay) rows.add(day);
      rows.add(visit);
      previousDay = day;
    }

    return SoftBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: ScreenHeader(
                leading: HeaderButton(
                  tooltip: l10n.back,
                  onPressed: () => context.pop(),
                  child: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                ),
                title: l10n.visitsTitle,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  itemCount: rows.length + 1,
                  itemBuilder: (context, index) {
                    if (index == rows.length) return _Footer(state: state, onRetry: controller.loadMore);
                    if (index >= rows.length - 4 && !state.reachedEnd && !state.isLoading && state.failure == null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) => controller.loadMore());
                    }
                    return switch (rows[index]) {
                      final LocalDate day => Padding(
                        padding: EdgeInsets.only(top: index == 0 ? 4 : 18, bottom: 10),
                        child: Text(visitDayLabel(l10n, dates, day, today), style: textTheme.titleSmall),
                      ),
                      final Visit visit => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: VisitCard(visit: visit, showDay: false),
                      ),
                      _ => const SizedBox.shrink(),
                    };
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state, required this.onRetry});

  final VisitsState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.failure case final failure?) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: LoadFailedCard(failure: failure, onRetry: onRetry),
      );
    }
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }
    if (state.visits.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(20),
        child: Text(
          context.l10n.noVisitsYet,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
