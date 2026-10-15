import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/design/brand.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/controls.dart';
import '../../../core/design/widgets/feedback.dart';
import '../../../core/design/widgets/surfaces.dart';
import '../../../core/errors/failure.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/language_menu.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/time/date_text.dart';
import '../../home/data/dashboard_repository.dart';
import '../data/billing_repository.dart';
import '../domain/billing.dart';
import 'pay_button.dart';

/// What the member owes, the plans they can buy, and what they paid.
class PaymentsPage extends ConsumerWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final outstanding = ref.watch(dashboardProvider).value?.outstanding;
    final plans = ref.watch(plansProvider);
    final invoices = ref.watch(invoicesProvider);

    return SoftBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(plansProvider)
              ..invalidate(invoicesProvider);
            await ref.read(dashboardProvider.notifier).refresh();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              ScreenHeader(title: l10n.navPayments, trailing: const LanguageMenu()),
              const SizedBox(height: 24),
              if (outstanding != null) ...[DueCard(outstanding: outstanding), const SizedBox(height: 28)],
              SectionHeader(l10n.plansTitle),
              switch (plans) {
                // A row, not a fixed-height list, so cards size to their
                // content at any text size.
                AsyncData(:final value) => SingleChildScrollView(
                  key: const Key('plans'),
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 14,
                    children: [
                      for (final (index, plan) in value.indexed) _PlanCard(plan: plan, photo: planPhoto(index)),
                    ],
                  ),
                ),
                AsyncError(:final error) => LoadFailedCard(
                  failure: error is Failure ? error : const UnexpectedFailure(),
                  onRetry: () => ref.invalidate(plansProvider),
                ),
                _ => const _Loading(),
              },
              const SizedBox(height: 28),
              SectionHeader(l10n.historyTitle),
              switch (invoices) {
                AsyncData(value: final list) when list.isEmpty => AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    l10n.noInvoices,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                AsyncData(:final value) => Column(
                  children: [
                    for (final invoice in value)
                      Padding(padding: const EdgeInsets.only(bottom: 10), child: _InvoiceRow(invoice: invoice)),
                  ],
                ),
                AsyncError(:final error) => LoadFailedCard(
                  failure: error is Failure ? error : const UnexpectedFailure(),
                  onRetry: () => ref.invalidate(invoicesProvider),
                ),
                _ => const _Loading(),
              },
            ],
          ),
        ),
      ),
    );
  }
}

/// A bundled gym photo for a plan with no photo of its own.
String planPhoto(int index) => const [
  'assets/photos/onboarding_train.jpg',
  'assets/photos/home_check_in.jpg',
  'assets/photos/onboarding_renew.jpg',
][index % 3];

/// The unpaid invoice, with the way to pay it.
class DueCard extends ConsumerWidget {
  const DueCard({super.key, required this.outstanding, this.compact = false});

  final OutstandingInvoice outstanding;

  /// The home screen's one-line version.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final languageCode = ref.watch(languageCodeProvider);
    final dates = ref.watch(dateTextProvider);
    final dueOn = outstanding.dueOn;
    final details = [
      if (dueOn != null) l10n.dueOn(dates.dayMonth(dueOn)),
      if (!compact) ?outstanding.number,
    ].join(' · ');

    if (compact) {
      return AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long_rounded, color: AppColors.danger, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.paymentDue, style: textTheme.bodySmall),
                  Text(outstanding.amount.format(languageCode), style: textTheme.titleMedium),
                  if (details.isNotEmpty) Text(details, style: textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PayButton(label: l10n.pay, invoiceId: outstanding.invoiceId, compact: true),
          ],
        ),
      );
    }
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.amountDue, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            outstanding.amount.format(languageCode),
            style: textTheme.headlineMedium?.copyWith(fontSize: 30, letterSpacing: -0.6),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(details, style: textTheme.bodySmall?.copyWith(color: AppColors.danger)),
          ],
          const SizedBox(height: 16),
          PayButton(label: l10n.payNow, invoiceId: outstanding.invoiceId),
        ],
      ),
    );
  }
}

/// A plan as a photo card, like a recipe card: photo, name, length, price.
class _PlanCard extends ConsumerWidget {
  const _PlanCard({required this.plan, required this.photo});

  final Plan plan;
  final String photo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final languageCode = ref.watch(languageCodeProvider);
    return SizedBox(
      width: 236,
      child: AppCard(
        padding: const EdgeInsets.all(12),
        onTap: () => showPlanSheet(context, plan: plan, photo: photo),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.control + 2),
              child: _PlanPhoto(plan: plan, photo: photo, height: 150),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.name, style: textTheme.titleMedium),
                  Text(l10n.gaugeDays(plan.durationDays), style: textTheme.bodySmall),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.price.format(languageCode),
                          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded, color: context.brand.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanPhoto extends StatelessWidget {
  const _PlanPhoto({required this.plan, required this.photo, required this.height});

  final Plan plan;
  final String photo;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bundled = Image.asset(photo, height: height, width: double.infinity, fit: BoxFit.cover);
    return switch (plan.photoUrl) {
      final url? => Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => bundled,
      ),
      null => bundled,
    };
  }
}

/// Confirms a plan before paying: what it is, what it costs, who takes the
/// payment.
Future<void> showPlanSheet(BuildContext context, {required Plan plan, required String photo}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card))),
      builder: (context) => _PlanSheet(plan: plan, photo: photo),
    );

class _PlanSheet extends ConsumerWidget {
  const _PlanSheet({required this.plan, required this.photo});

  final Plan plan;
  final String photo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final price = plan.price.format(ref.watch(languageCodeProvider));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.card - 4),
              child: _PlanPhoto(plan: plan, photo: photo, height: 170),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.name, style: textTheme.headlineSmall),
                      Text(l10n.gaugeDays(plan.durationDays), style: textTheme.bodyMedium),
                    ],
                  ),
                ),
                Text(price, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            Text(l10n.confirmPlanBody, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            PayButton(label: l10n.payAmount(price), planId: plan.id),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_rounded, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.securedByChapa,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceRow extends ConsumerWidget {
  const _InvoiceRow({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final dates = ref.watch(dateTextProvider);
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.go(AppRoutes.invoice(invoice.id)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: const Color(0xFFF2EEE8), borderRadius: BorderRadius.circular(AppRadii.tile)),
            child: const Icon(Icons.receipt_long_rounded, color: AppColors.ink, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoice.description, style: textTheme.titleSmall),
                Text('${invoice.number} · ${dates.date(invoice.issuedOn)}', style: textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(invoice.total.format(ref.watch(languageCodeProvider)), style: textTheme.titleSmall),
              const SizedBox(height: 2),
              InvoiceStatusText(status: invoice.status),
            ],
          ),
        ],
      ),
    );
  }
}

class InvoiceStatusText extends StatelessWidget {
  const InvoiceStatusText({super.key, required this.status});

  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, color) = switch (status) {
      InvoiceStatus.paid => (l10n.invoiceStatusPaid, context.brand.primary),
      InvoiceStatus.open => (l10n.invoiceStatusOpen, AppColors.danger),
      InvoiceStatus.voided => (l10n.invoiceStatusVoid, AppColors.textTertiary),
      InvoiceStatus.unknown => (l10n.statusUnknown, AppColors.textTertiary),
    };
    return Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w600));
  }
}

/// How a receipt names the way the member paid.
String paymentMethodName(String method) => switch (method) {
  'telebirr' => 'telebirr',
  'cbebirr' => 'CBE Birr',
  'mpesa' => 'M-Pesa',
  'card' => 'Card',
  _ => method,
};

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(32),
    child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
  );
}
