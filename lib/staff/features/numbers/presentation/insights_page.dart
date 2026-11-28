import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/feedback.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/money/money.dart';
import '../../../../core/money/payment_methods.dart';
import '../../desk/data/new_member_repository.dart';
import '../../scan/presentation/check_in_result.dart';
import '../data/insights_repository.dart';
import '../domain/desk_insights.dart';

/// The gym month by month (the API's ADR 0040): money for the roles that
/// see it; renewals, busy hours and members for owners and managers. The
/// period is the last 3, 6 or 12 months, at the desk's branch or all.
class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  var _months = 12;
  var _allBranches = false;

  InsightsQuery get _query => (months: _months, allBranches: _allBranches);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final roles = ref.watch(deskRolesProvider);
    final tabs = <(String, Widget)>[
      if (roles.maySeeRevenueInsights) (l10n.insightsTabMoney, _Money(query: _query)),
      if (roles.maySeeInsights) ...[
        (l10n.insightsTabRenewals, _Renewals(query: _query)),
        (l10n.insightsTabBusyHours, _Busy(query: _query)),
        (l10n.insightsTabMembers, _Members(query: _query)),
      ],
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.insightsTitle),
          bottom: tabs.length < 2
              ? null
              : TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [for (final (label, _) in tabs) Tab(text: label)]),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final months in const [3, 6, 12])
                    ChoiceChip(
                      key: Key('months-$months'),
                      label: Text(l10n.insightsMonths(months)),
                      selected: _months == months,
                      onSelected: (_) => setState(() => _months = months),
                    ),
                ],
              ),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(l10n.numbersAllBranches),
              value: _allBranches,
              onChanged: (on) => setState(() => _allBranches = on),
            ),
            Expanded(child: TabBarView(children: [for (final (_, view) in tabs) view])),
          ],
        ),
      ),
    );
  }
}

/// A month as the bars name it: "Oct".
String _monthLabel(String languageCode, DateTime month) => DateFormat.MMM(languageCode).format(month);

/// One insight's list: its figures when loaded, an error card otherwise.
class _InsightList<T> extends ConsumerWidget {
  const _InsightList({required this.value, required this.onRetry, required this.builder});

  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final List<Widget> Function(T value) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
    children: switch (value) {
      AsyncData(:final value) => [
        ...builder(value),
        const SizedBox(height: 16),
        Text(
          context.l10n.insightsCsvInPanel,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
      AsyncError(:final error) => [
        LoadFailedCard(failure: error is Failure ? error : const UnexpectedFailure(), onRetry: onRetry),
      ],
      _ => [
        const Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.ink)),
        ),
      ],
    },
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
}

/// A label and its figure, on one line, the label wrapping when long.
class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: textTheme.bodyMedium)),
          const SizedBox(width: 12),
          Text(value, style: textTheme.titleSmall),
        ],
      ),
    );
  }
}

/// A part of one bar, from the bottom up.
typedef _Part = ({double value, Color color});

/// A bar per month, each made of [parts] stacked from the bottom, with the
/// month under it and an optional [note] (a rate) under that. Tapping a bar
/// shows [tooltip].
class _MonthBars extends StatelessWidget {
  const _MonthBars({required this.months, required this.parts, required this.tooltip, this.note});

  final List<DateTime> months;
  final List<List<_Part>> parts;
  final String Function(int index) tooltip;
  final String? Function(int index)? note;

  static const _height = 120.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final languageCode = Localizations.localeOf(context).languageCode;
    final most = parts.fold<double>(0, (most, bar) {
      final total = bar.fold<double>(0, (sum, part) => sum + part.value);
      return total > most ? total : most;
    });
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final (index, bar) in parts.indexed)
          Expanded(
            child: Tooltip(
              message: tooltip(index),
              triggerMode: TooltipTriggerMode.tap,
              child: Column(
                children: [
                  SizedBox(
                    height: _height,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (final part in bar.reversed)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: most == 0 ? 0 : _height * part.value / most,
                            color: part.color,
                          ),
                        if (most == 0) Container(height: 2, color: AppColors.line),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(_monthLabel(languageCode, months[index]), style: textTheme.labelSmall),
                  ),
                  if (note?.call(index) case final text?)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(text, style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A coloured square and what it stands for.
class _Key extends StatelessWidget {
  const _Key(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 12, height: 12, color: color),
      const SizedBox(width: 6),
      Flexible(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
    ],
  );
}

const _green = CheckInResultView.letInColor;
const _red = CheckInResultView.turnedAwayColor;
const _blue = Color(0xFF1F5AA6);

class _Money extends ConsumerWidget {
  const _Money({required this.query});

  final InsightsQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final languageCode = ref.watch(languageCodeProvider);
    return _InsightList(
      value: ref.watch(revenueInsightProvider(query)),
      onRetry: () => ref.invalidate(revenueInsightProvider(query)),
      builder: (months) {
        if (months.isEmpty) return [Text(l10n.insightsNone)];
        final currency = months.first.net.currency;
        Money sum(Iterable<Money> amounts) => Money(amounts.fold(0, (total, amount) => total + amount.amountMinor), currency);
        Map<String, Money> totals(Map<String, Money> Function(RevenueMonth month) of) {
          final keys = {for (final month in months) ...of(month).keys};
          return {for (final key in keys) key: sum([for (final month in months) ?of(month)[key]])};
        }

        return [
          _Card(
            title: l10n.insightsMoneyTotal(months.length),
            children: [
              Text(
                sum([for (final month in months) month.net]).format(languageCode),
                key: const Key('revenue-total'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _MonthBars(
                months: [for (final month in months) month.month],
                parts: [
                  for (final month in months) [(value: month.net.amountMinor.toDouble(), color: _green)],
                ],
                tooltip: (index) => months[index].net.format(languageCode),
              ),
            ],
          ),
          _Card(
            title: l10n.insightsByPlan,
            children: [
              for (final MapEntry(:key, :value) in totals((month) => month.byPlan).entries)
                _Row(key, value.format(languageCode)),
            ],
          ),
          _Card(
            title: l10n.insightsByMethod,
            children: [
              for (final MapEntry(:key, :value) in totals((month) => month.byMethod).entries)
                _Row(paymentMethodName(l10n, key), value.format(languageCode)),
            ],
          ),
        ];
      },
    );
  }
}

String _percent(double rate) => '${(rate * 100).round()}%';

class _Renewals extends ConsumerWidget {
  const _Renewals({required this.query});

  final InsightsQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _InsightList(
      value: ref.watch(renewalsInsightProvider(query)),
      onRetry: () => ref.invalidate(renewalsInsightProvider(query)),
      builder: (months) {
        if (months.isEmpty) return [Text(l10n.insightsNone)];
        final renewed = months.fold(0, (sum, month) => sum + month.renewed);
        final lapsed = months.fold(0, (sum, month) => sum + month.lapsed);
        final plans = {for (final month in months) ...month.byPlan.keys};
        return [
          _Card(
            title: l10n.insightsRenewalRate,
            children: [
              Text(
                renewed + lapsed == 0 ? '—' : _percent(renewed / (renewed + lapsed)),
                key: const Key('renewal-rate'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(l10n.insightsRenewedMeans, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              _MonthBars(
                months: [for (final month in months) month.month],
                parts: [
                  for (final month in months)
                    [
                      (value: month.renewed.toDouble(), color: _green),
                      (value: month.lapsed.toDouble(), color: _red),
                      (value: month.waiting.toDouble(), color: AppColors.line),
                    ],
                ],
                tooltip: (index) => [
                  '${l10n.insightsRenewed}: ${months[index].renewed}',
                  '${l10n.insightsLapsed}: ${months[index].lapsed}',
                  '${l10n.insightsWaiting}: ${months[index].waiting}',
                ].join('\n'),
                note: (index) => switch (months[index].rate) {
                  final rate? => _percent(rate),
                  null => null,
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  _Key(_green, l10n.insightsRenewed),
                  _Key(_red, l10n.insightsLapsed),
                  _Key(AppColors.line, l10n.insightsWaiting),
                ],
              ),
            ],
          ),
          _Card(
            title: l10n.insightsByPlan,
            children: [
              for (final plan in plans)
                () {
                  final kept = months.fold(0, (sum, month) => sum + (month.byPlan[plan]?.renewed ?? 0));
                  final lost = months.fold(0, (sum, month) => sum + (month.byPlan[plan]?.lapsed ?? 0));
                  return _Row(plan, kept + lost == 0 ? '—' : '${_percent(kept / (kept + lost))} · $kept / ${kept + lost}');
                }(),
            ],
          ),
        ];
      },
    );
  }
}

class _Busy extends ConsumerWidget {
  const _Busy({required this.query});

  final InsightsQuery query;

  /// Monday to Sunday as the language names them: "Mon".
  static List<String> _weekdays(String languageCode) => [
    for (var day = 0; day < 7; day++) DateFormat.E(languageCode).format(DateTime(2024, 1, 1 + day)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final languageCode = ref.watch(languageCodeProvider);
    final weekdays = _weekdays(languageCode);
    return _InsightList(
      value: ref.watch(busyHoursInsightProvider(query)),
      onRetry: () => ref.invalidate(busyHoursInsightProvider(query)),
      builder: (busy) {
        final busiest = busy.busiest;
        final most = busiest?.count ?? 0;
        return [
          _Card(
            title: l10n.insightsCheckIns(busy.total),
            children: [
              if (busiest != null)
                Text(
                  l10n.insightsBusiest(weekdays[busiest.weekday - 1], '${busiest.hour.toString().padLeft(2, '0')}:00'),
                  key: const Key('busiest'),
                  style: textTheme.titleMedium,
                ),
              const SizedBox(height: 12),
              for (final (day, row) in busy.grid.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(weekdays[day], style: textTheme.labelSmall),
                        ),
                      ),
                      for (final (hour, count) in row.indexed)
                        Expanded(
                          child: Tooltip(
                            message: '${weekdays[day]} ${hour.toString().padLeft(2, '0')}:00 · $count',
                            triggerMode: TooltipTriggerMode.tap,
                            child: Container(
                              height: 14,
                              margin: const EdgeInsets.symmetric(horizontal: 0.5),
                              color: count == 0 || most == 0
                                  ? AppColors.line.withValues(alpha: 0.4)
                                  : Color.lerp(const Color(0xFFDCEFE6), _green, count / most),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 40, top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [for (final label in ['00', '06', '12', '18', '23']) Text(label, style: textTheme.labelSmall)],
                ),
              ),
            ],
          ),
        ];
      },
    );
  }
}

class _Members extends ConsumerWidget {
  const _Members({required this.query});

  final InsightsQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _InsightList(
      value: ref.watch(membersInsightProvider(query)),
      onRetry: () => ref.invalidate(membersInsightProvider(query)),
      builder: (months) {
        if (months.isEmpty) return [Text(l10n.insightsNone)];
        final last = months.last;
        final packsEnded = months.fold(0, (sum, month) => sum + month.packsEnded);
        final bought = months.fold(0, (sum, month) => sum + month.visitsBought);
        final used = months.fold(0, (sum, month) => sum + month.visitsUsed);
        final left = months.fold(0, (sum, month) => sum + month.packsWithVisitsLeft);
        return [
          _Card(
            title: l10n.insightsActive,
            children: [
              Text(
                '${last.active}',
                key: const Key('active-members'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _MonthBars(
                months: [for (final month in months) month.month],
                parts: [
                  for (final month in months) [(value: month.active.toDouble(), color: _blue)],
                ],
                tooltip: (index) => '${l10n.insightsActive}: ${months[index].active}\n'
                    '${l10n.insightsNew}: ${months[index].newMembers}',
                note: (index) => '+${months[index].newMembers}',
              ),
              const SizedBox(height: 8),
              Text(l10n.insightsNewUnder, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          _Card(
            title: l10n.insightsPacks,
            children: [
              _Row(l10n.insightsPacksEnded, '$packsEnded'),
              _Row(l10n.insightsVisitsUsed, bought == 0 ? '—' : '$used / $bought · ${_percent(used / bought)}'),
              _Row(l10n.insightsPacksLeft, '$left'),
            ],
          ),
        ];
      },
    );
  }
}
