import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/brand.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/controls.dart';
import '../../../core/design/widgets/surfaces.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/language_menu.dart';
import '../../../core/utils/ethiopian_phone.dart';
import 'sign_in_controller.dart';
import 'sign_in_messages.dart';

const _codeLength = 6;

/// Step two of sign-in: the SMS code. A full code verifies by itself; the
/// router moves on once the session exists.
class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({super.key});

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _verify() {
    if (_code.text.length == _codeLength) {
      unawaited(ref.read(signInControllerProvider.notifier).verify(_code.text));
    }
  }

  Future<void> _resend() async {
    _code.clear();
    await ref.read(signInControllerProvider.notifier).resendCode();
    if (!mounted || ref.read(signInControllerProvider).problem != null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.codeResent)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(signInControllerProvider);
    final problem = state.problem;

    // A rejected code is cleared so the member can type the next one.
    ref.listen(signInControllerProvider.select((state) => state.problem), (_, problem) {
      if (problem != null) _code.clear();
    });

    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  HeaderButton(
                    tooltip: l10n.back,
                    onPressed: () => context.pop(),
                    child: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                  ),
                  const LanguageMenu(),
                ],
              ),
              const SizedBox(height: 40),
              const Align(alignment: Alignment.centerLeft, child: IconTile(icon: Icons.sms_rounded, size: 56)),
              const SizedBox(height: 24),
              Text(l10n.otpTitle, style: textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                l10n.otpSubtitle(EthiopianPhone.format(state.phone ?? '')),
                style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              OtpInput(
                controller: _code,
                hasError: problem != null,
                enabled: !state.isBusy,
                onChanged: (_) => ref.read(signInControllerProvider.notifier).clearProblem(),
                onCompleted: _verify,
              ),
              if (problem != null) ...[
                const SizedBox(height: 12),
                FormMessage(signInProblemText(l10n, problem)),
              ],
              const SizedBox(height: 24),
              ListenableBuilder(
                listenable: _code,
                builder: (context, _) => PrimaryButton(
                  label: l10n.verifyButton,
                  isLoading: state.isBusy,
                  onPressed: _code.text.length == _codeLength ? _verify : null,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: ResendCountdown(
                  key: ValueKey(state.codesSent),
                  wait: state.resendIn,
                  onResend: state.isBusy ? null : _resend,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Six boxes over one hidden text field, so paste and SMS autofill work.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.onChanged,
    this.hasError = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onCompleted;
  final ValueChanged<String>? onChanged;
  final bool hasError;
  final bool enabled;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return GestureDetector(
      onTap: _focus.requestFocus,
      child: Stack(
        children: [
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              final code = widget.controller.text;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < _codeLength; i++)
                    _CodeBox(
                      digit: i < code.length ? code[i] : null,
                      borderColor: widget.hasError
                          ? AppColors.danger
                          : (_focus.hasFocus && i == code.length.clamp(0, _codeLength - 1)
                                ? brand.primary
                                : AppColors.line),
                    ),
                ],
              );
            },
          ),
          // Invisible, but it owns the keyboard, paste and autofill.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                enabled: widget.enabled,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_codeLength),
                ],
                showCursor: false,
                enableInteractiveSelection: false,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  counterText: '',
                ),
                onChanged: (code) {
                  widget.onChanged?.call(code);
                  if (code.length == _codeLength) widget.onCompleted();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.digit, required this.borderColor});

  final String? digit;
  final Color borderColor;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    width: 48,
    height: 58,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.tile),
      border: Border.all(color: borderColor, width: borderColor == AppColors.line ? 1 : 1.6),
      boxShadow: AppShadows.card,
    ),
    alignment: Alignment.center,
    child: Text(digit ?? '', style: Theme.of(context).textTheme.headlineSmall),
  );
}

/// "Resend code in 0:42", then a resend button once the wait is over.
class ResendCountdown extends StatefulWidget {
  const ResendCountdown({super.key, required this.wait, required this.onResend});

  final Duration wait;
  final VoidCallback? onResend;

  @override
  State<ResendCountdown> createState() => _ResendCountdownState();
}

class _ResendCountdownState extends State<ResendCountdown> {
  late int _secondsLeft = widget.wait.inSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (_secondsLeft > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _secondsLeft--);
        if (_secondsLeft <= 0) timer.cancel();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_secondsLeft > 0) {
      final time = '${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(l10n.resendIn(time), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
      );
    }
    return TextButton(onPressed: widget.onResend, child: Text(l10n.resendCode));
  }
}
