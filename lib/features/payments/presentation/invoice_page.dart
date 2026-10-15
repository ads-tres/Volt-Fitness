import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/controls.dart';
import '../../../core/design/widgets/feedback.dart';
import '../../../core/design/widgets/surfaces.dart';
import '../../../core/errors/failure.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/time/date_text.dart';
import '../../../core/time/local_date.dart';
import '../data/billing_repository.dart';
import '../domain/billing.dart';
import 'pay_button.dart';
import 'payments_page.dart';

/// One invoice: what it covers, its status, and the receipt once paid.
class InvoicePage extends ConsumerWidget {
  const InvoicePage({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final invoice = ref.watch(invoiceProvider(invoiceId));

    return SoftBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(invoiceProvider(invoiceId).future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              ScreenHeader(
                leading: HeaderButton(
                  tooltip: l10n.back,
                  onPressed: () => context.pop(),
                  child: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                ),
                title: switch (invoice) {
                  AsyncData(:final value) => l10n.invoiceTitle(value.number),
                  _ => '',
                },
              ),
              const SizedBox(height: 24),
              switch (invoice) {
                AsyncData(:final value) => _InvoiceDetails(invoice: value),
                AsyncError(:final error) => LoadFailedCard(
                  failure: error is Failure ? error : const UnexpectedFailure(),
                  onRetry: () => ref.invalidate(invoiceProvider(invoiceId)),
                ),
                _ => const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceDetails extends ConsumerWidget {
  const _InvoiceDetails({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final languageCode = ref.watch(languageCodeProvider);
    final dates = ref.watch(dateTextProvider);
    final receipt = invoice.receipt;
    final dueOn = invoice.dueOn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(invoice.description, style: textTheme.titleMedium)),
                  InvoiceStatusText(status: invoice.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                invoice.total.format(languageCode),
                style: textTheme.headlineMedium?.copyWith(fontSize: 30, letterSpacing: -0.6),
              ),
              const Divider(height: 28, color: AppColors.line),
              _Row(label: l10n.issuedOn, value: dates.date(invoice.issuedOn)),
              if (dueOn != null && invoice.status == InvoiceStatus.open) ...[
                const SizedBox(height: 10),
                _Row(label: l10n.dueDate, value: dates.date(dueOn)),
              ],
              const Divider(height: 28, color: AppColors.line),
              for (final line in invoice.lines) ...[
                _Row(label: line.description, value: line.amount.format(languageCode)),
                const SizedBox(height: 10),
              ],
              _Row(label: l10n.total, value: invoice.total.format(languageCode), strong: true),
            ],
          ),
        ),
        if (receipt != null) ...[
          const SizedBox(height: 28),
          SectionHeader(l10n.receiptTitle),
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Row(label: l10n.receiptTitle, value: receipt.number),
                const SizedBox(height: 10),
                _Row(
                  label: l10n.paidOn,
                  value: '${dates.date(LocalDate.of(receipt.paidAt.toLocal()))} · ${dates.time(receipt.paidAt)}',
                ),
                if (receipt.method case final method?) ...[
                  const SizedBox(height: 10),
                  _Row(label: l10n.paymentMethod, value: paymentMethodName(method)),
                ],
                if (receipt.reference case final reference?) ...[
                  const SizedBox(height: 10),
                  _Row(label: l10n.paymentReference, value: reference),
                ],
                if (receipt.url case final url?) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => unawaited(launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: Text(l10n.openReceipt),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (invoice.status == InvoiceStatus.open) ...[
          const SizedBox(height: 24),
          PayButton(label: l10n.payAmount(invoice.total.format(languageCode)), invoiceId: invoice.id),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fixed shares, so every value ends at the card's right edge.
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: strong ? textTheme.titleSmall : textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(flex: 3, child: Text(value, textAlign: TextAlign.end, style: textTheme.titleSmall)),
      ],
    );
  }
}
