import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/photos/photo_picker.dart';
import '../../plans/presentation/sell_plan_sheet.dart';
import '../data/member_photo_repository.dart';
import '../data/member_search.dart';

enum _NextStep { photo, plan, done }

/// After [member] is added: their photo, then a plan, which goes on to the
/// payment. Each step can be skipped; [onChanged] refreshes search.
Future<void> welcomeNewMember(BuildContext context, DeskMember member, {required VoidCallback onChanged}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final messenger = ScaffoldMessenger.of(context)..removeCurrentSnackBar();
  var hasPhoto = false;
  while (true) {
    if (!context.mounted) return;
    final step = await showModalBottomSheet<_NextStep>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (context) => _WelcomeSheet(member: member, hasPhoto: hasPhoto),
    );
    if (!context.mounted) return;
    switch (step) {
      case _NextStep.photo:
        final l10n = context.l10n;
        final photo = await container.read(photoPickerProvider).take();
        if (photo == null) continue;
        try {
          await container.read(memberPhotoRepositoryProvider).upload(member.id, photo);
          hasPhoto = true;
          onChanged();
        } on ValidationFailure catch (failure) {
          messenger.showSnackBar(
            SnackBar(content: Text(failure.fieldErrors['photo']?.firstOrNull ?? failureMessage(l10n, failure))),
          );
        } on Failure catch (failure) {
          messenger.showSnackBar(SnackBar(content: Text(failureMessage(l10n, failure))));
        }
      case _NextStep.plan:
        await showSellPlanSheet(context, (id: member.id, name: member.name, phone: member.phone), onSold: onChanged);
        return;
      case _NextStep.done || null:
        return;
    }
  }
}

class _WelcomeSheet extends StatelessWidget {
  const _WelcomeSheet({required this.member, required this.hasPhoto});

  final DeskMember member;
  final bool hasPhoto;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.celebration_rounded),
                const SizedBox(width: 10),
                Expanded(child: Text(l10n.newMemberAdded(member.name), style: textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 6),
            Text(l10n.welcomeBody, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(hasPhoto ? Icons.check_circle_rounded : Icons.photo_camera_rounded),
              title: Text(hasPhoto ? l10n.welcomePhotoTaken : l10n.photoTake),
              subtitle: hasPhoto ? null : Text(l10n.welcomePhotoHelp),
              enabled: !hasPhoto,
              onTap: () => Navigator.of(context).pop(_NextStep.photo),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.autorenew_rounded),
              title: Text(l10n.deskSellPlan),
              subtitle: Text(l10n.welcomePlanHelp),
              onTap: () => Navigator.of(context).pop(_NextStep.plan),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.of(context).pop(_NextStep.done), child: Text(l10n.welcomeLater)),
          ],
        ),
      ),
    );
  }
}
