import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/controls.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_text.dart';
import '../../../core/time/local_date.dart';
import '../../home/data/dashboard_repository.dart';
import '../data/freeze_repository.dart';
import '../domain/membership.dart';

/// Asks for the days to freeze [membership], with what that does to its end
/// date, and freezes it. The API has the last word on the dates: its refusal
/// shows under the day it is about.
Future<void> showFreezeSheet(BuildContext context, Membership membership) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: AppColors.surface,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card))),
  builder: (context) => FreezeSheet(membership: membership),
);

class FreezeSheet extends ConsumerStatefulWidget {
  const FreezeSheet({super.key, required this.membership});

  final Membership membership;

  @override
  ConsumerState<FreezeSheet> createState() => _FreezeSheetState();
}

class _FreezeSheetState extends ConsumerState<FreezeSheet> {
  /// Offered first: a week, or the days left if fewer.
  static const _suggestedDays = 7;

  final _reason = TextEditingController();
  late LocalDate _firstDay;
  late LocalDate _lastDay;
  bool _freezing = false;
  Map<String, List<String>> _fieldErrors = const {};
  String? _error;

  Membership get _membership => widget.membership;

  /// The earliest day a freeze can start: today, the plan's first day if it
  /// hasn't started, or the day after a freeze that covers today.
  LocalDate get _earliest {
    final today = ref.read(todayProvider);
    var earliest = _membership.startsOn.compareTo(today) > 0 ? _membership.startsOn : today;
    if (_membership.currentOrNextFreeze(today) case final freeze? when freeze.hasStarted(today)) {
      earliest = freeze.endsOn.addDays(1);
    }
    return earliest;
  }

  int get _days => _firstDay.daysUntil(_lastDay) + 1;

  @override
  void initState() {
    super.initState();
    _firstDay = _earliest;
    final days = _membership.freezeDaysLeft < _suggestedDays ? _membership.freezeDaysLeft : _suggestedDays;
    _lastDay = _firstDay.addDays(days < 1 ? 0 : days - 1);
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool first}) async {
    final earliest = first ? _earliest : _firstDay;
    final latest = _membership.endsOn.compareTo(earliest) < 0 ? earliest : _membership.endsOn;
    final current = first ? _firstDay : _lastDay;
    final picked = await showDatePicker(
      context: context,
      initialDate: (current.compareTo(latest) > 0 ? latest : current).toDateTime(),
      firstDate: earliest.toDateTime(),
      lastDate: latest.toDateTime(),
    );
    if (picked == null || !mounted) return;
    final day = LocalDate.of(picked);
    setState(() {
      _fieldErrors = const {};
      _error = null;
      if (first) {
        final length = _days;
        _firstDay = day;
        _lastDay = day.addDays(length - 1);
      } else {
        _lastDay = day;
      }
    });
  }

  Future<void> _freeze() async {
    final l10n = context.l10n;
    final dates = ref.read(dateTextProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _freezing = true;
      _fieldErrors = const {};
      _error = null;
    });
    try {
      await ref
          .read(freezeRepositoryProvider)
          .freeze(_membership.id, startsOn: _firstDay, endsOn: _lastDay, reason: _reason.text);
      await ref.read(dashboardProvider.notifier).refresh();
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.freezeDone(dates.date(_firstDay), dates.date(_lastDay)))));
    } on ValidationFailure catch (failure) {
      if (!mounted) return;
      final aboutADay = failure.fieldErrors.keys.any((field) => field == 'starts_on' || field == 'ends_on');
      setState(() {
        _freezing = false;
        _fieldErrors = failure.fieldErrors;
        _error = aboutADay ? null : failureMessage(l10n, failure);
      });
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() {
        _freezing = false;
        _error = failureMessage(l10n, failure);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final dates = ref.watch(dateTextProvider);
    final days = _days;
    final tooMany = days > _membership.freezeDaysLeft;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.freezeSheetTitle, style: textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(l10n.freezeSheetBody, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              _DayField(
                label: l10n.freezeFirstDay,
                value: dates.date(_firstDay),
                errors: _fieldErrors['starts_on'],
                onTap: _freezing ? null : () => _pick(first: true),
              ),
              const SizedBox(height: 12),
              _DayField(
                label: l10n.freezeLastDay,
                value: dates.date(_lastDay),
                errors: _fieldErrors['ends_on'],
                onTap: _freezing ? null : () => _pick(first: false),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.freezeSummary(days, dates.date(_membership.endsOn.addDays(days))),
                style: textTheme.titleSmall,
              ),
              if (tooMany) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.freezeTooManyDays(_membership.freezeDaysLeft),
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: 18),
              TextField(
                controller: _reason,
                enabled: !_freezing,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.freezeReason, hintText: l10n.freezeReasonHint, counterText: ''),
              ),
              if (_error case final error?) ...[
                const SizedBox(height: 12),
                Text(error, style: textTheme.bodyMedium?.copyWith(color: AppColors.danger)),
              ],
              const SizedBox(height: 20),
              PrimaryButton(label: l10n.freezeConfirm, isLoading: _freezing, onPressed: tooMany ? null : _freeze),
            ],
          ),
        ),
      ),
    );
  }
}

/// A day to pick, with the API's refusal about it underneath.
class _DayField extends StatelessWidget {
  const _DayField({required this.label, required this.value, required this.onTap, this.errors});

  final String label;
  final String value;
  final VoidCallback? onTap;
  final List<String>? errors;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final error = errors?.firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppColors.canvasTop,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
            side: BorderSide(color: error == null ? AppColors.line : AppColors.danger),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.control),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Text(label, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(value, textAlign: TextAlign.end, style: textTheme.titleSmall)),
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(error, style: textTheme.bodySmall?.copyWith(color: AppColors.danger)),
          ),
      ],
    );
  }
}
