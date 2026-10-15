import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/design/brand.dart';
import '../../../core/design/widgets/controls.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/localization/l10n.dart';
import '../data/billing_repository.dart';

/// Pays an open invoice, or buys a plan: the API starts a Chapa payment and
/// the checkout opens. Shows why when it can't start.
class PayButton extends ConsumerStatefulWidget {
  const PayButton({super.key, required this.label, this.invoiceId, this.planId, this.compact = false})
    : assert((invoiceId == null) != (planId == null), 'Pay an invoice or a plan, not both');

  final String label;
  final String? invoiceId;
  final String? planId;

  /// A small brand-coloured button for cards, instead of the full-width one.
  final bool compact;

  @override
  ConsumerState<PayButton> createState() => _PayButtonState();
}

class _PayButtonState extends ConsumerState<PayButton> {
  var _starting = false;

  Future<void> _pay() async {
    setState(() => _starting = true);
    try {
      final attempt = await ref
          .read(billingRepositoryProvider)
          .startPayment(invoiceId: widget.invoiceId, planId: widget.planId);
      if (mounted) unawaited(context.push(AppRoutes.checkout(attempt.id), extra: attempt));
    } on Failure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failureMessage(context.l10n, failure))));
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.compact) return PrimaryButton(label: widget.label, isLoading: _starting, onPressed: _pay);
    final brand = context.brand;
    return FilledButton(
      onPressed: _starting ? () {} : _pay,
      style: FilledButton.styleFrom(
        backgroundColor: brand.primary,
        foregroundColor: brand.onPrimary,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _starting
          ? SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: brand.onPrimary))
          : Text(widget.label),
    );
  }
}
