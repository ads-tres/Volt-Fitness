import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../app/routes.dart';
import '../../../core/config/env.dart';
import '../../../core/design/brand.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/feedback.dart';
import '../../../core/design/widgets/surfaces.dart';
import '../../../core/errors/failure.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/locale_controller.dart';
import '../data/billing_repository.dart';
import '../domain/billing.dart';
import 'fake_chapa_checkout.dart';

/// Chapa's checkout, full screen. When Chapa sends the member back, or they
/// leave, the result screen asks the API what really happened.
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key, required this.attemptId, this.attempt});

  final String attemptId;

  /// Passed along when the attempt was just created, to skip a reload.
  final PaymentAttempt? attempt;

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  late Future<PaymentAttempt> _attempt = widget.attempt != null
      ? Future.value(widget.attempt)
      : ref.read(billingRepositoryProvider).attempt(widget.attemptId);
  var _finished = false;

  void _returned() {
    if (_finished) return;
    _finished = true;
    context.pushReplacement(AppRoutes.paymentResult(widget.attemptId));
  }

  Future<void> _leave() async {
    final l10n = context.l10n;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.leaveCheckoutTitle),
        content: Text(l10n.leaveCheckoutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.ink),
            child: Text(l10n.stay),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.leave),
          ),
        ],
      ),
    );
    if (leave == true && mounted && !_finished) {
      _finished = true;
      context.pushReplacement(AppRoutes.paymentResult(widget.attemptId, left: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final usesFake = ref.watch(envProvider).usesFakeBackend;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: FutureBuilder<PaymentAttempt>(
            future: _attempt,
            builder: (context, snapshot) {
              final attempt = snapshot.data;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        HeaderButton(
                          tooltip: l10n.leave,
                          onPressed: _leave,
                          child: const Icon(Icons.close_rounded, color: AppColors.ink),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.checkoutTitle, style: textTheme.titleMedium),
                              if (attempt != null)
                                Text(attempt.amount.format(ref.watch(languageCodeProvider)), style: textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Icon(Icons.lock_rounded, size: 18, color: context.brand.primary),
                      ],
                    ),
                  ),
                  Expanded(
                    child: switch (snapshot) {
                      AsyncSnapshot(hasData: true) when usesFake => FakeChapaCheckout(
                        attempt: attempt!,
                        onPaid: _returned,
                        onCancel: _leave,
                      ),
                      AsyncSnapshot(hasData: true) => _ChapaWebView(attempt: attempt!, onReturned: _returned),
                      AsyncSnapshot(:final error?) => Padding(
                        padding: const EdgeInsets.all(20),
                        child: LoadFailedCard(
                          failure: error is Failure ? error : const UnexpectedFailure(),
                          onRetry: () => setState(() {
                            _attempt = ref.read(billingRepositoryProvider).attempt(widget.attemptId);
                          }),
                        ),
                      ),
                      _ => const Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Chapa's hosted checkout in a web view. Payment apps (telebirr, CBE Birr)
/// open outside it; reaching the return URL hands back to the app.
class _ChapaWebView extends StatefulWidget {
  const _ChapaWebView({required this.attempt, required this.onReturned});

  final PaymentAttempt attempt;
  final VoidCallback onReturned;

  @override
  State<_ChapaWebView> createState() => _ChapaWebViewState();
}

class _ChapaWebViewState extends State<_ChapaWebView> {
  late final WebViewController _controller;
  var _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _decide,
          onUrlChange: (change) {
            if (_isReturn(change.url)) widget.onReturned();
          },
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.attempt.checkoutUrl));
  }

  bool _isReturn(String? url) => url != null && url.startsWith(widget.attempt.returnUrl);

  NavigationDecision _decide(NavigationRequest request) {
    if (_isReturn(request.url)) {
      widget.onReturned();
      return NavigationDecision.prevent;
    }
    final uri = Uri.tryParse(request.url);
    if (uri == null || uri.scheme == 'https' || uri.scheme == 'http' || uri.scheme == 'about') {
      return NavigationDecision.navigate;
    }
    unawaited(_openOutside(uri));
    return NavigationDecision.prevent;
  }

  /// A payment app's link. Android `intent:` links carry a web fallback for
  /// when the app isn't installed.
  Future<void> _openOutside(Uri uri) async {
    if (await canLaunchUrl(uri) && await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    final fallback = RegExp(r'S\.browser_fallback_url=([^;]+)').firstMatch(uri.toString())?.group(1);
    if (fallback != null) await _controller.loadRequest(Uri.parse(Uri.decodeComponent(fallback)));
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: WebViewWidget(controller: _controller)),
      if (_progress < 100)
        LinearProgressIndicator(
          value: _progress / 100,
          minHeight: 3,
          color: context.brand.primary,
          backgroundColor: Colors.transparent,
        ),
    ],
  );
}
