import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/json.dart';
import '../../../core/tenant/selected_organization.dart';
import '../../../core/utils/uuid.dart';
import '../domain/billing.dart';
import 'billing_json.dart';

/// Billing at the selected gym. Every call throws a [Failure] when it fails.
final class BillingRepository {
  BillingRepository(this._api);

  final ApiClient _api;

  Future<List<Plan>> plans() async {
    final response = await _api.get('/plans');
    return readResponse(() => [for (final plan in (response! as Map<String, dynamic>).objects('data')) planFromJson(plan)]);
  }

  /// The latest invoices, newest first.
  Future<List<Invoice>> invoices() async {
    final response = await _api.get('/invoices', query: {'per_page': 30});
    return readResponse(
      () => [for (final invoice in (response! as Map<String, dynamic>).objects('data')) invoiceFromJson(invoice)],
    );
  }

  Future<Invoice> invoice(String id) async {
    final data = dataObject(await _api.get('/invoices/$id'));
    return readResponse(() => invoiceFromJson(data));
  }

  /// Starts paying an open invoice, or buying a plan. The API works out the
  /// amount and asks Chapa for a checkout page. The idempotency key makes a
  /// retried request return the same attempt instead of a second charge.
  Future<PaymentAttempt> startPayment({String? invoiceId, String? planId}) async {
    assert((invoiceId == null) != (planId == null), 'Pay an invoice or a plan, not both');
    final data = dataObject(
      await _api.post(
        '/payment-attempts',
        body: {'invoice_id': ?invoiceId, 'plan_id': ?planId},
        idempotencyKey: uuidV4(),
      ),
    );
    return readResponse(() => paymentAttemptFromJson(data));
  }

  Future<PaymentAttempt> attempt(String id) async {
    final data = dataObject(await _api.get('/payment-attempts/$id'));
    return readResponse(() => paymentAttemptFromJson(data));
  }
}

final billingRepositoryProvider = Provider<BillingRepository>((ref) => BillingRepository(ref.watch(apiClientProvider)));

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
