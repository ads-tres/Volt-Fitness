import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/controls.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/time/clock.dart' as clock;
import '../../../../core/time/date_text.dart';
import '../../../../core/time/local_date.dart';
import '../../desk/data/new_member_repository.dart';
import '../data/desk_memberships_repository.dart';

/// Asks for the days to freeze [membership], with what that does to its end
/// date, and freezes it. Pops `true` once frozen.
Future<bool?> showFreezeMembershipSheet(BuildContext context, DeskMembership membership) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: AppColors.surface,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card))),
  builder: (context) => FreezeMembershipSheet(membership: membership),
);

class FreezeMembershipSheet extends ConsumerStatefulWidget {
  const FreezeMembershipSheet({super.key, required this.membership});

  final DeskMembership membership;

  @override
  ConsumerState<FreezeMembershipSheet> createState() => _FreezeMembershipSheetState();
}

class _FreezeMembershipSheetState extends ConsumerState<FreezeMembershipSheet> {
  /// Offered first: a week, or the days left if fewer.
  static const _suggestedDays = 7;

  final _reason = TextEditingController();
  late LocalDate _firstDay;
  late LocalDate _lastDay;
  var _freezing = false;
  Map<String, List<String>> _fieldErrors = const {};
  String? _error;

  DeskMembership get _membership => widget.membership;

  /// Owners and managers may start on a past day and go past the plan's
  /// freeze days.
  bool get _ownerOrManager => ref.read(deskRolesProvider).mayCancel;

  int get _days => _firstDay.daysUntil(_lastDay) + 1;

  @override
  void initState() {
    super.initState();
    final today = ref.read(clock.todayProvider);
    _firstDay = _membership.startsOn.compareTo(today) > 0 ? _membership.startsOn : today;
    if (_membership.currentOrNextFreeze(today) case final freeze? when freeze.hasStarted(today)) {
      _firstDay = freeze.endsOn.addDays(1);
    }
    final left = _membership.freezeDaysLeft;
    final days = left > 0 && left < _suggestedDays ? left : _suggestedDays;
    _lastDay = _firstDay.addDays(days - 1);
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pick({required bool first}) async {
    final today = ref.read(clock.todayProvider);
    final earliest = first ? (_ownerOrManager ? _membership.startsOn : today) : _firstDay;
    final latest = _membership.endsOn.compareTo(earliest) < 0 ? earliest.addDays(60) : _membership.endsOn.addDays(60);
    final current = first ? _firstDay : _lastDay;
    final picked = await showDatePicker(
      context: context,
      initialDate: (current.compareTo(earliest) < 0 ? earliest : current).toDateTime(),
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
    final navigator = Navigator.of(context);
    final today = ref.read(clock.todayProvider);
    setState(() {
      _freezing = true;
      _fieldErrors = const {};
      _error = null;
    });
    try {
      await ref
          .read(deskMembershipsRepositoryProvider)
          .freeze(
            _membership.id,
            startsOn: _firstDay == today ? null : _firstDay,
            endsOn: _lastDay,
            reason: _reason.text,
          );
      navigator.pop(true);
    } on ValidationFailure catch (failure) {
      if (!mounted) return;
      const shownByField = {'starts_on', 'ends_on', 'reason'};
      setState(() {
        _freezing = false;
        _fieldErrors = failure.fieldErrors;
        _error = failure.fieldErrors.keys.any(shownByField.contains)
            ? null
            : failure.fieldErrors.values.firstOrNull?.firstOrNull ?? failureMessage(l10n, failure);
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
              Row(
                children: [
                  const Icon(Icons.ac_unit_rounded),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l10n.deskFreezeTitle(_membership.planName), style: textTheme.titleLarge)),
                ],
              ),
              const SizedBox(height: 6),
              Text(l10n.deskFreezeBody, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              _DayField(
                key: const Key('freeze-first-day'),
                label: l10n.freezeFirstDay,
                value: dates.date(_firstDay),
                errors: _fieldErrors['starts_on'],
                onTap: _freezing ? null : () => _pick(first: true),
              ),
              const SizedBox(height: 12),
              _DayField(
                key: const Key('freeze-last-day'),
                label: l10n.freezeLastDay,
                value: dates.date(_lastDay),
                errors: _fieldErrors['ends_on'],
                onTap: _freezing ? null : () => _pick(first: false),
              ),
              const SizedBox(height: 14),
              Text(l10n.deskFreezeSummary(days, dates.date(_membership.endsOn.addDays(days))), style: textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                tooMany
                    ? (_ownerOrManager
                          ? l10n.deskFreezeOverAllowanceOwner(_membership.freezeDaysLeft)
                          : l10n.freezeTooManyDays(_membership.freezeDaysLeft))
                    : l10n.deskFreezeDaysLeft(_membership.freezeDaysLeft),
                style: textTheme.bodyMedium?.copyWith(color: tooMany ? AppColors.danger : AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              TextField(
                key: const Key('freeze-reason'),
                controller: _reason,
                enabled: !_freezing,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) {
                  if (_fieldErrors.containsKey('reason')) setState(() => _fieldErrors = const {});
                },
                decoration: InputDecoration(
                  labelText: l10n.deskFreezeReason,
                  hintText: l10n.freezeReasonHint,
                  counterText: '',
                  errorText: _fieldErrors['reason']?.firstOrNull,
                ),
              ),
              if (_error case final error?) ...[
                const SizedBox(height: 12),
                Text(error, style: textTheme.bodyMedium?.copyWith(color: AppColors.danger)),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                label: l10n.freezeConfirm,
                isLoading: _freezing,
                onPressed: _freezing || (tooMany && !_ownerOrManager) ? null : _freeze,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A day to pick, with the API's refusal about it underneath.
class _DayField extends StatelessWidget {
  const _DayField({super.key, required this.label, required this.value, required this.onTap, this.errors});

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
