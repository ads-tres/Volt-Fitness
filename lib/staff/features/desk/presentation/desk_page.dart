import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/feedback.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/utils/ethiopian_phone.dart';
import '../../scan/data/check_in_repository.dart';
import '../../scan/presentation/check_in_result.dart';
import '../../scan/presentation/desk_app_bar.dart';
import '../../scan/presentation/scan_page.dart';
import '../data/member_search.dart';

/// Checking in a member without their phone: find them by name or phone,
/// then tap to check them in at the desk's branch. The same rules apply as
/// at the scanner, and the same answer fills the screen.
class DeskPage extends ConsumerStatefulWidget {
  const DeskPage({super.key});

  @override
  ConsumerState<DeskPage> createState() => _DeskPageState();
}

class _DeskPageState extends ConsumerState<DeskPage> {
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
      if (!mounted) return;
      setState(() => _checkingIn = null);
      final navigator = Navigator.of(context);
      final hide = Timer(ScanPage.resultShownFor, () {
        if (navigator.canPop()) navigator.pop();
      });
      await showGeneralDialog<void>(
        context: context,
        pageBuilder: (context, _, _) => CheckInResultView(checkIn: checkIn, onDone: () => Navigator.of(context).pop()),
      );
      hide.cancel();
    } on Failure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failureMessage(context.l10n, failure))));
      }
    } finally {
      if (mounted) setState(() => _checkingIn = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final languageCode = ref.watch(languageCodeProvider);
    final results = ref.watch(memberSearchProvider(_typed));
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
          const SizedBox(height: 16),
          switch (results) {
            AsyncData(value: []) when _typed.trim().length >= 2 => Text(l10n.deskNoMembersFound, style: textTheme.bodyMedium),
            AsyncData(value: []) => Text(l10n.deskSearchHint, style: textTheme.bodyMedium),
            AsyncData(:final value) => Column(
              children: [
                for (final member in value)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(member.name),
                    subtitle: Text(
                      [
                        EthiopianPhone.format(member.phone),
                        ?member.planName,
                        if (member.balanceDue case final owed? when owed.amountMinor > 0) l10n.deskOwes(owed.format(languageCode)),
                      ].join(' · '),
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
