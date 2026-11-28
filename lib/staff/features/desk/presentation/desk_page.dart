import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/feedback.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/design/widgets/member_photo.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/utils/ethiopian_phone.dart';
import '../../memberships/presentation/membership_sheet.dart';
import '../../payments/presentation/take_payment_sheet.dart';
import '../../plans/presentation/sell_plan_sheet.dart';
import '../../scan/data/check_in_repository.dart';
import '../../scan/data/scan_outbox.dart';
import '../../scan/presentation/check_in_result.dart';
import '../../scan/presentation/desk_app_bar.dart';
import '../../scan/presentation/scan_page.dart';
import '../data/member_search.dart';
import '../data/new_member_repository.dart';
import 'member_photo_sheet.dart';
import 'new_member_sheet.dart';
import 'welcome_member_sheet.dart';

/// Checking in a member without their phone: find them by name or phone,
/// then tap to check them in at the desk's branch. The same rules apply as
/// at the scanner, and the same answer fills the screen.
class DeskPage extends ConsumerStatefulWidget {
  const DeskPage({super.key});

  @override
  ConsumerState<DeskPage> createState() => _DeskPageState();
}

class _DeskPageState extends ConsumerState<DeskPage> {
  /// The small actions under a member's name.
  static final _rowAction = TextButton.styleFrom(
    minimumSize: const Size(0, 36),
    padding: EdgeInsets.zero,
    alignment: Alignment.centerLeft,
  );

  final _search = TextEditingController();
  var _typed = '';
  Timer? _debounce;
  int? _checkingIn;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onTyped(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _typed = text);
    });
  }

  Future<void> _checkIn(DeskMember member) async {
    setState(() => _checkingIn = member.id);
    try {
      final checkIn = await ref.read(checkInRepositoryProvider).atDesk(member.id);
      unawaited(ref.read(scanOutboxProvider.notifier).flush());
      if (!mounted) return;
      setState(() => _checkingIn = null);
      final navigator = Navigator.of(context);
      final hide = Timer(ScanPage.resultShownFor, () {
        if (navigator.canPop()) navigator.pop();
      });
      var takePayment = false;
      var renew = false;
      var endFreeze = false;
      await showGeneralDialog<void>(
        context: context,
        pageBuilder: (context, _, _) => CheckInResultView(
          checkIn: checkIn,
          onDone: () => Navigator.of(context).pop(),
          onTakePayment: () {
            takePayment = true;
            Navigator.of(context).pop();
          },
          onRenew: ref.read(deskRolesProvider).maySell
              ? () {
                  renew = true;
                  Navigator.of(context).pop();
                }
              : null,
          onEndFreeze: ref.read(deskRolesProvider).mayFreeze
              ? () {
                  endFreeze = true;
                  Navigator.of(context).pop();
                }
              : null,
        ),
      );
      hide.cancel();
      if (endFreeze && mounted) {
        await showMembershipSheet(
          context,
          (id: member.id, name: member.name, phone: member.phone),
          onChanged: () => ref.invalidate(memberSearchProvider(_typed)),
        );
      }
      if (renew && mounted) {
        await showSellPlanSheet(
          context,
          (id: member.id, name: member.name, phone: member.phone),
          currentPlanName: member.planName,
          onSold: () => ref.invalidate(memberSearchProvider(_typed)),
        );
      }
      if (takePayment && mounted) {
        await showTakePaymentSheet(
          context,
          (id: member.id, name: member.name, phone: member.phone),
          onPaid: () => ref.invalidate(memberSearchProvider(_typed)),
        );
      }
    } on Failure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failureMessage(context.l10n, failure))));
      }
    } finally {
      if (mounted) setState(() => _checkingIn = null);
    }
  }

  /// Shows [text] in search at once, without waiting for the debounce.
  void _searchFor(String text) {
    _debounce?.cancel();
    _search.text = text;
    setState(() => _typed = text);
  }

  Future<void> _addMember() async {
    final outcome = await showNewMemberSheet(context, typed: _search.text);
    if (outcome == null || !mounted) return;
    if (outcome.findPhone case final phone?) {
      _searchFor(phone);
      return;
    }
    final member = outcome.added!;
    _searchFor(member.name);
    await welcomeNewMember(context, member, onChanged: () => ref.invalidate(memberSearchProvider(_typed)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final languageCode = ref.watch(languageCodeProvider);
    final results = ref.watch(memberSearchProvider(_typed));
    final roles = ref.watch(deskRolesProvider);
    final mayAdd = roles.mayAddMembers;
    return Scaffold(
      appBar: const DeskAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _search,
            autofocus: true,
            onChanged: _onTyped,
            decoration: InputDecoration(labelText: l10n.deskSearchMembers, prefixIcon: const Icon(Icons.search_rounded)),
          ),
          if (mayAdd)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('add-member'),
                onPressed: _addMember,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: Text(l10n.deskAddMember),
              ),
            ),
          const SizedBox(height: 8),
          switch (results) {
            AsyncData(value: []) when _typed.trim().length >= 2 => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.deskNoMembersFound, style: textTheme.bodyMedium),
                if (mayAdd)
                  TextButton(
                    style: _rowAction,
                    onPressed: _addMember,
                    child: Text(l10n.deskNoMembersFoundAdd),
                  ),
              ],
            ),
            AsyncData(value: []) => Text(l10n.deskSearchHint, style: textTheme.bodyMedium),
            AsyncData(:final value) => Column(
              children: [
                for (final member in value)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Semantics(
                      button: true,
                      label: l10n.deskMemberPhoto(member.name),
                      excludeSemantics: true,
                      child: InkWell(
                        key: Key('member-photo-${member.id}'),
                        customBorder: const CircleBorder(),
                        onTap: () => showMemberPhotoSheet(context, member, onChanged: () => ref.invalidate(memberSearchProvider(_typed))),
                        child: MemberPhoto(url: member.photoUrl, size: 44, fallback: InitialsCircle(name: member.name, size: 44)),
                      ),
                    ),
                    title: Text(member.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            EthiopianPhone.format(member.phone),
                            ?member.planName,
                            if (member.balanceDue case final owed? when owed.amountMinor > 0)
                              l10n.deskOwes(owed.format(languageCode)),
                          ].join(' · '),
                        ),
                        Wrap(
                          spacing: 16,
                          children: [
                            if (member.balanceDue case final owed? when owed.amountMinor > 0)
                              TextButton.icon(
                                key: Key('take-payment-${member.id}'),
                                style: _rowAction,
                                onPressed: () => showTakePaymentSheet(
                                  context,
                                  (id: member.id, name: member.name, phone: member.phone),
                                  onPaid: () => ref.invalidate(memberSearchProvider(_typed)),
                                ),
                                icon: const Icon(Icons.payments_rounded, size: 18),
                                label: Text(l10n.deskTakePayment),
                              ),
                            if (roles.maySell)
                            TextButton.icon(
                              key: Key('sell-plan-${member.id}'),
                              style: _rowAction,
                              onPressed: () => showSellPlanSheet(
                                context,
                                (id: member.id, name: member.name, phone: member.phone),
                                currentPlanName: member.planName,
                                onSold: () => ref.invalidate(memberSearchProvider(_typed)),
                              ),
                              icon: const Icon(Icons.autorenew_rounded, size: 18),
                              label: Text(l10n.deskSellPlan),
                            ),
                            if (roles.mayFreeze)
                              TextButton.icon(
                                key: Key('membership-${member.id}'),
                                style: _rowAction,
                                onPressed: () => showMembershipSheet(
                                  context,
                                  (id: member.id, name: member.name, phone: member.phone),
                                  onChanged: () => ref.invalidate(memberSearchProvider(_typed)),
                                ),
                                icon: const Icon(Icons.card_membership_rounded, size: 18),
                                label: Text(l10n.deskMembershipAction),
                              ),
                          ],
                        ),
                      ],
                    ),
                    trailing: _checkingIn == member.id
                        ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                        : FilledButton(
                            // The theme's buttons are full width; this one sits in a row.
                            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                            onPressed: _checkingIn == null ? () => _checkIn(member) : null,
                            child: Text(l10n.deskCheckIn),
                          ),
                  ),
              ],
            ),
            AsyncError(:final error) => LoadFailedCard(
              failure: error is Failure ? error : const UnexpectedFailure(),
              onRetry: () => ref.invalidate(memberSearchProvider(_typed)),
            ),
            _ => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.ink)),
            ),
          },
        ],
      ),
    );
  }
}
