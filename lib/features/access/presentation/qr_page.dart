import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../../../core/auth/session.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/design/brand.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/controls.dart';
import '../../../core/design/widgets/feedback.dart';
import '../../../core/design/widgets/surfaces.dart';
import '../../../core/errors/failure.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/language_menu.dart';
import '../../../core/time/clock.dart';
import '../data/access_card_controller.dart';
import '../domain/gq1.dart';
import 'qr_code_view.dart';

/// The member's check-in QR. A new code appears every 30 seconds, and the
/// screen turns its brightness up while the QR is in view.
class QrPage extends ConsumerStatefulWidget {
  const QrPage({super.key});

  @override
  ConsumerState<QrPage> createState() => _QrPageState();
}

class _QrPageState extends ConsumerState<QrPage> with WidgetsBindingObserver {
  Timer? _ticker;
  var _inView = false;
  var _tabVisible = false;
  var _appResumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The tab stays alive behind the others; tickers are muted while hidden.
    _tabVisible = TickerMode.valuesOf(context).enabled;
    _setInView(_tabVisible && _appResumed);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
    _setInView(_tabVisible && _appResumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setInView(false);
    super.dispose();
  }

  void _setInView(bool inView) {
    if (inView == _inView) return;
    _inView = inView;
    _ticker?.cancel();
    _ticker = inView ? Timer.periodic(const Duration(seconds: 1), (_) => setState(() {})) : null;
    unawaited(_brighten(inView));
  }

  /// Scanners read a bright screen far more easily. This changes only this
  /// app's window, never the phone's own brightness setting.
  Future<void> _brighten(bool on) async {
    try {
      if (on) {
        await ScreenBrightness.instance.setApplicationScreenBrightness(1);
      } else {
        await ScreenBrightness.instance.resetApplicationScreenBrightness();
      }
    } on Object {
      // Not available on this device; the QR still works.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final card = ref.watch(accessCardProvider);
    final controller = ref.read(accessCardProvider.notifier);

    return SoftBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            ScreenHeader(title: l10n.navQr, trailing: const LanguageMenu()),
            const SizedBox(height: 24),
            switch (card) {
              AsyncData(value: ActiveCard(:final credential)) => _QrCard(
                payload: credential.payloadAt(ref.read(serverClockProvider).now()),
                secondsLeft: Gq1.secondsLeft(ref.read(serverClockProvider).now()),
              ),
              AsyncData(value: RevokedCard(reason: 'replaced')) => PhotoMessageCard(
                photo: 'assets/photos/onboarding_check_in.jpg',
                title: l10n.qrReplacedTitle,
                body: l10n.qrReplacedBody,
                action: PrimaryButton(
                  label: l10n.qrUseThisPhone,
                  isLoading: card.isLoading,
                  onPressed: controller.useThisPhone,
                ),
              ),
              AsyncData(value: RevokedCard()) => PhotoMessageCard(
                photo: 'assets/photos/onboarding_check_in.jpg',
                title: l10n.qrRevokedTitle,
                body: l10n.qrRevokedBody,
              ),
              AsyncError(:final error) => PhotoMessageCard(
                photo: 'assets/photos/onboarding_check_in.jpg',
                title: error is NetworkFailure ? l10n.qrSetupTitle : l10n.loadFailed,
                body: l10n.qrSetupBody,
                action: PrimaryButton(label: l10n.retry, onPressed: () => ref.invalidate(accessCardProvider)),
              ),
              _ => const Padding(
                padding: EdgeInsets.all(64),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _QrCard extends ConsumerWidget {
  const _QrCard({required this.payload, required this.secondsLeft});

  final String payload;
  final int secondsLeft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final brand = context.brand;
    final name = switch (ref.watch(sessionControllerProvider)) {
      SignedIn(:final profile) => profile.user.name,
      SignedOut() => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          child: Column(
            children: [
              Row(
                children: [
                  GymAvatar(brand: brand, size: 42, round: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(brand.name, style: textTheme.titleMedium),
                        if (name != null) Text(l10n.qrMember(name), style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) => QrCodeView(
                  data: payload,
                  size: constraints.maxWidth.clamp(0, 280).toDouble(),
                  semanticLabel: l10n.qrImageLabel,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: secondsLeft / Gq1.stepSeconds,
                  minHeight: 6,
                  color: brand.primary,
                  backgroundColor: const Color(0xFFE9E4DD),
                ),
              ),
              const SizedBox(height: 10),
              Text(l10n.qrNewCodeIn(secondsLeft), style: textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.qrHint,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 16, color: brand.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(l10n.qrWorksOffline, style: textTheme.labelLarge?.copyWith(color: brand.primary)),
            ),
          ],
        ),
      ],
    );
  }
}
