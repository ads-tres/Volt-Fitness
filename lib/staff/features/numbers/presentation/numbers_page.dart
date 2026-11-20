import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/feedback.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/money/money.dart';
import '../../../../l10n/app_localizations.dart';
import '../../scan/presentation/check_in_result.dart';
import '../data/numbers_repository.dart';
import '../domain/desk_numbers.dart';
import 'members_to_call.dart';

/// The gym's figures at the desk: check-ins, money and what is owed (for
/// those who see money), members, busy hours and the members to call, for
/// today or the last 7 or 30 days, at this branch or every branch.
class NumbersPage extends ConsumerStatefulWidget {
  const NumbersPage({super.key});

  @override
  ConsumerState<NumbersPage> createState() => _NumbersPageState();
}

class _NumbersPageState extends ConsumerState<NumbersPage> {
  NumbersPeriod _period = NumbersPeriod.today;
  bool _allBranches = false;

  NumbersQuery get _query => (period: _period, allBranches: _allBranches);

  String _periodName(AppLocalizations l10n, NumbersPeriod period) => switch (period) {
    NumbersPeriod.today => l10n.numbersToday,
    NumbersPeriod.week => l10n.numbersWeek,
    NumbersPeriod.month => l10n.numbersMonth,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final numbers = ref.watch(numbersProvider(_query));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.numbersTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(numbersProvider(_query).future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final period in NumbersPeriod.values)
                  ChoiceChip(
                    label: Text(_periodName(l10n, period)),
                    selected: _period == period,
                    onSelected: (_) => setState(() => _period = period),
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.numbersAllBranches),
              value: _allBranches,
              onChanged: (on) => setState(() => _allBranches = on),
            ),
            switch (numbers) {
              AsyncData(:final value) => _Figures(numbers: value),
              AsyncError(:final error) => LoadFailedCard(
                failure: error is Failure ? error : const UnexpectedFailure(),
                onRetry: () => ref.invalidate(numbersProvider(_query)),
              ),
              _ => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.ink)),
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _Figures extends ConsumerWidget {
  const _Figures({required this.numbers});

  final DeskNumbers numbers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final languageCode = ref.watch(languageCodeProvider);
    String format(Money money) => money.format(languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Card(
          title: l10n.numbersCheckIns,
          figures: [
            (l10n.deskLetIn, '${numbers.letIn}'),
            (l10n.deskTurnedAway, '${numbers.turnedAway}'),
          ],
          details: [for (final (code, count) in numbers.turnedAwayByReason.take(3)) (deskReason(l10n, code), '$count')],
        ),
        if (numbers.money case final money?)
          _Card(
            title: l10n.numbersMoney,
            figures: [(l10n.numbersTaken, format(money.net))],
            details: [
              (l10n.numbersReceived, format(money.received)),
              (l10n.numbersRefunded, format(money.refunded)),
              for (final MapEntry(:key, :value) in money.byMethod.entries) ('· $key', format(value)),
              (l10n.numbersOpenLinks(money.openLinks), format(money.openLinksAmount)),
              (l10n.numbersRefundsNeeded(money.refundsNeeded), format(money.refundsNeededAmount)),
            ],
          ),
        if (numbers.owed case final owed?)
          _Card(
            title: l10n.numbersOwed,
            figures: [(l10n.numbersOwedMembers(owed.members), format(owed.total))],
          ),
        _Card(
          title: l10n.numbersMembers,
          figures: [
            (l10n.numbersActive, '${numbers.activeMembers}'),
            (l10n.numbersNew, '${numbers.newMembers}'),
          ],
          details: [
            (l10n.numbersSoldAtDesk, '${numbers.soldAtTheDesk}'),
            (l10n.numbersSoldInApp, '${numbers.soldInTheApp}'),
          ],
        ),
        _BusyHours(byHour: numbers.checkInsByHour),
        MembersToCall(members: numbers.toCall),
      ],
    );
  }
}

/// A titled card: big figures side by side, then label and value lines.
class _Card extends StatelessWidget {
  const _Card({required this.title, required this.figures, this.details = const []});

  final String title;
  final List<(String, String)> figures;
  final List<(String, String)> details;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        side: const BorderSide(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleSmall?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 28,
              runSpacing: 8,
              children: [
                for (final (label, value) in figures)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Text(label, style: textTheme.bodySmall),
                    ],
                  ),
              ],
            ),
            if (details.isNotEmpty) const Divider(height: 24, color: AppColors.line),
            for (final (label, value) in details)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(child: Text(label, style: textTheme.bodyMedium)),
                    Text(value, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Who came in at each hour of the gym's day, as a row of bars.
class _BusyHours extends StatelessWidget {
  const _BusyHours({required this.byHour});

  final List<int> byHour;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final most = byHour.fold(0, (a, b) => a > b ? a : b);
    return Card(
      margin: const EdgeInsets.only(top: 12),
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        side: const BorderSide(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.numbersBusyHours, style: textTheme.titleSmall?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            SizedBox(
              height: 64,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final (hour, count) in byHour.indexed)
                    Expanded(
                      child: Tooltip(
                        message: '${hour.toString().padLeft(2, '0')}:00 · $count',
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          height: most == 0 ? 2 : 2 + 62 * count / most,
                          decoration: BoxDecoration(
                            color: count == 0 ? AppColors.line : CheckInResultView.letInColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final label in ['00', '06', '12', '18', '23']) Text(label, style: textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
