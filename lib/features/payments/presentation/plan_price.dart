import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/brand.dart';
import '../../../core/design/tokens.dart';
import '../../../core/errors/failure.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/locale_controller.dart';
import '../data/billing_repository.dart';
import '../domain/billing.dart';

/// What the member pays for [plan], bold; when that is less than the list
/// price, the list price struck through and a tag naming why ("Student", or
/// the code).
class PlanPrice extends ConsumerWidget {
  const PlanPrice({super.key, required this.plan, this.style});

  final Plan plan;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final languageCode = ref.watch(languageCodeProvider);
    final pays = Text(
      plan.pays.format(languageCode),
      style: (style ?? textTheme.titleLarge)?.copyWith(fontWeight: FontWeight.w700),
    );
    if (plan.yourPrice == null) return pays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              plan.price.format(languageCode),
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            if (plan.discountName case final name?)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.brand.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Text(
                    name,
                    style: textTheme.labelMedium?.copyWith(color: context.brand.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
        pays,
      ],
    );
  }
}

/// "Have a promo code?": a field to apply one to every plan, then a chip
/// with the code to remove it. The API's refusal shows under the field.
class PromoCodeField extends ConsumerStatefulWidget {
  const PromoCodeField({super.key});

  @override
  ConsumerState<PromoCodeField> createState() => _PromoCodeFieldState();
}

class _PromoCodeFieldState extends ConsumerState<PromoCodeField> {
  final _code = TextEditingController();
  bool _open = false;
  bool _applying = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    setState(() {
      _applying = true;
      _error = null;
    });
    try {
      await ref.read(promoCodeProvider.notifier).apply(_code.text);
      if (!mounted) return;
      _code.clear();
      setState(() => _open = false);
    } on ValidationFailure catch (failure) {
      if (mounted) setState(() => _error = failure.fieldErrors['promo_code']?.firstOrNull ?? failure.message);
    } on Failure {
      if (mounted) setState(() => _error = context.l10n.errorNetwork);
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final applied = ref.watch(promoCodeProvider);
    if (applied != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: InputChip(
          key: const Key('promo-code-applied'),
          avatar: const Icon(Icons.local_offer_rounded, size: 18),
          label: Text(l10n.promoCodeApplied(applied)),
          onDeleted: ref.read(promoCodeProvider.notifier).remove,
          deleteButtonTooltipMessage: l10n.promoCodeRemove,
        ),
      );
    }
    if (!_open) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() => _open = true),
          icon: const Icon(Icons.local_offer_outlined, size: 18),
          label: Text(l10n.promoCodeAsk),
          style: TextButton.styleFrom(foregroundColor: AppColors.ink, padding: EdgeInsets.zero),
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            key: const Key('promo-code'),
            controller: _code,
            autofocus: true,
            enabled: !_applying,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(hintText: l10n.promoCodeHint, errorText: _error, errorMaxLines: 3),
            onSubmitted: (_) => _apply(),
          ),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: FilledButton(
            onPressed: _applying ? null : _apply,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            child: Text(l10n.promoCodeApply),
          ),
        ),
      ],
    );
  }
}
