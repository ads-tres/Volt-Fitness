import '../../../core/money/money.dart';
import '../../../core/network/json.dart';
import '../../../core/time/local_date.dart';
import '../domain/billing.dart';

Plan planFromJson(Map<String, dynamic> json) => Plan(
  id: json.field<String>('id'),
  name: json.field<String>('name'),
  durationDays: json.field<int>('duration_days'),
  price: Money.fromJson(json.field<Map<String, dynamic>>('price')),
  photoUrl: json.optional<String>('photo_url'),
);

Invoice invoiceFromJson(Map<String, dynamic> json) => Invoice(
  id: json.field<String>('id'),
  number: json.field<String>('number'),
  description: json.field<String>('description'),
  total: Money.fromJson(json.field<Map<String, dynamic>>('total')),
  status: switch (json.optional<String>('status')) {
    'open' => InvoiceStatus.open,
    'paid' => InvoiceStatus.paid,
    'void' => InvoiceStatus.voided,
    _ => InvoiceStatus.unknown,
  },
  issuedOn: LocalDate.parse(json.field<String>('issued_on')),
  dueOn: switch (json.optional<String>('due_on')) {
    final iso? => LocalDate.parse(iso),
    null => null,
  },
  lines: [
    for (final line in json.objects('lines'))
      InvoiceLine(
        description: line.field<String>('description'),
        amount: Money.fromJson(line.field<Map<String, dynamic>>('amount')),
      ),
  ],
  receipt: switch (json.optional<Map<String, dynamic>>('receipt')) {
    final receipt? => Receipt(
      number: receipt.field<String>('number'),
      paidAt: DateTime.parse(receipt.field<String>('paid_at')).toUtc(),
      method: receipt.optional<String>('method'),
      reference: receipt.optional<String>('reference'),
      url: receipt.optional<String>('url'),
    ),
    null => null,
  },
);

OutstandingInvoice outstandingFromJson(Map<String, dynamic> json) => OutstandingInvoice(
  invoiceId: json.field<String>('invoice_id'),
  amount: Money.fromJson(json.field<Map<String, dynamic>>('amount')),
  number: json.optional<String>('number'),
  dueOn: switch (json.optional<String>('due_on')) {
    final iso? => LocalDate.parse(iso),
    null => null,
  },
);

PaymentAttempt paymentAttemptFromJson(Map<String, dynamic> json) => PaymentAttempt(
  id: json.field<String>('id'),
  status: PaymentStatus.values.where((status) => status.name == json.optional<String>('status')).firstOrNull ??
      PaymentStatus.unknown,
  amount: Money.fromJson(json.field<Map<String, dynamic>>('amount')),
  checkoutUrl: json.field<String>('checkout_url'),
  returnUrl: json.field<String>('return_url'),
  invoiceId: json.optional<String>('invoice_id'),
  failureReason: json.optional<String>('failure_reason'),
);
