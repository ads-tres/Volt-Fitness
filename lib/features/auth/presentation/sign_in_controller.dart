import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/ethiopian_phone.dart';
import '../data/auth_repository.dart';

/// What went wrong in the sign-in flow, for the screen to explain.
sealed class SignInProblem {
  const SignInProblem();
}

final class InvalidPhone extends SignInProblem {
  const InvalidPhone();
}

final class RequestFailed extends SignInProblem {
  const RequestFailed(this.failure);

  final Failure failure;
}

final class SignInState {
  const SignInState({this.phone, this.codesSent = 0, this.resendIn = Duration.zero, this.isBusy = false, this.problem});

  /// The number a code went to, in E.164.
  final String? phone;

  /// Goes up with every code sent, so the resend countdown restarts.
  final int codesSent;
  final Duration resendIn;
  final bool isBusy;
  final SignInProblem? problem;

  SignInState copyWith({bool? isBusy, SignInProblem? problem}) => SignInState(
    phone: phone,
    codesSent: codesSent,
    resendIn: resendIn,
    isBusy: isBusy ?? this.isBusy,
    problem: problem,
  );
}

/// Phone number, then SMS code, then a session. A successful [verify]
/// signs in, and the router takes the member on from there.
final class SignInController extends Notifier<SignInState> {
  @override
  SignInState build() => const SignInState();

  /// Sends a code to [input]. True when it went out and the code screen
  /// should open.
  Future<bool> requestCode(String input) async {
    final phone = EthiopianPhone.normalize(input);
    if (phone == null) {
      state = state.copyWith(problem: const InvalidPhone());
      return false;
    }
    return _send(phone);
  }

  Future<void> resendCode() async {
    if (state.phone case final phone?) await _send(phone);
  }

  Future<void> verify(String code) async {
    final phone = state.phone;
    if (phone == null || state.isBusy) return;
    state = state.copyWith(isBusy: true);
    try {
      final result = await ref.read(authRepositoryProvider).verifyCode(phone: phone, code: code);
      await ref.read(sessionControllerProvider.notifier).signIn(token: result.token, profile: result.profile);
      state = const SignInState();
    } on Failure catch (failure) {
      state = state.copyWith(isBusy: false, problem: RequestFailed(failure));
    }
  }

  void clearProblem() {
    if (state.problem != null) state = state.copyWith();
  }

  Future<bool> _send(String phone) async {
    state = state.copyWith(isBusy: true);
    try {
      final challenge = await ref.read(authRepositoryProvider).requestCode(phone);
      state = SignInState(phone: phone, codesSent: state.codesSent + 1, resendIn: challenge.resendIn);
      return true;
    } on Failure catch (failure) {
      state = state.copyWith(isBusy: false, problem: RequestFailed(failure));
      return false;
    }
  }
}

final signInControllerProvider = NotifierProvider<SignInController, SignInState>(SignInController.new);
