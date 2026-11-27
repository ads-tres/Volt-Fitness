import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/money/money.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/json.dart';
import '../../../../core/time/local_date.dart';
import '../../../core/desk_session.dart';

/// How the desk took the money. Online payments come only through a link.
enum DeskPaymentMethod {
  cash('cash'),
  telebirr('telebirr'),
  cbeBirr('cbe_birr'),
  bankTransfer('bank_transfer');

  const DeskPaymentMethod(this.api);

  final String api;

  /// Every method but cash needs the transaction number from the
  /// confirmation.
  bool get hasReference => this != cash;
}

/// A membership of the member's that still has money due.
final class OwingMembership {
  const OwingMembership({
    required this.id,
    required this.planName,
    required this.startsOn,
    required this.endsOn,
    required this.balanceDue,
    this.openLinkId,
  });

  final int id;
  final String planName;
  final LocalDate startsOn;
  final LocalDate endsOn;
  final Money balanceDue;

  /// A pay-online link already sent and not paid yet.
  final int? openLinkId;
}

/// A payment the desk recorded, as on its receipt.
final class RecordedPayment {
  const RecordedPayment({required this.receiptNumber, required this.amount});

  final String receiptNumber;
  final Money amount;
}

/// A membership from the staff API, or null when nothing is due on it.
OwingMembership? owingMembershipFromJson(Map<String, dynamic> json) {
  final due = json.optional<Map<String, dynamic>>('balance_due');
  if (due == null) return null;
  final balanceDue = Money.fromJson(due);
  if (balanceDue.amountMinor <= 0 || json.optional<Map<String, dynamic>>('cancellation') != null) return null;
  return OwingMembership(
    id: json.field<int>('id'),
    planName: json.field<Map<String, dynamic>>('plan').field<String>('name'),
    startsOn: LocalDate.parse(json.field<String>('starts_on')),
    endsOn: LocalDate.parse(json.field<String>('ends_on')),
    balanceDue: balanceDue,
    openLinkId: json.optional<Map<String, dynamic>>('open_payment_link')?.optional<int>('id'),
  );
}

/// Money taken at the desk, at the desk's branch: cash and transfers
/// recorded (`POST memberships/{id}/payments`), or a pay-online link texted
/// to the member (`POST memberships/{id}/payment-links`, then `sms`). Every
/// call throws a [Failure]; the API's refusals are [ValidationFailure]s on
/// the field they are about.
final class DeskPaymentsRepository {
  const DeskPaymentsRepository(this._api, this._session);

  final ApiClient _api;
  final DeskSession Function() _session;

  String _path(String path) => deskPath(_session(), path);

  int get _branchId => switch (_session()) {
    DeskSignedIn(branch: final branch?) => branch.id,
    _ => throw StateError('No branch is chosen'),
  };

  /// The member's memberships with money due, newest first.
  Future<List<OwingMembership>> owing(int memberId) async {
    final response = await _api.get(_path('/members/$memberId/memberships'));
    return readResponse(
      () => [
        for (final membership in (response! as Map<String, dynamic>).objects('data'))
          ?owingMembershipFromJson(membership),
      ],
    );
  }

  Future<RecordedPayment> record(
    int membershipId, {
    required Money amount,
    required DeskPaymentMethod method,
    String? reference,
    LocalDate? paidOn,
  }) async {
    final response = await _api.post(
      _path('/memberships/$membershipId/payments'),
      body: {
        'amount': amountText(amount),
        'method': method.api,
        if (method.hasReference) 'reference': reference?.trim(),
        'branch_id': _branchId,
        'paid_on': ?paidOn?.toIso(),
      },
    );
    return readResponse(() {
      final payment = (response! as Map<String, dynamic>).field<Map<String, dynamic>>('data');
      return RecordedPayment(
        receiptNumber: payment.field<String>('receipt_number'),
        amount: Money.fromJson(payment.field<Map<String, dynamic>>('amount')),
      );
    });
  }

  /// Opens a pay-online link for [amount] and texts it to the member.
  Future<void> textNewLink(int membershipId, {required Money amount}) async {
    final response = await _api.post(
      _path('/memberships/$membershipId/payment-links'),
      body: {'amount': amountText(amount), 'branch_id': _branchId},
    );
    final linkId = readResponse(
      () => (response! as Map<String, dynamic>).field<Map<String, dynamic>>('data').field<int>('id'),
    );
    await textLink(linkId);
  }

  /// Texts an open link to the member again.
  Future<void> textLink(int linkId) => _api.post(_path('/payment-links/$linkId/sms'));

  /// The amount as the API reads it: "1000.50".
  static String amountText(Money amount) =>
      '${amount.amountMinor ~/ 100}.${(amount.amountMinor % 100).toString().padLeft(2, '0')}';
}

final deskPaymentsRepositoryProvider = Provider<DeskPaymentsRepository>(
  (ref) => DeskPaymentsRepository(ref.watch(apiClientProvider), () => ref.read(deskSessionProvider)),
);
