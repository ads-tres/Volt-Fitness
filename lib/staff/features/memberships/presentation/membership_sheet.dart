import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/feedback.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/time/clock.dart' as clock;
import '../../../../core/time/date_text.dart';
import '../../desk/data/new_member_repository.dart';
import '../../payments/presentation/take_payment_sheet.dart';
import '../data/desk_memberships_repository.dart';
import 'freeze_membership_sheet.dart';

/// The member's memberships that run or are still to come, to freeze, end
/// a freeze or (owners and managers) cancel. [onChanged] runs after each
/// change, so the caller can refresh.
Future<void> showMembershipSheet(BuildContext context, PayingMember member, {required VoidCallback onChanged}) {
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card))),
    builder: (context) => MembershipSheet(member: member, onChanged: onChanged),
  );
}

class MembershipSheet extends ConsumerStatefulWidget {
  const MembershipSheet({super.key, required this.member, required this.onChanged});

  final PayingMember member;
  final VoidCallback onChanged;

  @override
  ConsumerState<MembershipSheet> createState() => _MembershipSheetState();
}

class _MembershipSheetState extends ConsumerState<MembershipSheet> {
  List<DeskMembership>? _memberships;
  Failure? _loadFailure;
  String? _message;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _loadFailure = null);
    try {
      final memberships = await ref.read(deskMembershipsRepositoryProvider).memberships(widget.member.id);
      if (mounted) setState(() => _memberships = memberships);
    } on Failure catch (failure) {
      if (mounted) setState(() => _loadFailure = failure);
    }
  }

  /// After a change: say [done], reload, and let the caller refresh.
  Future<void> _changed(String done) async {
    widget.onChanged();
    setState(() => _message = done);
    await _load();
  }

  Future<void> _freeze(DeskMembership membership) async {
    final l10n = context.l10n;
    final frozen = await showFreezeMembershipSheet(context, membership);
    if (frozen == true && mounted) await _changed(l10n.deskFrozen);
  }

  Future<void> _endFreeze(DeskMembership membership, DeskFreeze freeze) async {
    final l10n = context.l10n;
    final dates = ref.read(dateTextProvider);
    final started = freeze.hasStarted(ref.read(clock.todayProvider));
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.wb_sunny_outlined),
        title: Text(started ? l10n.deskEndFreezeTitle : l10n.deskRemoveFreezeTitle),
        content: Text(
          started ? l10n.deskEndFreezeBody(dates.date(freeze.endsOn)) : l10n.deskRemoveFreezeBody(freeze.days),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.deskKeepFreeze)),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(started ? l10n.deskEndFreeze : l10n.deskRemoveFreeze),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(deskMembershipsRepositoryProvider).endFreeze(membership.id, freeze.id);
      if (mounted) await _changed(started ? l10n.deskFreezeEnded : l10n.deskFreezeRemoved);
    } on ValidationFailure catch (failure) {
      if (mounted) setState(() => _message = failure.fieldErrors.values.firstOrNull?.firstOrNull ?? failureMessage(l10n, failure));
    } on Failure catch (failure) {
      if (mounted) setState(() => _message = failureMessage(l10n, failure));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(DeskMembership membership) async {
    final cancelled = await showDialog<bool>(
      context: context,
      builder: (context) => _CancelDialog(membership: membership),
    );
    if (cancelled == true && mounted) await _changed(context.l10n.deskCancelled);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final dates = ref.watch(dateTextProvider);
    final today = ref.watch(clock.todayProvider);
    final roles = ref.watch(deskRolesProvider);
    final memberships = _memberships;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.card_membership_rounded),
                const SizedBox(width: 10),
                Expanded(child: Text(l10n.deskMembershipTitle(widget.member.name), style: textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 6),
            Text(l10n.deskMembershipBody, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            if (_message case final message?) ...[
              const SizedBox(height: 12),
              Text(message, style: textTheme.titleSmall),
            ],
            const SizedBox(height: 16),
            if (_loadFailure case final failure?)
              LoadFailedCard(failure: failure, onRetry: _load)
            else if (memberships == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.ink)),
              )
            else if (memberships.isEmpty)
              Text(l10n.deskNoRunningMembership, style: textTheme.bodyMedium)
            else
              for (final membership in memberships)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.canvasTop,
                      borderRadius: BorderRadius.circular(AppRadii.control),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${membership.planName} · ${switch (membership.status) {
                              'frozen' => l10n.deskStatusFrozen,
                              'upcoming' => l10n.deskStatusUpcoming,
                              _ => l10n.deskStatusActive,
                            }}',
                            style: textTheme.titleSmall,
                          ),
                          Text(
                            '${dates.date(membership.startsOn)} – ${dates.date(membership.endsOn)}',
                            style: textTheme.bodyMedium,
                          ),
                          Text(
                            l10n.deskFreezeDaysUsed(membership.freezeDaysUsed, membership.freezeDaysAllowed),
                            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                          if (membership.currentOrNextFreeze(today) case final freeze?) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.ac_unit_rounded, size: 18, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    l10n.deskFrozenFrom(dates.date(freeze.startsOn), dates.date(freeze.endsOn)),
                                    style: textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                            if (roles.mayFreeze)
                              TextButton(
                                key: Key('end-freeze-${freeze.id}'),
                                onPressed: _busy ? null : () => _endFreeze(membership, freeze),
                                child: Text(freeze.hasStarted(today) ? l10n.deskEndFreeze : l10n.deskRemoveFreeze),
                              ),
                          ],
                          Wrap(
                            spacing: 8,
                            children: [
                              if (roles.mayFreeze)
                                TextButton.icon(
                                  key: Key('freeze-${membership.id}'),
                                  onPressed: _busy ? null : () => _freeze(membership),
                                  icon: const Icon(Icons.ac_unit_rounded, size: 18),
                                  label: Text(l10n.freezeConfirm),
                                ),
                              if (roles.mayCancel)
                                TextButton.icon(
                                  key: Key('cancel-${membership.id}'),
                                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                                  onPressed: _busy ? null : () => _cancel(membership),
                                  icon: const Icon(Icons.cancel_outlined, size: 18),
                                  label: Text(l10n.deskCancelMembership),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Asks why, and cancels; the API's refusal shows in the dialog.
class _CancelDialog extends ConsumerStatefulWidget {
  const _CancelDialog({required this.membership});

  final DeskMembership membership;

  @override
  ConsumerState<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends ConsumerState<_CancelDialog> {
  final _reason = TextEditingController();
  var _cancelling = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    setState(() {
      _cancelling = true;
      _error = null;
    });
    try {
      await ref.read(deskMembershipsRepositoryProvider).cancel(widget.membership.id, reason: _reason.text);
      navigator.pop(true);
    } on ValidationFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _cancelling = false;
        _error = failure.fieldErrors.values.firstOrNull?.firstOrNull ?? failureMessage(l10n, failure);
      });
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() {
        _cancelling = false;
        _error = failureMessage(l10n, failure);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      icon: const Icon(Icons.cancel_outlined, color: AppColors.danger),
      title: Text(l10n.deskCancelTitle(widget.membership.planName)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.deskCancelBody),
          const SizedBox(height: 16),
          TextField(
            key: const Key('cancel-reason'),
            controller: _reason,
            enabled: !_cancelling,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.deskCancelReason, counterText: '', errorText: _error, errorMaxLines: 3),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _cancelling ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.deskKeepMembership),
        ),
        FilledButton(
          key: const Key('confirm-cancel'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: _cancelling ? null : _cancel,
          child: Text(l10n.deskCancelMembership),
        ),
      ],
    );
  }
}
