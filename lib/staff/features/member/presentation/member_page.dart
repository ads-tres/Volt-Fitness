import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/feedback.dart';
import '../../../../core/design/widgets/member_photo.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/money/payment_methods.dart';
import '../../../../core/time/date_text.dart';
import '../../../../core/time/local_date.dart';
import '../../../../core/utils/ethiopian_phone.dart';
import '../../desk/data/member_search.dart';
import '../../desk/data/new_member_repository.dart';
import '../../desk/presentation/member_photo_sheet.dart';
import '../../desk/presentation/new_member_sheet.dart';
import '../../memberships/data/desk_memberships_repository.dart';
import '../../memberships/presentation/membership_sheet.dart';
import '../../payments/presentation/take_payment_sheet.dart';
import '../../plans/presentation/sell_plan_sheet.dart';
import '../../scan/data/check_in_repository.dart';
import '../../scan/data/scan_outbox.dart';
import '../../scan/domain/desk_check_in.dart';
import '../../scan/presentation/check_in_result.dart';
import '../../scan/presentation/scan_page.dart';
import '../data/member_profile_repository.dart';

/// Every membership of the member, ended and cancelled too.
final memberHistoryProvider = FutureProvider.autoDispose.family<List<DeskMembership>, int>(
  (ref, memberId) => ref.read(deskMembershipsRepositoryProvider).history(memberId),
);

/// One member in full: who they are, what they can do at the desk, and
/// their memberships, payments and visits. Each part loads on its own, so
/// one failing doesn't hide the others.
class MemberPage extends ConsumerStatefulWidget {
  const MemberPage({super.key, required this.memberId});

  final int memberId;

  @override
  ConsumerState<MemberPage> createState() => _MemberPageState();
}

class _MemberPageState extends ConsumerState<MemberPage> {
  var _checkingIn = false;

  int get _id => widget.memberId;

  /// After an action: everything on the page loads again.
  void _reload() {
    ref
      ..invalidate(memberProfileProvider(_id))
      ..invalidate(memberHistoryProvider(_id));
    unawaited(ref.read(memberPaymentsProvider(_id).notifier).refresh());
    unawaited(ref.read(memberVisitsProvider(_id).notifier).refresh());
  }

  Future<void> _edit(DeskMemberProfile member) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await showNewMemberSheet(context, editing: member);
    if (!mounted || outcome == null) return;
    if (outcome.findPhone case final phone?) {
      // Their number belongs to someone else: look them up in Desk search.
      messenger.showSnackBar(SnackBar(content: Text(l10n.editMemberPhoneTaken(EthiopianPhone.format(phone)))));
      return;
    }
    if (outcome.saved) {
      _reload();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.editMemberSaved)));
    }
  }

  Future<void> _checkIn() async {
    setState(() => _checkingIn = true);
    try {
      final checkIn = await ref.read(checkInRepositoryProvider).atDesk(_id);
      unawaited(ref.read(scanOutboxProvider.notifier).flush());
      if (!mounted) return;
      setState(() => _checkingIn = false);
      final navigator = Navigator.of(context);
      final hide = Timer(ScanPage.resultShownFor, () {
        if (navigator.canPop()) navigator.pop();
      });
      await showGeneralDialog<void>(
        context: context,
        pageBuilder: (context, _, _) => CheckInResultView(checkIn: checkIn, onDone: () => Navigator.of(context).pop()),
      );
      hide.cancel();
      _reload();
    } on Failure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failureMessage(context.l10n, failure))));
      }
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = ref.watch(memberProfileProvider(_id));
    return Scaffold(
      appBar: AppBar(
        title: Text(profile.value?.name ?? l10n.memberPageTitle),
        actions: [
          if (profile.value case final member? when ref.watch(deskRolesProvider).mayAddMembers)
            IconButton(
              key: const Key('edit-member'),
              tooltip: l10n.editMember,
              onPressed: () => _edit(member),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: switch (profile) {
            AsyncData(:final value) => [
              _Header(profile: value, onChanged: _reload),
              const SizedBox(height: 16),
              _Actions(profile: value, checkingIn: _checkingIn, onCheckIn: _checkIn, onChanged: _reload),
              _Memberships(memberId: _id),
              if (ref.watch(deskRolesProvider).maySeePayments) _Payments(memberId: _id),
              _Visits(memberId: _id),
              _Details(profile: value),
            ],
            AsyncError(:final error) => [
              LoadFailedCard(
                failure: error is Failure ? error : const UnexpectedFailure(),
                onRetry: () => ref.invalidate(memberProfileProvider(_id)),
              ),
            ],
            _ => [
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.ink)),
              ),
            ],
          },
        ),
      ),
    );
  }
}

String _statusName(BuildContext context, String? status) {
  final l10n = context.l10n;
  return switch (status) {
    'active' => l10n.deskStatusActive,
    'frozen' => l10n.deskStatusFrozen,
    'upcoming' => l10n.deskStatusUpcoming,
    'expired' => l10n.memberStatusEnded,
    'cancelled' => l10n.memberStatusCancelled,
    _ => l10n.memberStatusNoPlan,
  };
}

Color _statusColor(String? status) => switch (status) {
  'active' => CheckInResultView.letInColor,
  'frozen' || 'upcoming' => const Color(0xFF1F5AA6),
  _ => CheckInResultView.turnedAwayColor,
};

class _Header extends ConsumerWidget {
  const _Header({required this.profile, required this.onChanged});

  final DeskMemberProfile profile;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final dates = ref.watch(dateTextProvider);
    final languageCode = ref.watch(languageCodeProvider);
    final asSearched = DeskMember(id: profile.id, name: profile.name, phone: profile.phone, photoUrl: profile.photoUrl);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: l10n.deskMemberPhoto(profile.name),
          excludeSemantics: true,
          child: InkWell(
            key: const Key('member-page-photo'),
            customBorder: const CircleBorder(),
            onTap: () => showMemberPhotoSheet(context, asSearched, onChanged: onChanged),
            child: MemberPhoto(url: profile.photoUrl, size: 96, fallback: InitialsCircle(name: profile.name, size: 96)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.name, style: textTheme.headlineSmall),
              InkWell(
                onTap: () => unawaited(launchUrl(Uri(scheme: 'tel', path: profile.phone))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone_rounded, size: 16),
                      const SizedBox(width: 6),
                      Flexible(child: Text(EthiopianPhone.format(profile.phone), style: textTheme.bodyMedium)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Chip(
                    key: const Key('member-status'),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: _statusColor(profile.status)),
                    label: Text(
                      [
                        _statusName(context, profile.status),
                        ?profile.planName,
                      ].join(' · '),
                      style: textTheme.labelMedium?.copyWith(color: _statusColor(profile.status)),
                    ),
                  ),
                  if (profile.discountGroupName case final group?)
                    Chip(visualDensity: VisualDensity.compact, label: Text(group, style: textTheme.labelMedium)),
                ],
              ),
              if (profile.balanceDue.amountMinor > 0)
                Text(
                  key: const Key('member-owes'),
                  l10n.deskOwes(profile.balanceDue.format(languageCode)),
                  style: textTheme.titleSmall?.copyWith(color: AppColors.danger),
                ),
              Text(
                [
                  if (profile.registeredOn case final day?) l10n.memberSince(dates.date(day)),
                  ?profile.homeBranchName,
                ].join(' · '),
                style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.profile, required this.checkingIn, required this.onCheckIn, required this.onChanged});

  final DeskMemberProfile profile;
  final bool checkingIn;
  final VoidCallback onCheckIn;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final roles = ref.watch(deskRolesProvider);
    final member = (id: profile.id, name: profile.name, phone: profile.phone);
    final style = OutlinedButton.styleFrom(minimumSize: const Size(0, 40));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          key: const Key('member-page-check-in'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: checkingIn ? null : onCheckIn,
          icon: checkingIn
              ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.login_rounded, size: 18),
          label: Text(l10n.deskCheckIn),
        ),
        if (roles.maySeePayments && profile.balanceDue.amountMinor > 0)
          OutlinedButton.icon(
            key: const Key('member-page-pay'),
            style: style,
            onPressed: () => showTakePaymentSheet(context, member, onPaid: onChanged),
            icon: const Icon(Icons.payments_rounded, size: 18),
            label: Text(l10n.deskTakePayment),
          ),
        if (roles.maySell)
          OutlinedButton.icon(
            key: const Key('member-page-sell'),
            style: style,
            onPressed: () => showSellPlanSheet(context, member, currentPlanName: profile.planName, onSold: onChanged),
            icon: const Icon(Icons.autorenew_rounded, size: 18),
            label: Text(l10n.deskSellPlan),
          ),
        if (roles.mayFreeze)
          OutlinedButton.icon(
            key: const Key('member-page-membership'),
            style: style,
            onPressed: () => showMembershipSheet(context, member, onChanged: onChanged),
            icon: const Icon(Icons.card_membership_rounded, size: 18),
            label: Text(l10n.deskMembershipAction),
          ),
      ],
    );
  }
}

/// A titled part of the page.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.children});

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  );
}

const _sectionLoading = Padding(
  padding: EdgeInsets.all(16),
  child: Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.ink)),
);

class _Memberships extends ConsumerWidget {
  const _Memberships({required this.memberId});

  final int memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final dates = ref.watch(dateTextProvider);
    final languageCode = ref.watch(languageCodeProvider);
    final history = ref.watch(memberHistoryProvider(memberId));
    return _Section(
      title: l10n.memberMemberships,
      icon: Icons.card_membership_rounded,
      children: switch (history) {
        AsyncData(value: []) => [Text(l10n.memberNoMemberships, style: textTheme.bodyMedium)],
        AsyncData(:final value) => [
          for (final membership in value)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${membership.planName} · ${_statusName(context, membership.status)}'),
              subtitle: Text(
                [
                  '${dates.date(membership.startsOn)} – ${dates.date(membership.endsOn)}',
                  for (final freeze in membership.freezes)
                    l10n.deskFrozenFrom(dates.date(freeze.startsOn), dates.date(freeze.endsOn)),
                ].join('\n'),
              ),
              trailing: switch (membership.balanceDue) {
                final due? when due.amountMinor > 0 => Text(
                  l10n.deskOwes(due.format(languageCode)),
                  style: textTheme.bodySmall?.copyWith(color: AppColors.danger),
                ),
                _ => null,
              },
            ),
        ],
        AsyncError(:final error) => [
          LoadFailedCard(
            failure: error is Failure ? error : const UnexpectedFailure(),
            onRetry: () => ref.invalidate(memberHistoryProvider(memberId)),
          ),
        ],
        _ => const [_sectionLoading],
      },
    );
  }
}

class _Payments extends ConsumerWidget {
  const _Payments({required this.memberId});

  final int memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final dates = ref.watch(dateTextProvider);
    final languageCode = ref.watch(languageCodeProvider);
    final payments = ref.watch(memberPaymentsProvider(memberId));
    final notifier = ref.read(memberPaymentsProvider(memberId).notifier);
    return _Section(
      title: l10n.memberPayments,
      icon: Icons.receipt_long_rounded,
      children: [
        if (payments.items.isEmpty && !payments.isLoading && payments.failure == null)
          Text(l10n.memberNoPayments, style: textTheme.bodyMedium),
        for (final receipt in payments.items)
          ListTile(
            key: Key('receipt-${receipt.receiptNumber}'),
            contentPadding: EdgeInsets.zero,
            title: Text(
              [
                receipt.receiptNumber,
                if (receipt.isRefund) l10n.memberRefund,
                if (receipt.voided) l10n.memberVoided,
              ].join(' · '),
            ),
            subtitle: Text(
              [dates.date(receipt.paidOn), paymentMethodName(l10n, receipt.method), ?receipt.planName].join(' · '),
            ),
            trailing: Text(
              '${receipt.isRefund ? '−' : ''}${receipt.amount.format(languageCode)}',
              style: textTheme.titleSmall?.copyWith(decoration: receipt.voided ? TextDecoration.lineThrough : null),
            ),
          ),
        ..._pageFooter(context, payments, notifier.loadMore, notifier.refresh),
      ],
    );
  }
}

class _Visits extends ConsumerWidget {
  const _Visits({required this.memberId});

  final int memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final dates = ref.watch(dateTextProvider);
    final visits = ref.watch(memberVisitsProvider(memberId));
    final notifier = ref.read(memberVisitsProvider(memberId).notifier);
    return _Section(
      title: l10n.memberVisits,
      icon: Icons.history_rounded,
      children: [
        if (visits.items.isEmpty && !visits.isLoading && visits.failure == null)
          Text(l10n.memberNoVisits, style: textTheme.bodyMedium),
        for (final DeskCheckIn visit in visits.items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              visit.letIn ? Icons.check_circle_rounded : Icons.block_rounded,
              color: visit.letIn ? CheckInResultView.letInColor : CheckInResultView.turnedAwayColor,
            ),
            title: Text(
              '${dates.date(LocalDate.of(visit.checkedInAt.toLocal()))} · ${DateFormat.Hm().format(visit.checkedInAt.toLocal())}',
            ),
            subtitle: Text([?visit.branchName, if (!visit.letIn) deskReason(l10n, visit.reasonCode)].join(' · ')),
          ),
        ..._pageFooter(context, visits, notifier.loadMore, notifier.refresh),
      ],
    );
  }
}

/// The loading spinner, error card or Load more under a paged list.
List<Widget> _pageFooter<T>(BuildContext context, PagedList<T> list, VoidCallback loadMore, VoidCallback retry) => [
  if (list.failure case final failure?) LoadFailedCard(failure: failure, onRetry: retry),
  if (list.isLoading) _sectionLoading,
  if (!list.isLoading && list.failure == null && list.nextPage != null && list.items.isNotEmpty)
    Align(
      alignment: Alignment.centerLeft,
      child: TextButton(onPressed: loadMore, child: Text(context.l10n.memberLoadMore)),
    ),
];

class _Details extends ConsumerWidget {
  const _Details({required this.profile});

  final DeskMemberProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final dates = ref.watch(dateTextProvider);
    Widget row(String label, String value, {VoidCallback? onTap}) => ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
      trailing: onTap == null ? null : const Icon(Icons.phone_rounded, size: 18),
      onTap: onTap,
    );
    return _Section(
      title: l10n.memberDetails,
      icon: Icons.badge_outlined,
      children: [
        if (profile.gender case final gender?)
          row(l10n.memberGender, gender == 'female' ? l10n.newMemberFemale : l10n.newMemberMale),
        if (profile.dateOfBirth case final day?) row(l10n.newMemberBirthday, dates.date(day)),
        if (profile.email case final email?) row(l10n.newMemberEmail, email),
        if ((profile.emergencyContactName, profile.emergencyContactPhone) case (final name?, final phone?))
          row(
            l10n.newMemberEmergency,
            '$name · ${EthiopianPhone.format(phone)}',
            onTap: () => unawaited(launchUrl(Uri(scheme: 'tel', path: phone))),
          ),
        row(l10n.memberLanguage, profile.messageLanguage == 'am' ? 'አማርኛ' : 'English'),
      ],
    );
  }
}
