import 'package:material_ui/material_ui.dart';

import '../../errors/failure.dart';
import '../../errors/failure_messages.dart';
import '../../localization/l10n.dart';
import '../tokens.dart';
import 'surfaces.dart';

/// Shown when a load failed and there is nothing cached to show instead.
class LoadFailedCard extends StatelessWidget {
  const LoadFailedCard({super.key, required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        children: [
          Text(l10n.loadFailed, textAlign: TextAlign.center, style: textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            failureMessage(l10n, failure),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}

/// A slim note that the screen shows the last copy because a refresh failed.
class OfflineNotice extends StatelessWidget {
  const OfflineNotice({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: const Color(0xFFE9E4DD), borderRadius: BorderRadius.circular(99)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.offlineNotice,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A photo card that explains a state with nothing else to show, such as no
/// plan or a QR that needs setting up, with an optional action under it.
class PhotoMessageCard extends StatelessWidget {
  const PhotoMessageCard({super.key, required this.photo, required this.title, required this.body, this.action});

  /// An asset path under `assets/photos/`.
  final String photo;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Image.asset(photo, height: 200, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, textAlign: TextAlign.center, style: textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
                if (action case final action?) ...[const SizedBox(height: 18), action],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
