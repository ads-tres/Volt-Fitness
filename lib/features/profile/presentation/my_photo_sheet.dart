import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/tokens.dart';
import '../../../core/errors/failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/localization/l10n.dart';
import '../data/my_photo.dart';

/// Take a photo, choose one, or remove the one there. The photo is kept at
/// every gym where the member's phone is registered, and the desk sees it
/// at the door.
Future<void> showMyPhotoSheet(BuildContext context, {required bool hasPhoto}) {
  // A message still showing would cover the sheet's last choice.
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (context) => _MyPhotoSheet(hasPhoto: hasPhoto),
  );
}

class _MyPhotoSheet extends ConsumerWidget {
  const _MyPhotoSheet({required this.hasPhoto});

  final bool hasPhoto;

  /// Closes the sheet, then runs [action] with the app's providers, which
  /// outlive the sheet.
  Future<void> _run(BuildContext context, Future<void> Function(MyPhotoRepository photos) action, String done) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final container = ProviderScope.containerOf(context, listen: false);
    Navigator.of(context).pop();
    try {
      await action(container.read(myPhotoRepositoryProvider));
      container.invalidate(myPhotoUrlProvider);
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on ValidationFailure catch (failure) {
      messenger.showSnackBar(
        SnackBar(content: Text(failure.fieldErrors['photo']?.firstOrNull ?? failure.message ?? failureMessage(l10n, failure))),
      );
    } on Failure catch (failure) {
      messenger.showSnackBar(SnackBar(content: Text(failureMessage(l10n, failure))));
    }
  }

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref, {required bool camera}) async {
    final picker = ref.read(photoPickerProvider);
    final photo = await (camera ? picker.take() : picker.choose());
    if (photo == null || !context.mounted) return;
    await _run(context, (photos) => photos.upload(photo), context.l10n.photoSaved);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
            child: Text(l10n.photoTitle, style: textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(l10n.photoBody, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded),
            title: Text(l10n.photoTake),
            onTap: () => unawaited(_pickAndUpload(context, ref, camera: true)),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: Text(l10n.photoChoose),
            onTap: () => unawaited(_pickAndUpload(context, ref, camera: false)),
          ),
          if (hasPhoto)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              title: Text(l10n.photoRemove, style: const TextStyle(color: AppColors.danger)),
              onTap: () => unawaited(_run(context, (photos) => photos.remove(), l10n.photoRemoved)),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
