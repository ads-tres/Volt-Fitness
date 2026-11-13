import '../../../core/money/money.dart';
import '../../../core/network/json.dart';
import '../../../core/time/local_date.dart';
import '../domain/billing.dart';

/// A plan the member can buy (`GET /me/gyms/{gym}/plans`). The API gives the
/// dates it would run if bought now; its length is counted from those, both
/// days included.
Plan planFromJson(Map<String, dynamic> json) => Plan(
  id: '${json.field<Object>('id')}',
  name: json.field<String>('name'),
  durationDays:
      LocalDate.parse(json.field<String>('starts_on')).daysUntil(LocalDate.parse(json.field<String>('ends_on'))) + 1,
  price: Money.fromJson(json.field<Map<String, dynamic>>('price')),
);

/// A receipt (`GET /me/gyms/{gym}/payments`), shown as a paid invoice for the
/// plan of its membership. A voided receipt shows as void.
Invoice invoiceFromJson(Map<String, dynamic> json) {
  final amount = Money.fromJson(json.field<Map<String, dynamic>>('amount'));
  final planName = json.optional<Map<String, dynamic>>('membership')?.optional<Map<String, dynamic>>('plan')?.optional<String>('name');
  final description = switch ((planName, json.optional<String>('type'))) {
    (final name?, 'refund') => '$name refund',
    (final name?, _) => '$name plan',
    (null, _) => json.field<String>('receipt_number'),
  };
  final paidOn = LocalDate.parse(json.field<String>('paid_on'));
  return Invoice(
    id: '${json.field<Object>('id')}',
    number: json.field<String>('receipt_number'),
    description: description,
    total: amount,
    status: json.optional<bool>('voided') == true ? InvoiceStatus.voided : InvoiceStatus.paid,
    issuedOn: paidOn,
    lines: [InvoiceLine(description: description, amount: amount)],
    receipt: Receipt(
      number: json.field<String>('receipt_number'),
      paidAt: DateTime(paidOn.year, paidOn.month, paidOn.day),
      method: json.optional<String>('method'),
      reference: json.optional<String>('reference'),
    ),
  );
}

/// What is owed on [membership], or null when nothing is.
OutstandingInvoice? outstandingFromMembership(Map<String, dynamic>? membership) {
  if (membership == null) return null;
  final balance = switch (membership.optional<Map<String, dynamic>>('balance_due')) {
    final json? => Money.fromJson(json),
    null => null,
  };
  if (balance == null || balance.amountMinor <= 0) return null;
  return OutstandingInvoice(
    invoiceId: '${membership.field<Object>('id')}',
    amount: balance,
    number: membership.optional<Map<String, dynamic>>('plan')?.optional<String>('name'),
  );
}

/// A payment link (`/me/gyms/{gym}/payment-links/{id}`): the attempt to pay
/// through Chapa. `paid` succeeded; `cancelled` and `refund_needed` (paid
/// after the membership changed, so the gym refunds it) won't go through.
PaymentAttempt paymentAttemptFromJson(Map<String, dynamic> json) => PaymentAttempt(
  id: '${json.field<Object>('id')}',
  status: switch (json.optional<String>('status')) {
    'pending' => PaymentStatus.pending,
    'paid' => PaymentStatus.succeeded,
    'cancelled' => PaymentStatus.cancelled,
    'refund_needed' => PaymentStatus.failed,
    _ => PaymentStatus.unknown,
  },
  amount: Money.fromJson(json.field<Map<String, dynamic>>('amount')),
  checkoutUrl: json.optional<String>('checkout_url') ?? '',
  invoiceId: switch (json.optional<Map<String, dynamic>>('payment')?['id']) {
    final Object id => '$id',
    null => null,
  },
);
