import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

/// The dark full-width button for a screen's one main action.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.isLoading = false});

  final String label;
  final VoidCallback? onPressed;

  /// Shows a spinner and ignores taps, without greying the button out.
  final bool isLoading;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed == null ? null : (isLoading ? () {} : onPressed),
    child: isLoading
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
          )
        : Text(label),
  );
}

/// An inline error under a form field.
class FormMessage extends StatelessWidget {
  const FormMessage(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 1),
        child: Icon(Icons.error_outline_rounded, size: 18, color: AppColors.danger),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.danger, fontSize: 13),
        ),
      ),
    ],
  );
}

/// A section title with an optional action on the right, like "See all".
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        ?action,
      ],
    ),
  );
}

/// The top row of a screen: a circle on each side and the title between.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, this.leading, required this.title, this.trailing});

  final Widget? leading;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: 46, child: leading),
      Expanded(
        child: Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      SizedBox(width: 46, child: trailing),
    ],
  );
}
