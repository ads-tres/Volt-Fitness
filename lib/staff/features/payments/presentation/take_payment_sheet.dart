import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/controls.dart';
import '../../../../core/design/widgets/feedback.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/money/money.dart';
import '../../../../core/time/clock.dart' as clock;
import '../../../../core/time/date_text.dart';
import '../../../../core/time/local_date.dart';
import '../../../../core/utils/ethiopian_phone.dart';
import '../../../core/desk_session.dart';
import '../data/desk_payments_repository.dart';

/// Who is paying: enough to find their memberships and to name them.
typedef PayingMember = ({int id, String name, String phone});

/// Takes money from [member] at the desk: cash or a transfer recorded on
/// the membership with money due, or a pay-online link texted to them.
/// [onPaid] runs once the API has taken it, so the caller can refresh.
Future<void> showTakePaymentSheet(BuildContext context, PayingMember member, {required VoidCallback onPaid}) {
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card))),
    builder: (context) => TakePaymentSheet(member: member, onPaid: onPaid),
  );
}

class TakePaymentSheet extends ConsumerStatefulWidget {
  const TakePaymentSheet({super.key, required this.member, required this.onPaid});

  final PayingMember member;
  final VoidCallback onPaid;

  @override
  ConsumerState<TakePaymentSheet> createState() => _TakePaymentSheetState();
}

class _TakePaymentSheetState extends ConsumerState<TakePaymentSheet> {
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  List<OwingMembership>? _owing;
  Failure? _loadFailure;
  OwingMembership? _membership;
  var _method = DeskPaymentMethod.cash;
  LocalDate? _paidOn;
  var _busy = false;
  Map<String, List<String>> _fieldErrors = const {};
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _owing = null;
      _loadFailure = null;
    });
    try {
      final owing = await ref.read(deskPaymentsRepositoryProvider).owing(widget.member.id);
      if (!mounted) return;
      setState(() {
        _owing = owing;
        if (owing.isNotEmpty) _choose(owing.first);
      });
    } on Failure catch (failure) {
      if (mounted) setState(() => _loadFailure = failure);
    }
  }

  void _choose(OwingMembership membership) {
    _membership = membership;
    _amount.text = DeskPaymentsRepository.amountText(membership.balanceDue);
    _fieldErrors = const {};
    _error = null;
  }

  /// What was typed, as money, or null when it isn't an amount.
  Money? get _typedAmount {
    final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(_amount.text.trim().replaceAll(',', ''));
    final membership = _membership;
    if (match == null || membership == null) return null;
    final minor = int.parse(match.group(1)!) * 100 + int.parse((match.group(2) ?? '0').padRight(2, '0'));
    return minor > 0 ? Money(minor, membership.balanceDue.currency) : null;
  }

  bool get _mayBackdate => switch (ref.read(deskSessionProvider)) {
    DeskSignedIn(gym: final gym?) => gym.role != 'receptionist',
    _ => false,
  };

  String _methodName(DeskPaymentMethod method) {
    final l10n = context.l10n;
    return switch (method) {
      DeskPaymentMethod.cash => l10n.payCash,
      DeskPaymentMethod.telebirr => l10n.payTelebirr,
      DeskPaymentMethod.cbeBirr => l10n.payCbeBirr,
      DeskPaymentMethod.bankTransfer => l10n.payBankTransfer,
    };
  }

  /// Runs [action] against the API; on success closes the sheet and says
  /// [done], otherwise shows why under the field it is about.
  Future<void> _send(Future<String> Function(DeskPaymentsRepository payments) action) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _fieldErrors = const {};
      _error = null;
    });
    try {
      final done = await action(ref.read(deskPaymentsRepositoryProvider));
      widget.onPaid();
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(done)));
    } on ValidationFailure catch (failure) {
      if (!mounted) return;
      const shownByField = {'amount', 'reference', 'paid_on'};
      final general = failure.fieldErrors.entries.where((entry) => !shownByField.contains(entry.key)).firstOrNull;
      setState(() {
        _busy = false;
        _fieldErrors = failure.fieldErrors;
        _error = general?.value.firstOrNull ??
            (failure.fieldErrors.keys.any(shownByField.contains) ? null : failureMessage(l10n, failure));
      });
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = failureMessage(l10n, failure);
      });
    }
  }

  void _record() {
    final l10n = context.l10n;
    final languageCode = ref.read(languageCodeProvider);
    final amount = _typedAmount;
    final membership = _membership!;
    if (amount == null) {
      setState(() => _fieldErrors = {'amount': [l10n.payAmountInvalid]});
      return;
    }
    unawaited(
      _send((payments) async {
        final receipt = await payments.record(
          membership.id,
          amount: amount,
          method: _method,
          reference: _reference.text,
          paidOn: _paidOn,
        );
        return l10n.payRecorded(receipt.receiptNumber, receipt.amount.format(languageCode));
      }),
    );
  }

  void _textLink() {
    final l10n = context.l10n;
    final amount = _typedAmount;
    final membership = _membership!;
    if (amount == null) {
      setState(() => _fieldErrors = {'amount': [l10n.payAmountInvalid]});
      return;
    }
    final texted = l10n.payLinkTexted(EthiopianPhone.format(widget.member.phone));
    unawaited(
      _send((payments) async {
        if (membership.openLinkId case final linkId?) {
          await payments.textLink(linkId);
        } else {
          await payments.textNewLink(membership.id, amount: amount);
        }
        return texted;
      }),
    );
  }

  Future<void> _pickDay() async {
    final today = ref.read(clock.todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: (_paidOn ?? today).toDateTime(),
      firstDate: today.addDays(-90).toDateTime(),
      lastDate: today.toDateTime(),
    );
    if (picked == null || !mounted) return;
    final day = LocalDate.of(picked);
    setState(() => _paidOn = day == today ? null : day);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final languageCode = ref.watch(languageCodeProvider);
    final dates = ref.watch(dateTextProvider);
    final owing = _owing;
    final membership = _membership;

    final List<Widget> body;
    if (_loadFailure case final failure?) {
      body = [LoadFailedCard(failure: failure, onRetry: _load)];
    } else if (owing == null) {
      body = [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.ink)),
        ),
      ];
    } else if (owing.isEmpty || membership == null) {
      body = [Text(l10n.payNothingDue(widget.member.name), style: textTheme.bodyMedium)];
    } else {
      final amount = _typedAmount;
      final left = amount == null ? null : membership.balanceDue.amountMinor - amount.amountMinor;
      body = [
        if (owing.length > 1) ...[
          Text(l10n.payWhichMembership, style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final each in owing)
                ChoiceChip(
                  label: Text(
                    '${each.planName} · ${dates.date(each.startsOn)} – ${dates.date(each.endsOn)} · '
                    '${each.balanceDue.format(languageCode)}',
                  ),
                  selected: each == membership,
                  onSelected: _busy ? null : (_) => setState(() => _choose(each)),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          key: const Key('pay-amount'),
          controller: _amount,
          enabled: !_busy,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
          onChanged: (_) => setState(() => _fieldErrors = const {}),
          decoration: InputDecoration(
            labelText: l10n.payAmountLabel,
            suffixText: membership.balanceDue.currency,
            helperText: l10n.payAmountHelp(membership.balanceDue.format(languageCode)),
            errorText: _fieldErrors['amount']?.firstOrNull,
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.payMethod, style: textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final method in DeskPaymentMethod.values)
              ChoiceChip(
                label: Text(_methodName(method)),
                selected: _method == method,
                onSelected: _busy
                    ? null
                    : (_) => setState(() {
                        _method = method;
                        _fieldErrors = const {};
                      }),
              ),
          ],
        ),
        if (_method.hasReference) ...[
          const SizedBox(height: 16),
          TextField(
            key: const Key('pay-reference'),
            controller: _reference,
            enabled: !_busy,
            maxLength: 100,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: l10n.payReference,
              helperText: l10n.payReferenceHelp,
              counterText: '',
              prefixIcon: const Icon(Icons.tag_rounded),
              errorText: _fieldErrors['reference']?.firstOrNull,
            ),
          ),
        ],
        if (_mayBackdate) ...[
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_rounded),
            title: Text(l10n.payPaidOn),
            subtitle: _fieldErrors['paid_on'] == null
                ? null
                : Text(_fieldErrors['paid_on']!.first, style: textTheme.bodySmall?.copyWith(color: AppColors.danger)),
            trailing: Text(_paidOn == null ? l10n.payToday : dates.date(_paidOn!), style: textTheme.titleSmall),
            onTap: _busy ? null : _pickDay,
          ),
        ],
        const SizedBox(height: 12),
        if (amount != null && left != null && left >= 0)
          Text(
            left == 0
                ? l10n.paySummaryPaidOff(amount.format(languageCode), _methodName(_method), widget.member.name)
                : l10n.paySummary(
                    amount.format(languageCode),
                    _methodName(_method),
                    widget.member.name,
                    Money(left, amount.currency).format(languageCode),
                  ),
            style: textTheme.titleSmall,
          ),
        if (_error case final error?) ...[
          const SizedBox(height: 12),
          Text(error, style: textTheme.bodyMedium?.copyWith(color: AppColors.danger)),
        ],
        const SizedBox(height: 20),
        PrimaryButton(label: l10n.payRecord, isLoading: _busy, onPressed: _busy ? null : _record),
        const SizedBox(height: 8),
        if (membership.openLinkId != null)
          Text(l10n.payLinkOpen, style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
        TextButton.icon(
          onPressed: _busy ? null : _textLink,
          icon: const Icon(Icons.sms_rounded),
          label: Text(membership.openLinkId == null ? l10n.payTextLink : l10n.payTextAgain),
        ),
      ];
    }

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
                  const Icon(Icons.payments_rounded),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l10n.payTitle(widget.member.name), style: textTheme.titleLarge)),
                ],
              ),
              const SizedBox(height: 6),
              Text(l10n.payBody, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              ...body,
            ],
          ),
        ),
      ),
    );
  }
}
