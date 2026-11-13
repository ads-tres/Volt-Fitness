import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/json.dart';
import '../../../core/tenant/gym_path.dart';
import '../../../core/tenant/selected_organization.dart';
import '../domain/billing.dart';
import 'billing_json.dart';

/// Billing at the selected gym, as the members-app contract has it: plans to
/// buy, receipts, and payment links that open Chapa's checkout. Every call
/// throws a [Failure] when it fails.
final class BillingRepository {
  BillingRepository(this._api, this._gym);

  final ApiClient _api;

  /// The selected gym's slug.
  final String? Function() _gym;

  String _path(String path) => gymPath(_gym(), path);

  /// The plans the member can buy at their home branch, cheapest first.
  Future<List<Plan>> plans() async {
    final response = await _api.get(_path('/plans'));
    return readResponse(() => [for (final plan in (response! as Map<String, dynamic>).objects('data')) planFromJson(plan)]);
  }

  /// The latest receipts, newest first.
  Future<List<Invoice>> invoices() async {
    final response = await _api.get(_path('/payments'));
    return readResponse(
      () => [for (final receipt in (response! as Map<String, dynamic>).objects('data')) invoiceFromJson(receipt)],
    );
  }

  Future<Invoice> invoice(String id) async {
    final data = dataObject(await _api.get(_path('/payments/$id')));
    return readResponse(() => invoiceFromJson(data));
  }

  /// Starts paying what is owed on a membership ([invoiceId] is the
  /// membership, see [OutstandingInvoice]), or buying a plan. The API works
  /// out the amount and asks Chapa for a checkout page. Asking again gives
  /// the same open link, so a retry never charges twice.
  Future<PaymentAttempt> startPayment({String? invoiceId, String? planId}) async {
    assert((invoiceId == null) != (planId == null), 'Pay a membership or a plan, not both');
    final path = invoiceId != null ? '/memberships/$invoiceId/payment-link' : '/plans/$planId/purchase';
    final data = dataObject(await _api.post(_path(path)));
    return readResponse(() => paymentAttemptFromJson(data));
  }

  /// The payment link as the API last heard of it.
  Future<PaymentAttempt> attempt(String id) async {
    final data = dataObject(await _api.get(_path('/payment-links/$id')));
    return readResponse(() => paymentAttemptFromJson(data));
  }

  /// Has the API ask Chapa about the payment now, after the member comes
  /// back from the checkout. The API allows ten a minute.
  Future<PaymentAttempt> check(String id) async {
    final data = dataObject(await _api.post(_path('/payment-links/$id/check')));
    return readResponse(() => paymentAttemptFromJson(data));
  }
}

final billingRepositoryProvider = Provider<BillingRepository>(
  (ref) => BillingRepository(ref.watch(apiClientProvider), () => ref.read(selectedOrganizationProvider)?.id),
);

final plansProvider = FutureProvider.autoDispose<List<Plan>>((ref) {
  ref.watch(selectedOrganizationProvider.select((organization) => organization?.id));
  return ref.watch(billingRepositoryProvider).plans();
});

final invoicesProvider = FutureProvider.autoDispose<List<Invoice>>((ref) {
  ref.watch(selectedOrganizationProvider.select((organization) => organization?.id));
  return ref.watch(billingRepositoryProvider).invoices();
});

final invoiceProvider = FutureProvider.autoDispose.family<Invoice, String>(
  (ref, id) => ref.watch(billingRepositoryProvider).invoice(id),
);
