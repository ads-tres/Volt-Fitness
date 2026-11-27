import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/controls.dart';
import '../../../../core/design/widgets/feedback.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/time/clock.dart' as clock;
import '../../../../core/time/date_text.dart';
import '../../../../core/time/local_date.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/desk_session.dart';
import '../../payments/presentation/take_payment_sheet.dart';
import '../data/desk_plans_repository.dart';

/// Sells [member] one of the gym's plans, then opens the payment sheet for
/// what is due on it. [currentPlanName] is chosen first, for a renewal.
/// [onSold] runs once the plan is sold, so the caller can refresh.
Future<void> showSellPlanSheet(
  BuildContext context,
  PayingMember member, {
  String? currentPlanName,
  required VoidCallback onSold,
}) async {
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  final sold = await showModalBottomSheet<SoldMembership>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card))),
    builder: (context) => SellPlanSheet(member: member, currentPlanName: currentPlanName),
  );
  if (sold == null || !context.mounted) return;
  onSold();
  final container = ProviderScope.containerOf(context, listen: false);
  final languageCode = container.read(languageCodeProvider);
  final dates = container.read(dateTextProvider);
  final done = context.l10n.sellDone(
    sold.planName,
    member.name,
    dates.date(sold.startsOn),
    dates.date(sold.endsOn),
    sold.price.format(languageCode),
  );
  if (sold.balanceDue.amountMinor > 0) {
    // The payment sheet says it was sold, and takes what is due.
    await showTakePaymentSheet(context, member, onPaid: onSold, membershipId: sold.id, note: done);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
  }
}

/// How long [plan] runs, with its visits: "1 month", "10 visits · 2 months".
String deskPlanLength(AppLocalizations l10n, DeskPlan plan) {
  final count = plan.durationCount;
  final length = switch (plan.durationUnit) {
    'day' => l10n.sellLengthDays(count),
    'week' => l10n.sellLengthWeeks(count),
    'year' => l10n.sellLengthYears(count),
    _ => l10n.sellLengthMonths(count),
  };
  return switch (plan.visitLimit) {
    final visits? => '${l10n.sellVisits(visits)} · $length',
    null => length,
  };
}

class SellPlanSheet extends ConsumerStatefulWidget {
  const SellPlanSheet({super.key, required this.member, this.currentPlanName});

  final PayingMember member;
  final String? currentPlanName;

  @override
  ConsumerState<SellPlanSheet> createState() => _SellPlanSheetState();
}

class _SellPlanSheetState extends ConsumerState<SellPlanSheet> {
  final _promoCode = TextEditingController();
  final _discount = TextEditingController();
  final _discountReason = TextEditingController();
  int? _planId;
  LocalDate? _startsOn;
  var _selling = false;
  Map<String, List<String>> _fieldErrors = const {};
  String? _error;

  @override
  void dispose() {
    _promoCode.dispose();
    _discount.dispose();
    _discountReason.dispose();
    super.dispose();
  }

  /// Owners and managers may start a plan on a past day and type a discount.
  bool get _ownerOrManager => switch (ref.read(deskSessionProvider)) {
    DeskSignedIn(gym: final gym?) => gym.role == 'owner' || gym.role == 'manager',
    _ => false,
  };

  void _clearErrors() {
    _fieldErrors = const {};
    _error = null;
  }

  Future<void> _pickDay() async {
    final today = ref.read(clock.todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: (_startsOn ?? today).toDateTime(),
      firstDate: (_ownerOrManager ? today.addDays(-90) : today).toDateTime(),
      lastDate: today.addDays(365).toDateTime(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _startsOn = LocalDate.of(picked);
      _clearErrors();
    });
  }

  Future<void> _sell(DeskPlan plan) async {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    setState(() {
      _selling = true;
      _clearErrors();
    });
    try {
      final sold = await ref
          .read(deskPlansRepositoryProvider)
          .sell(
            widget.member.id,
            plan.id,
            startsOn: _startsOn,
            promoCode: _promoCode.text,
            discount: _ownerOrManager ? _discount.text : null,
            discountReason: _discountReason.text,
          );
      navigator.pop(sold);
    } on ValidationFailure catch (failure) {
      if (!mounted) return;
      const shownByField = {'plan_id', 'starts_on', 'promo_code', 'discount', 'discount_reason'};
      setState(() {
        _selling = false;
        _fieldErrors = failure.fieldErrors;
        _error = failure.fieldErrors.keys.any(shownByField.contains) ? null : failureMessage(l10n, failure);
      });
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() {
        _selling = false;
        _error = failureMessage(l10n, failure);
      });
    }
  }

  Widget _section(IconData icon, String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final languageCode = ref.watch(languageCodeProvider);
    final dates = ref.watch(dateTextProvider);
    final plans = ref.watch(deskPlansProvider);

    final List<Widget> body;
    switch (plans) {
      case AsyncError(:final error):
        body = [
          LoadFailedCard(
            failure: error is Failure ? error : const UnexpectedFailure(),
            onRetry: () => ref.invalidate(deskPlansProvider),
          ),
        ];
      case AsyncData(value: []):
        body = [Text(l10n.sellNoPlans, style: textTheme.bodyMedium)];
      case AsyncData(value: final list):
        final chosen =
            list.where((plan) => plan.id == _planId).firstOrNull ??
            list.where((plan) => plan.name == widget.currentPlanName).firstOrNull ??
            list.first;
        final hasDiscount = _discount.text.trim().isNotEmpty;
        body = [
          _section(Icons.card_membership_rounded, l10n.sellPlan, [
            for (final plan in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PlanCard(
                  key: Key('plan-${plan.id}'),
                  plan: plan,
                  selected: plan == chosen,
                  isCurrent: plan.name == widget.currentPlanName,
                  onTap: _selling
                      ? null
                      : () => setState(() {
                          _planId = plan.id;
                          _clearErrors();
                        }),
                ),
              ),
            if (_fieldErrors['plan_id']?.firstOrNull case final error?)
              Text(error, style: textTheme.bodySmall?.copyWith(color: AppColors.danger)),
          ]),
          _section(Icons.event_rounded, l10n.sellStarts, [
            Material(
              color: AppColors.canvasTop,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.control),
                side: BorderSide(color: _fieldErrors['starts_on'] == null ? AppColors.line : AppColors.danger),
              ),
              child: InkWell(
                key: const Key('sell-starts'),
                onTap: _selling ? null : _pickDay,
                borderRadius: BorderRadius.circular(AppRadii.control),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _startsOn == null ? l10n.sellFirstFreeDay : dates.date(_startsOn!),
                          style: textTheme.titleSmall,
                        ),
                      ),
                      if (_startsOn != null)
                        IconButton(
                          tooltip: l10n.sellFirstFreeDay,
                          onPressed: _selling ? null : () => setState(() => _startsOn = null),
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                      const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _fieldErrors['starts_on']?.firstOrNull ?? l10n.sellStartsHelp,
              style: textTheme.bodySmall?.copyWith(
                color: _fieldErrors['starts_on'] == null ? AppColors.textSecondary : AppColors.danger,
              ),
            ),
          ]),
          _section(Icons.sell_rounded, l10n.sellPrice, [
            TextField(
              key: const Key('sell-promo-code'),
              controller: _promoCode,
              enabled: !_selling && !hasDiscount,
              maxLength: 30,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(_clearErrors),
              decoration: InputDecoration(
                labelText: l10n.sellPromoCode,
                hintText: l10n.sellPromoCodeHint,
                counterText: '',
                prefixIcon: const Icon(Icons.local_offer_outlined),
                errorText: _fieldErrors['promo_code']?.firstOrNull,
              ),
            ),
            if (_ownerOrManager) ...[
              const SizedBox(height: 12),
              TextField(
                key: const Key('sell-discount'),
                controller: _discount,
                enabled: !_selling && _promoCode.text.trim().isEmpty,
                onChanged: (_) => setState(_clearErrors),
                decoration: InputDecoration(
                  labelText: l10n.sellDiscount,
                  hintText: l10n.sellDiscountHint,
                  helperText: l10n.sellDiscountHelp,
                  prefixIcon: const Icon(Icons.percent_rounded),
                  errorText: _fieldErrors['discount']?.firstOrNull,
                ),
              ),
              if (hasDiscount) ...[
                const SizedBox(height: 12),
                TextField(
                  key: const Key('sell-discount-reason'),
                  controller: _discountReason,
                  enabled: !_selling,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.sellDiscountReason,
                    counterText: '',
                    errorText: _fieldErrors['discount_reason']?.firstOrNull,
                  ),
                ),
              ],
            ],
          ]),
          const SizedBox(height: 16),
          Text(
            hasDiscount
                ? l10n.sellSummaryDiscount(chosen.name, widget.member.name, chosen.price.format(languageCode))
                : l10n.sellSummary(chosen.name, widget.member.name, chosen.price.format(languageCode)),
            style: textTheme.titleSmall,
          ),
          if (_error case final error?) ...[
            const SizedBox(height: 12),
            Text(error, style: textTheme.bodyMedium?.copyWith(color: AppColors.danger)),
          ],
          const SizedBox(height: 20),
          PrimaryButton(label: l10n.sellConfirm, isLoading: _selling, onPressed: _selling ? null : () => _sell(chosen)),
        ];
      default:
        body = [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.ink)),
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
                  const Icon(Icons.autorenew_rounded),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l10n.sellTitle(widget.member.name), style: textTheme.titleLarge)),
                ],
              ),
              const SizedBox(height: 6),
              Text(l10n.sellBody, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              ...body,
            ],
          ),
        ),
      ),
    );
  }
}

/// One plan to choose, with its price and length.
class _PlanCard extends ConsumerWidget {
  const _PlanCard({super.key, required this.plan, required this.selected, required this.isCurrent, required this.onTap});

  final DeskPlan plan;
  final bool selected;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final languageCode = ref.watch(languageCodeProvider);
    return Material(
      color: selected ? AppColors.canvasTop : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        side: BorderSide(color: selected ? AppColors.ink : AppColors.line, width: selected ? 2 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.control),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: selected ? AppColors.ink : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(plan.name, style: textTheme.titleSmall),
                        if (isCurrent)
                          Text(l10n.sellCurrentPlan, style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                    Text(
                      [
                        deskPlanLength(l10n, plan),
                        if (plan.branchNames.isNotEmpty) plan.branchNames.join(', '),
                      ].join(' · '),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(plan.price.format(languageCode), style: textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}
