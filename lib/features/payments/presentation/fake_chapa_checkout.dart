import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/brand.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/controls.dart';
import '../../../core/design/widgets/surfaces.dart';
import '../../../core/errors/failure.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/network/api_client.dart';
import '../domain/billing.dart';

/// Stands in for Chapa's checkout while dev builds run on the fake backend:
/// no web page, no money. Paying here tells the fake backend the member
/// paid, as Chapa's webhook would tell the API. Never shown in prod, so its
/// text is English only.
class FakeChapaCheckout extends ConsumerStatefulWidget {
  const FakeChapaCheckout({super.key, required this.attempt, required this.onPaid, required this.onCancel});

  final PaymentAttempt attempt;
  final VoidCallback onPaid;
  final VoidCallback onCancel;

  @override
  ConsumerState<FakeChapaCheckout> createState() => _FakeChapaCheckoutState();
}

class _FakeChapaCheckoutState extends ConsumerState<FakeChapaCheckout> {
  static const _methods = ['telebirr', 'CBE Birr', 'M-Pesa', 'Card'];
  var _method = _methods.first;
  var _paying = false;

  Future<void> _pay() async {
    setState(() => _paying = true);
    try {
      await ref.read(apiClientProvider).post('/dev/fake-chapa/${widget.attempt.id}/pay');
    } on Failure {
      // The result screen asks the API either way.
    }
    if (mounted) widget.onPaid();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final brand = context.brand;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: const Color(0xFFFFF4D6), borderRadius: BorderRadius.circular(AppRadii.tile)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Test checkout: the fake backend stands in for Chapa. No money moves.',
              style: textTheme.bodySmall?.copyWith(color: const Color(0xFF7A5B00)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(brand.name, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(
                widget.attempt.amount.format(ref.watch(languageCodeProvider)),
                style: textTheme.headlineMedium?.copyWith(fontSize: 30),
              ),
              const Divider(height: 28, color: AppColors.line),
              for (final method in _methods)
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.tile),
                  onTap: () => setState(() => _method = method),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          _method == method ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: _method == method ? brand.primary : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 12),
                        Text(method, style: textTheme.titleSmall),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(label: 'Pay with $_method', isLoading: _paying, onPressed: () => unawaited(_pay())),
        const SizedBox(height: 8),
        TextButton(
          onPressed: widget.onCancel,
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          child: const Text('Cancel payment'),
        ),
      ],
    );
  }
}
