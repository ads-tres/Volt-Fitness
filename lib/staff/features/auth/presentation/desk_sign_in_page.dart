import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/widgets/controls.dart';
import '../../../../core/design/widgets/surfaces.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/utils/ethiopian_phone.dart';
import '../../../core/desk_session.dart';
import '../data/desk_auth_repository.dart';

/// Staff sign in with the phone and password they set from the gym's SMS.
class DeskSignInPage extends ConsumerStatefulWidget {
  const DeskSignInPage({super.key});

  @override
  ConsumerState<DeskSignInPage> createState() => _DeskSignInPageState();
}

class _DeskSignInPageState extends ConsumerState<DeskSignInPage> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  var _busy = false;
  String? _problem;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final l10n = context.l10n;
    FocusScope.of(context).unfocus();
    final phone = EthiopianPhone.normalize(_phone.text);
    if (phone == null) {
      setState(() => _problem = l10n.phoneInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      final signedIn = await ref.read(deskAuthRepositoryProvider).signIn(phone: phone, password: _password.text);
      if (signedIn.gyms.isEmpty) {
        if (mounted) setState(() => _problem = l10n.deskNoGym);
        return;
      }
      await ref.read(deskSessionProvider.notifier).signIn(token: signedIn.token, name: signedIn.name, gyms: signedIn.gyms);
    } on Failure catch (failure) {
      if (mounted) {
        setState(
          () => _problem = switch (failure) {
            // The API's own words for a wrong phone or password.
            ValidationFailure(:final fieldErrors) when fieldErrors.isNotEmpty => fieldErrors.values.first.first,
            _ => failureMessage(l10n, failure),
          },
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SoftBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            children: [
              Text(l10n.deskTitle, style: textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(l10n.deskSignInTitle, style: textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(l10n.deskSignInBody, style: textTheme.bodyMedium),
              const SizedBox(height: 28),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration: InputDecoration(labelText: l10n.phoneLabel),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('password'),
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(labelText: l10n.deskPassword),
                onSubmitted: (_) => _signIn(),
              ),
              if (_problem case final problem?) ...[
                const SizedBox(height: 12),
                Text(problem, style: textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              PrimaryButton(label: l10n.deskSignIn, isLoading: _busy, onPressed: _signIn),
            ],
          ),
        ),
      ),
    );
  }
}
