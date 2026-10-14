import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/brand.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/controls.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/language_menu.dart';
import '../../../l10n/app_localizations.dart';
import '../onboarding_controller.dart';

/// The welcome pages before the first sign-in: a photo per page fading into
/// the page, with chips pinned to it that hint at what the app does.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pages = PageController();
  var _index = 0;

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// The router moves on to sign-in once this is recorded.
  Future<void> _finish() => ref.read(onboardingDoneProvider.notifier).complete();

  void _next() {
    if (_isLast) {
      unawaited(_finish());
    } else {
      unawaited(_pages.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The photos run under the status bar.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: _slides.length,
                    onPageChanged: (index) => setState(() => _index = index),
                    itemBuilder: (context, index) => _SlideView(slide: _slides[index]),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: Column(
                      children: [
                        _Dots(count: _slides.length, index: _index),
                        const SizedBox(height: 24),
                        PrimaryButton(label: _isLast ? l10n.getStarted : l10n.next, onPressed: _next),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    const LanguageMenu(),
                    const Spacer(),
                    if (!_isLast) _SkipButton(label: l10n.skip, onPressed: _finish),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A chip pinned to a point of the photo by a thin line, like a label on a
/// diagram.
final class _Pin {
  const _Pin({required this.at, required this.label, required this.icon, this.line = 44, this.align = 0, this.below = false});

  /// The pinned point, as fractions of the photo's width and height.
  final Offset at;
  final String Function(AppLocalizations l10n) label;
  final IconData icon;
  final double line;

  /// -1: the chip extends right of the line, 0: centred on it, 1: left.
  final double align;

  /// The chip hangs under the point instead of standing above it.
  final bool below;
}

final class _Slide {
  const _Slide({required this.photo, required this.title, required this.body, this.pins = const []});

  final String photo;
  final String Function(AppLocalizations l10n) title;
  final String Function(AppLocalizations l10n) body;
  final List<_Pin> pins;
}

final _slides = [
  _Slide(
    photo: 'assets/photos/onboarding_train.jpg',
    title: (l10n) => l10n.onboardingTrainTitle,
    body: (l10n) => l10n.onboardingTrainBody,
    pins: [
      _Pin(
        at: const Offset(0.52, 0.47),
        label: (l10n) => l10n.onboardingPinDaysLeft,
        icon: Icons.event_available_rounded,
        align: -1,
      ),
    ],
  ),
  _Slide(
    photo: 'assets/photos/onboarding_check_in.jpg',
    title: (l10n) => l10n.onboardingCheckInTitle,
    body: (l10n) => l10n.onboardingCheckInBody,
    pins: [
      _Pin(
        at: const Offset(0.5, 0.4),
        label: (l10n) => l10n.onboardingPinCheckedIn,
        icon: Icons.check_circle_rounded,
        line: 52,
      ),
    ],
  ),
  _Slide(
    photo: 'assets/photos/onboarding_renew.jpg',
    title: (l10n) => l10n.onboardingRenewTitle,
    body: (l10n) => l10n.onboardingRenewBody,
    pins: [
      _Pin(
        at: const Offset(0.16, 0.52),
        label: (l10n) => l10n.onboardingPinPaid,
        icon: Icons.verified_rounded,
        align: -1,
        line: 34,
        below: true,
      ),
    ],
  ),
];

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Expanded(child: _PinnedPhoto(slide: slide)),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
          child: Column(
            children: [
              Text(
                slide.title(l10n),
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(fontSize: 30, height: 1.12, letterSpacing: -0.8),
              ),
              const SizedBox(height: 12),
              Text(
                slide.body(l10n),
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PinnedPhoto extends StatelessWidget {
  const _PinnedPhoto({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(slide.photo, fit: BoxFit.cover, alignment: Alignment.topCenter),
            // Keeps the status bar and the buttons over the photo readable.
            const Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x59000000), Color(0x00000000)],
                    ),
                  ),
                ),
              ),
            ),
            // Fades the photo into the page under the title.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.62, 1],
                  colors: [Color(0x00F2EEE8), AppColors.canvas],
                ),
              ),
            ),
            for (final pin in slide.pins) ..._pinned(pin, Offset(pin.at.dx * width, pin.at.dy * height), l10n),
          ],
        );
      },
    );
  }

  List<Widget> _pinned(_Pin pin, Offset at, AppLocalizations l10n) {
    final chipTop = pin.below ? at.dy + pin.line : at.dy - pin.line;
    return [
      Positioned(
        left: at.dx - 0.75,
        top: pin.below ? at.dy : at.dy - pin.line,
        width: 1.5,
        height: pin.line,
        child: ColoredBox(color: Colors.white.withValues(alpha: 0.9)),
      ),
      Positioned(left: at.dx - 7, top: at.dy - 7, child: const _PinDot()),
      Positioned(
        left: at.dx,
        top: chipTop,
        child: FractionalTranslation(
          translation: Offset(-(pin.align + 1) / 2, pin.below ? 0 : -1),
          child: _PinChip(label: pin.label(l10n), icon: pin.icon),
        ),
      ),
    ];
  }
}

class _PinDot extends StatelessWidget {
  const _PinDot();

  @override
  Widget build(BuildContext context) => Container(
    width: 14,
    height: 14,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.4)),
    alignment: Alignment.center,
    child: const SizedBox.square(
      dimension: 8,
      child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
    ),
  );
}

class _PinChip extends StatelessWidget {
  const _PinChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(99),
      boxShadow: AppShadows.raised,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: context.brand.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < count; i++)
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i == index ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: i == index ? AppColors.ink : const Color(0xFFCFC8BF),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
    ],
  );
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: 0.92),
    shape: const StadiumBorder(),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Text(label, style: Theme.of(context).textTheme.titleSmall),
      ),
    ),
  );
}
