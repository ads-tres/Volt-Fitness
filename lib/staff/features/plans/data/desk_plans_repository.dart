import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/money/money.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/json.dart';
import '../../../../core/time/local_date.dart';
import '../../../core/desk_session.dart';

/// A plan the gym sells.
final class DeskPlan {
  const DeskPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationCount,
    required this.durationUnit,
    this.visitLimit,
    this.branchNames = const [],
  });

  final int id;
  final String name;
  final Money price;
  final int durationCount;

  /// `day`, `week`, `month` or `year`.
  final String durationUnit;
  final int? visitLimit;

  /// Empty when the plan is good at every branch.
  final List<String> branchNames;
}

/// A membership the desk just sold, with what is due on it.
final class SoldMembership {
  const SoldMembership({
    required this.id,
    required this.planName,
    required this.startsOn,
    required this.endsOn,
    required this.price,
    required this.balanceDue,
  });

  final int id;
  final String planName;
  final LocalDate startsOn;
  final LocalDate endsOn;
  final Money price;
  final Money balanceDue;
}

/// A plan from the staff API (`GET /organizations/{gym}/plans`).
DeskPlan deskPlanFromJson(Map<String, dynamic> json) {
  final duration = json.field<Map<String, dynamic>>('duration');
  final everywhere = json.optional<bool>('available_at_all_branches') ?? true;
  return DeskPlan(
    id: json.field<int>('id'),
    name: json.field<String>('name'),
    price: Money.fromJson(json.field<Map<String, dynamic>>('price')),
    durationCount: duration.field<int>('count'),
    durationUnit: duration.field<String>('unit'),
    visitLimit: json.optional<int>('visit_limit'),
    branchNames: everywhere
        ? const []
        : [for (final branch in json.objects('branches')) branch.field<String>('name')],
  );
}

SoldMembership soldMembershipFromJson(Map<String, dynamic> json) => SoldMembership(
  id: json.field<int>('id'),
  planName: json.field<Map<String, dynamic>>('plan').field<String>('name'),
  startsOn: LocalDate.parse(json.field<String>('starts_on')),
  endsOn: LocalDate.parse(json.field<String>('ends_on')),
  price: Money.fromJson(json.field<Map<String, dynamic>>('price')),
  balanceDue: Money.fromJson(json.field<Map<String, dynamic>>('balance_due')),
);

/// Selling a member a plan at the desk (`POST members/{id}/memberships`).
/// The member pays the lowest of the plan's price, their discount group's
/// and the promo code's; owners and managers may type a discount instead.
/// Every call throws a [Failure]; the API's refusals are
/// [ValidationFailure]s on the field they are about.
final class DeskPlansRepository {
  const DeskPlansRepository(this._api, this._session);

  final ApiClient _api;
  final DeskSession Function() _session;

  Future<List<DeskPlan>> plans() async {
    final response = await _api.get(deskPath(_session(), '/plans'));
    return readResponse(
      () => [for (final plan in (response! as Map<String, dynamic>).objects('data')) deskPlanFromJson(plan)],
    );
  }

  /// Sells [planId] to the member, starting [startsOn] or else on their
  /// first free day.
  Future<SoldMembership> sell(
    int memberId,
    int planId, {
    LocalDate? startsOn,
    String? promoCode,
    String? discount,
    String? discountReason,
  }) async {
    final code = promoCode?.trim() ?? '';
    final off = discount?.trim() ?? '';
    final response = await _api.post(
      deskPath(_session(), '/members/$memberId/memberships'),
      body: {
        'plan_id': planId,
        'starts_on': ?startsOn?.toIso(),
        if (code.isNotEmpty) 'promo_code': code,
        if (off.isNotEmpty) ...{'discount': off, 'discount_reason': discountReason?.trim()},
      },
    );
    return readResponse(
      () => soldMembershipFromJson((response! as Map<String, dynamic>).field<Map<String, dynamic>>('data')),
    );
  }
}

final deskPlansRepositoryProvider = Provider<DeskPlansRepository>(
  (ref) => DeskPlansRepository(ref.watch(apiClientProvider), () => ref.read(deskSessionProvider)),
);

/// The gym's plans on sale, read once per gym while the desk is open.
final deskPlansProvider = FutureProvider.autoDispose<List<DeskPlan>>((ref) {
  ref.watch(deskSessionProvider.select((session) => session is DeskSignedIn ? session.gym?.slug : null));
  return ref.read(deskPlansRepositoryProvider).plans();
});
