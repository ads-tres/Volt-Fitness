import 'package:material_ui/material_ui.dart';

/// A member's photo in a circle, from its short-lived link, or [fallback]
/// (their initials) when there is none or it doesn't load. A `data:` link,
/// as the dev fakes give, is shown straight from its bytes.
class MemberPhoto extends StatelessWidget {
  const MemberPhoto({super.key, required this.url, required this.size, required this.fallback});

  final String? url;
  final double size;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final link = url;
    if (link == null) return SizedBox.square(dimension: size, child: fallback);
    final image = link.startsWith('data:')
        ? Image.memory(
            UriData.parse(link).contentAsBytes(),
            key: const Key('member-photo'),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => fallback,
          )
        : Image.network(
            link,
            key: const Key('member-photo'),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => fallback,
          );
    return ClipOval(child: SizedBox.square(dimension: size, child: image));
  }
}

/// A person's initials in a soft circle, where their photo would be.
class InitialsCircle extends StatelessWidget {
  const InitialsCircle({super.key, required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word.characters.first.toUpperCase())
        .join();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, shape: BoxShape.circle),
      child: Text(initials, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
