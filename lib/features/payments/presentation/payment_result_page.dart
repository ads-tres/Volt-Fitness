import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/design/brand.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/controls.dart';
import '../../../core/design/widgets/surfaces.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/time/date_text.dart';
import '../../home/data/dashboard_repository.dart';
import '../data/billing_repository.dart';
import '../domain/billing.dart';

/// What became of a payment, as the API says. Coming back from Chapa
/// proves nothing, so this asks until the API has verified the payment or
/// given up, for about half a minute.
class PaymentResultPage extends ConsumerStatefulWidget {
  const PaymentResultPage({super.key, required this.attemptId, this.left = false});

  final String attemptId;

  /// The member closed the checkout before Chapa sent them back.
  final bool left;

  @override
  ConsumerState<PaymentResultPage> createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends ConsumerState<PaymentResultPage> {
  static const _interval = Duration(seconds: 2);
  static const _maxChecks = 15;

  PaymentAttempt? _attempt;
  Failure? _failure;
  Timer? _next;
  var _checks = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_check());
  }

  @override
  void dispose() {
    _next?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    _checks++;
    try {
      final attempt = await ref.read(billingRepositoryProvider).attempt(widget.attemptId);
      if (!mounted) return;
      setState(() {
        _attempt = attempt;
        _failure = null;
      });
      if (attempt.status == PaymentStatus.succeeded) {
        // The membership and invoices changed on the server.
        unawaited(ref.read(dashboardProvider.notifier).refresh());
        ref
          ..invalidate(invoicesProvider)
          ..invalidate(plansProvider);
      }
      final keepWaiting = !attempt.status.isFinal && !_leftUnpaid && _checks < _maxChecks;
      if (keepWaiting) _next = Timer(_interval, _check);
    } on Failure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    }
  }

  /// Left the checkout, and the API has not heard of a payment either.
  bool get _leftUnpaid => widget.left && _attempt?.status == PaymentStatus.pending;

  void _retry() {
    setState(() => _failure = null);
    unawaited(_check());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final attempt = _attempt;
    final status = attempt?.status;
    final languageCode = ref.watch(languageCodeProvider);
    final brand = context.brand;

    final _Outcome outcome;
    if (_failure case final failure? when attempt == null) {
      outcome = _Outcome(
        icon: Icons.cloud_off_rounded,
        color: AppColors.textSecondary,
        title: l10n.loadFailed,
        body: failureMessage(l10n, failure),
        primary: (l10n.retry, _retry),
      );
    } else if (status == PaymentStatus.succeeded) {
      final endsOn = ref.watch(dashboardProvider).value?.membership?.endsOn;
      outcome = _Outcome(
        icon: Icons.check_rounded,
        color: brand.primary,
        title: l10n.resultSucceeded,
        amount: attempt!.amount.format(languageCode),
        body: endsOn == null ? l10n.resultSucceededBody : l10n.resultSucceededUntil(ref.watch(dateTextProvider).date(endsOn)),
        primary: (l10n.done, () => context.go(AppRoutes.home)),
        secondary: switch (attempt.invoiceId) {
          final invoiceId? => (l10n.viewReceipt, () => context.go(AppRoutes.invoice(invoiceId))),
          null => (l10n.backToPayments, () => context.go(AppRoutes.payments)),
        },
      );
    } else if (status == PaymentStatus.failed || status == PaymentStatus.expired || status == PaymentStatus.cancelled) {
      outcome = _Outcome(
        icon: Icons.close_rounded,
        color: AppColors.danger,
        title: l10n.resultFailed,
        body: attempt!.failureReason ?? l10n.resultFailedBody,
        primary: (l10n.retry, () => context.go(AppRoutes.payments)),
        secondary: (l10n.done, () => context.go(AppRoutes.home)),
      );
    } else if (_leftUnpaid) {
      outcome = _Outcome(
        icon: Icons.hourglass_empty_rounded,
        color: AppColors.textSecondary,
        title: l10n.resultNotFinished,
        body: l10n.resultNotFinishedBody,
        primary: (l10n.backToPayments, () => context.go(AppRoutes.payments)),
        secondary: (l10n.done, () => context.go(AppRoutes.home)),
      );
    } else if (_checks >= _maxChecks && _next?.isActive != true) {
      outcome = _Outcome(
        icon: Icons.schedule_rounded,
        color: AppColors.textSecondary,
        title: l10n.resultStillConfirming,
        body: l10n.resultStillConfirmingBody,
        primary: (l10n.done, () => context.go(AppRoutes.home)),
      );
    } else {
      outcome = _Outcome(
        title: l10n.resultConfirming,
        body: l10n.resultConfirmingBody,
        amount: attempt?.amount.format(languageCode),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.payments);
      },
      child: Scaffold(
        body: SoftBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: _OutcomeView(outcome: outcome),
            ),
          ),
        ),
      ),
    );
  }
}

final class _Outcome {
  const _Outcome({
    required this.title,
    required this.body,
    this.icon,
    this.color,
    this.amount,
    this.primary,
    this.secondary,
  });

  /// Null while waiting: a spinner shows instead.
  final IconData? icon;
  final Color? color;
  final String title;
  final String body;
  final String? amount;
  final (String, VoidCallback)? primary;
  final (String, VoidCallback)? secondary;
}

class _OutcomeView extends StatelessWidget {
  const _OutcomeView({required this.outcome});

  final _Outcome outcome;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = outcome.color ?? context.brand.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Center(
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: switch (outcome.icon) {
              final icon? => Icon(icon, size: 52, color: color),
              null => SizedBox.square(dimension: 44, child: CircularProgressIndicator(strokeWidth: 3, color: color)),
            },
          ),
        ),
        const SizedBox(height: 28),
        Text(outcome.title, textAlign: TextAlign.center, style: textTheme.headlineSmall),
        if (outcome.amount case final amount?) ...[
          const SizedBox(height: 6),
          Text(amount, textAlign: TextAlign.center, style: textTheme.titleLarge?.copyWith(color: color)),
        ],
        const SizedBox(height: 10),
        Text(
          outcome.body,
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const Spacer(),
        if (outcome.primary case (final label, final action)) PrimaryButton(label: label, onPressed: action),
        if (outcome.secondary case (final label, final action)) ...[
          const SizedBox(height: 10),
          OutlinedButton(onPressed: action, child: Text(label)),
        ],
      ],
    );
  }
}
