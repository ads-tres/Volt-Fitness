import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/photos/photo_picker.dart';
import '../data/member_photo_repository.dart';
import '../data/member_search.dart';

/// Take a member's photo at the desk, or remove the one there. The photo
/// is kept at every gym where their phone is registered.
Future<void> showMemberPhotoSheet(BuildContext context, DeskMember member, {required VoidCallback onChanged}) {
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (context) => _MemberPhotoSheet(member: member, onChanged: onChanged),
  );
}

class _MemberPhotoSheet extends ConsumerWidget {
  const _MemberPhotoSheet({required this.member, required this.onChanged});

  final DeskMember member;
  final VoidCallback onChanged;

  /// Closes the sheet, then runs [action] with the app's providers, which
  /// outlive the sheet.
  Future<void> _run(BuildContext context, Future<void> Function(MemberPhotoRepository photos) action, String done) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final container = ProviderScope.containerOf(context, listen: false);
    Navigator.of(context).pop();
    try {
      await action(container.read(memberPhotoRepositoryProvider));
      onChanged();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on ValidationFailure catch (failure) {
      messenger.showSnackBar(
        SnackBar(content: Text(failure.fieldErrors['photo']?.firstOrNull ?? failure.message ?? failureMessage(l10n, failure))),
      );
    } on Failure catch (failure) {
      messenger.showSnackBar(SnackBar(content: Text(failureMessage(l10n, failure))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(member.name, style: Theme.of(context).textTheme.titleLarge),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded),
            title: Text(l10n.photoTake),
            onTap: () async {
              final photo = await ref.read(photoPickerProvider).take();
              if (photo == null || !context.mounted) return;
              unawaited(_run(context, (photos) => photos.upload(member.id, photo), l10n.deskPhotoSaved(member.name)));
            },
          ),
          if (member.photoUrl != null)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              title: Text(l10n.photoRemove, style: const TextStyle(color: AppColors.danger)),
              onTap: () => unawaited(_run(context, (photos) => photos.remove(member.id), l10n.deskPhotoRemoved(member.name))),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
