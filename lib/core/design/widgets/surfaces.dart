import 'package:material_ui/material_ui.dart';

import '../brand.dart';
import '../tokens.dart';

/// The page backdrop: a wash of the brand colour at the top that fades into
/// the page, with two soft glows.
class SoftBackground extends StatelessWidget {
  const SoftBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.45],
          colors: [brand.mist, AppColors.canvas],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -140, right: -90, child: _Glow(size: 320, color: brand.primary.withValues(alpha: 0.12))),
          Positioned(top: 120, left: -120, child: _Glow(size: 260, color: Colors.white.withValues(alpha: 0.85))),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    ),
  );
}

/// A white card with a soft shadow, tappable when [onTap] is set.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(AppRadii.card));
    return DecoratedBox(
      decoration: const BoxDecoration(borderRadius: radius, boxShadow: AppShadows.card),
      child: Material(
        color: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: AppColors.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A rounded square in the brand gradient holding a white icon.
class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, this.size = 52});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final (light, deep) = brand.gradient;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [light, deep]),
        boxShadow: [BoxShadow(color: deep.withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Icon(icon, color: brand.onPrimary, size: size * 0.48),
    );
  }
}

/// A white circle for header actions such as back or language.
class CircleButton extends StatelessWidget {
  const CircleButton({super.key, required this.tooltip, required this.onPressed, required this.child, this.size = 46});

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: DecoratedBox(
      decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: AppShadows.card),
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(dimension: size, child: Center(child: child)),
        ),
      ),
    ),
  );
}

/// A gym's logo in a white circle: Volt's own mark before sign-in, and the
/// gym's initials on its colour when it has no logo.
class GymAvatar extends StatelessWidget {
  const GymAvatar({super.key, required this.brand, this.size = 46});

  final Brand brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    final logoUrl = brand.logoUrl;
    final Widget content;
    if (brand.isPlatform) {
      content = Padding(
        padding: EdgeInsets.all(size * 0.2),
        child: Image.asset('assets/brand/volt_mark_red.png', fit: BoxFit.contain),
      );
    } else if (logoUrl != null) {
      content = Image.network(
        logoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _Initials(brand: brand, size: size),
      );
    } else {
      content = _Initials(brand: brand, size: size);
    }
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, boxShadow: AppShadows.card),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.brand, required this.size});

  final Brand brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = brand.name
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word.characters.first.toUpperCase())
        .join();
    final (light, deep) = brand.gradient;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [light, deep]),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(color: brand.onPrimary, fontSize: size * 0.34, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// The dark card for the screen's main action, with a second card peeking
/// out underneath.
class DarkActionCard extends StatelessWidget {
  const DarkActionCard({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const radius = BorderRadius.all(Radius.circular(AppRadii.card - 2));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 16,
            right: 16,
            bottom: -10,
            height: 40,
            child: DecoratedBox(
              decoration: BoxDecoration(color: AppColors.ink.withValues(alpha: 0.08), borderRadius: radius),
            ),
          ),
          Material(
            color: AppColors.ink,
            shape: const RoundedRectangleBorder(borderRadius: radius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconTile(icon: icon, size: 48),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: textTheme.titleMedium?.copyWith(color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(subtitle, style: textTheme.bodySmall?.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
