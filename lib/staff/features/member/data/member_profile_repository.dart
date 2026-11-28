import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/money/money.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/json.dart';
import '../../../../core/time/local_date.dart';
import '../../../core/desk_session.dart';
import '../../scan/domain/desk_check_in.dart';

/// Everything the desk shows about one member.
final class DeskMemberProfile {
  const DeskMemberProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.balanceDue,
    this.email,
    this.gender,
    this.dateOfBirth,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.messageLanguage,
    this.photoUrl,
    this.homeBranchName,
    this.homeBranchId,
    this.planName,
    this.status,
    this.endsOn,
    this.discountGroupName,
    this.registeredOn,
  });

  final int id;
  final String name;
  final String phone;
  final Money balanceDue;
  final String? email;

  /// `female` or `male`.
  final String? gender;
  final LocalDate? dateOfBirth;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  /// `en` or `am`.
  final String? messageLanguage;

  /// A link that works for 10 minutes; never stored.
  final String? photoUrl;
  final String? homeBranchName;
  final int? homeBranchId;
  final String? planName;

  /// Their membership today: `active`, `frozen`, `upcoming`, `expired` or
  /// `cancelled`, or null with none.
  final String? status;
  final LocalDate? endsOn;
  final String? discountGroupName;
  final LocalDate? registeredOn;
}

/// A payment or refund on one of the member's memberships.
final class DeskReceipt {
  const DeskReceipt({
    required this.id,
    required this.receiptNumber,
    required this.isRefund,
    required this.amount,
    required this.method,
    required this.paidOn,
    required this.voided,
    this.planName,
    this.branchName,
  });

  final int id;
  final String receiptNumber;
  final bool isRefund;
  final Money amount;

  /// `cash`, `telebirr`, `cbe_birr`, `bank_transfer`, `chapa` or
  /// `brought_in`.
  final String method;
  final LocalDate paidOn;
  final bool voided;
  final String? planName;
  final String? branchName;
}

/// One page of a list, and whether there is another.
typedef DeskPage<T> = ({List<T> items, bool hasMore});

DeskMemberProfile deskMemberProfileFromJson(Map<String, dynamic> json) {
  final membership = json.optional<Map<String, dynamic>>('membership');
  final contact = json.optional<Map<String, dynamic>>('emergency_contact');
  LocalDate? day(String? iso) => iso == null ? null : LocalDate.parse(iso.length > 10 ? iso.substring(0, 10) : iso);
  return DeskMemberProfile(
    id: json.field<int>('id'),
    name: json.field<String>('full_name'),
    phone: json.field<String>('phone'),
    balanceDue: switch (json.optional<Map<String, dynamic>>('balance_due')) {
      final money? => Money.fromJson(money),
      null => const Money(0, 'ETB'),
    },
    email: json.optional<String>('email'),
    gender: json.optional<String>('gender'),
    dateOfBirth: day(json.optional<String>('date_of_birth')),
    emergencyContactName: contact?.optional<String>('name'),
    emergencyContactPhone: contact?.optional<String>('phone'),
    messageLanguage: json.optional<String>('message_language'),
    photoUrl: json.optional<String>('photo_url'),
    homeBranchName: json.optional<Map<String, dynamic>>('home_branch')?.optional<String>('name'),
    homeBranchId: json.optional<Map<String, dynamic>>('home_branch')?.optional<int>('id'),
    planName: membership?.optional<Map<String, dynamic>>('plan')?.optional<String>('name'),
    status: membership?.optional<String>('status'),
    endsOn: day(membership?.optional<String>('ends_on')),
    discountGroupName: json.optional<Map<String, dynamic>>('discount_group')?.optional<String>('name'),
    // The gym's day it was made on is near enough; the UTC date is shown.
    registeredOn: day(json.optional<String>('registered_at')),
  );
}

DeskReceipt deskReceiptFromJson(Map<String, dynamic> json) => DeskReceipt(
  id: json.field<int>('id'),
  receiptNumber: json.field<String>('receipt_number'),
  isRefund: json.optional<String>('type') == 'refund',
  amount: Money.fromJson(json.field<Map<String, dynamic>>('amount')),
  method: json.optional<String>('method') ?? '',
  paidOn: LocalDate.parse(json.field<String>('paid_on')),
  voided: json.optional<Map<String, dynamic>>('void') != null,
  planName: json.optional<Map<String, dynamic>>('membership')?.optional<Map<String, dynamic>>('plan')?.optional<String>('name'),
  branchName: json.optional<Map<String, dynamic>>('branch')?.optional<String>('name'),
);

/// One member at the desk (`GET members/{id}`), with their payments
/// (`GET payments?member_id=`) and visits (`GET check-ins?member_id=`),
/// newest first, 25 a page. Every call throws a [Failure].
final class MemberProfileRepository {
  const MemberProfileRepository(this._api, this._session);

  final ApiClient _api;
  final DeskSession Function() _session;

  Future<DeskMemberProfile> member(int memberId) async {
    final response = await _api.get(deskPath(_session(), '/members/$memberId'));
    return readResponse(
      () => deskMemberProfileFromJson((response! as Map<String, dynamic>).field<Map<String, dynamic>>('data')),
    );
  }

  Future<DeskPage<DeskReceipt>> payments(int memberId, {int page = 1}) =>
      _page('/payments', memberId, page, deskReceiptFromJson);

  Future<DeskPage<DeskCheckIn>> visits(int memberId, {int page = 1}) =>
      _page('/check-ins', memberId, page, deskCheckInFromJson);

  Future<DeskPage<T>> _page<T>(String path, int memberId, int page, T Function(Map<String, dynamic>) read) async {
    final response = await _api.get(deskPath(_session(), path), query: {'member_id': memberId, 'page': page});
    return readResponse(() {
      final json = response! as Map<String, dynamic>;
      return (
        items: [for (final item in json.objects('data')) read(item)],
        hasMore: json.optional<Map<String, dynamic>>('links')?.optional<String>('next') != null,
      );
    });
  }
}

final memberProfileRepositoryProvider = Provider<MemberProfileRepository>(
  (ref) => MemberProfileRepository(ref.watch(apiClientProvider), () => ref.read(deskSessionProvider)),
);

/// The member at the top of their page.
final memberProfileProvider = FutureProvider.autoDispose.family<DeskMemberProfile, int>(
  (ref, memberId) => ref.read(memberProfileRepositoryProvider).member(memberId),
);

/// A list on the member's page, loaded a page at a time.
final class PagedList<T> {
  const PagedList({this.items = const [], this.nextPage = 1, this.isLoading = false, this.failure});

  final List<T> items;

  /// The page to load next, or null when all are loaded.
  final int? nextPage;
  final bool isLoading;
  final Failure? failure;
}

/// Pages through one member's payments or visits, newest first.
abstract base class MemberPages<T> extends Notifier<PagedList<T>> {
  MemberPages(this.memberId);

  final int memberId;

  Future<DeskPage<T>> fetch(MemberProfileRepository repository, int page);

  @override
  PagedList<T> build() {
    Future.microtask(refresh);
    return const PagedList(isLoading: true);
  }

  Future<void> refresh() async {
    state = const PagedList(isLoading: true);
    await _load(1, const []);
  }

  Future<void> loadMore() async {
    final next = state.nextPage;
    if (next == null || state.isLoading) return;
    state = PagedList(items: state.items, nextPage: next, isLoading: true);
    await _load(next, state.items);
  }

  Future<void> _load(int page, List<T> keep) async {
    try {
      final result = await fetch(ref.read(memberProfileRepositoryProvider), page);
      if (ref.mounted) state = PagedList(items: [...keep, ...result.items], nextPage: result.hasMore ? page + 1 : null);
    } on Failure catch (failure) {
      if (ref.mounted) state = PagedList(items: keep, nextPage: page, failure: failure);
    }
  }
}

final class MemberPayments extends MemberPages<DeskReceipt> {
  MemberPayments(super.memberId);

  @override
  Future<DeskPage<DeskReceipt>> fetch(MemberProfileRepository repository, int page) =>
      repository.payments(memberId, page: page);
}

final class MemberVisits extends MemberPages<DeskCheckIn> {
  MemberVisits(super.memberId);

  @override
  Future<DeskPage<DeskCheckIn>> fetch(MemberProfileRepository repository, int page) =>
      repository.visits(memberId, page: page);
}

final memberPaymentsProvider = NotifierProvider.autoDispose.family<MemberPayments, PagedList<DeskReceipt>, int>(
  MemberPayments.new,
);

final memberVisitsProvider = NotifierProvider.autoDispose.family<MemberVisits, PagedList<DeskCheckIn>, int>(
  MemberVisits.new,
);
