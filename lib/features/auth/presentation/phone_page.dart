import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/config/env.dart';
import '../../../core/design/tokens.dart';
import '../../../core/design/widgets/controls.dart';
import '../../../core/design/widgets/surfaces.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/localization/language_menu.dart';
import '../../../core/network/fake_backend.dart';
import 'sign_in_controller.dart';
import 'sign_in_messages.dart';

/// Step one of sign-in: the member's phone number. Always drawn in Volt's
/// brand, since no gym is known yet.
class PhonePage extends ConsumerStatefulWidget {
  const PhonePage({super.key});

  @override
  ConsumerState<PhonePage> createState() => _PhonePageState();
}

class _PhonePageState extends ConsumerState<PhonePage> {
  final _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    final sent = await ref.read(signInControllerProvider.notifier).requestCode(_phone.text);
    if (sent && mounted) await context.push(AppRoutes.verify);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(signInControllerProvider);
    final problem = state.problem;

    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      const Align(alignment: Alignment.centerRight, child: LanguageMenu()),
                      const Spacer(flex: 2),
                      Center(child: Image.asset('assets/brand/volt_wordmark.png', height: 64)),
                      const SizedBox(height: 40),
                      Text(l10n.welcomeTitle, style: textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                        l10n.welcomeSubtitle,
                        style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.telephoneNumberNational],
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                          LengthLimitingTextInputFormatter(16),
                        ],
                        style: textTheme.titleMedium?.copyWith(letterSpacing: 0.6),
                        onChanged: (_) => ref.read(signInControllerProvider.notifier).clearProblem(),
                        onSubmitted: (_) => _continue(),
                        decoration: InputDecoration(
                          labelText: l10n.phoneLabel,
                          hintText: '0911 23 45 67',
                          prefixIcon: const Icon(Icons.phone_iphone_rounded),
                          errorText: problem == null ? null : '',
                          errorStyle: const TextStyle(height: 0, fontSize: 0),
                        ),
                      ),
                      if (problem != null) ...[
                        const SizedBox(height: 10),
                        FormMessage(signInProblemText(l10n, problem)),
                      ],
                      const SizedBox(height: 20),
                      PrimaryButton(label: l10n.continueButton, isLoading: state.isBusy, onPressed: _continue),
                      const Spacer(flex: 3),
                      Text(l10n.smsNotice, textAlign: TextAlign.center, style: textTheme.bodySmall),
                      if (ref.watch(envProvider).usesFakeBackend) ...[
                        const SizedBox(height: 10),
                        Center(child: _TestModeBadge(l10n.testModeNotice(FakeBackend.validCode))),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TestModeBadge extends StatelessWidget {
  const _TestModeBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: AppColors.line),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
    ),
  );
}
