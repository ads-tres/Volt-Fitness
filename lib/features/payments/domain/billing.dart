import '../../../core/money/money.dart';
import '../../../core/time/local_date.dart';

/// A plan the member can buy or renew at the selected gym. The price shown
/// is the API's; the API charges what it calculates, not what the app sent.
final class Plan {
  const Plan({required this.id, required this.name, required this.durationDays, required this.price, this.photoUrl});

  final String id;
  final String name;
  final int durationDays;
  final Money price;
  final String? photoUrl;
}

enum InvoiceStatus { open, paid, voided, unknown }

final class InvoiceLine {
  const InvoiceLine({required this.description, required this.amount});

  final String description;
  final Money amount;
}

/// Proof of a payment Chapa confirmed and the API verified.
final class Receipt {
  const Receipt({required this.number, required this.paidAt, this.method, this.reference, this.url});

  final String number;
  final DateTime paidAt;

  /// The way the member paid, such as `telebirr` or `cbebirr`.
  final String? method;

  /// Chapa's reference, for the gym to look the payment up.
  final String? reference;

  /// A printable copy, when the API offers one.
  final String? url;
}

final class Invoice {
  const Invoice({
    required this.id,
    required this.number,
    required this.description,
    required this.total,
    required this.status,
    required this.issuedOn,
    this.dueOn,
    this.lines = const [],
    this.receipt,
  });

  final String id;
  final String number;
  final String description;
  final Money total;
  final InvoiceStatus status;
  final LocalDate issuedOn;
  final LocalDate? dueOn;
  final List<InvoiceLine> lines;

  /// Set once the invoice is paid.
  final Receipt? receipt;
}

/// The unpaid invoice the home screen points at.
final class OutstandingInvoice {
  const OutstandingInvoice({required this.invoiceId, required this.amount, this.number, this.dueOn});

  final String invoiceId;
  final Money amount;
  final String? number;
  final LocalDate? dueOn;
}

enum PaymentStatus {
  pending,
  processing,
  succeeded,
  failed,
  expired,
  cancelled,
  unknown;

  /// Nothing more will happen to the attempt.
  bool get isFinal => this == succeeded || this == failed || this == expired || this == cancelled;
}

/// One try at paying through Chapa. Its status comes from the API, which
/// hears from Chapa and verifies the payment; the app never decides it.
final class PaymentAttempt {
  const PaymentAttempt({
    required this.id,
    required this.status,
    required this.amount,
    required this.checkoutUrl,
    required this.returnUrl,
    this.invoiceId,
    this.failureReason,
  });

  final String id;
  final PaymentStatus status;
  final Money amount;

  /// Chapa's hosted checkout page.
  final String checkoutUrl;

  /// Where Chapa sends the member after paying. The app watches for it to
  /// close the checkout; reaching it proves nothing about the payment.
  final String returnUrl;
  final String? invoiceId;
  final String? failureReason;
}
