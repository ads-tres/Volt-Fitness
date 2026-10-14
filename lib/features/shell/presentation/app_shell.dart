import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/design/tokens.dart';
import '../../../core/errors/failure.dart';
import '../../auth/data/auth_repository.dart';
import 'volt_navigation_bar.dart';

/// The signed-in app: five tabs, each keeping its own navigation stack.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    unawaited(_refreshProfile());
  }

  /// The cached profile opens the app instantly; this brings in changes
  /// such as a new gym. A 401 here signs out through the interceptor.
  Future<void> _refreshProfile() async {
    try {
      final profile = await ref.read(authRepositoryProvider).fetchProfile();
      await ref.read(sessionControllerProvider.notifier).updateProfile(profile);
    } on Failure {
      // Offline or failing: keep the cached profile.
    }
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.navigationShell;
    return Scaffold(
      // The page's rounded bottom corners show the bar's colour behind them.
      backgroundColor: AppColors.night,
      body: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        child: ColoredBox(color: AppColors.canvas, child: shell),
      ),
      bottomNavigationBar: VoltNavigationBar(
        currentIndex: shell.currentIndex,
        // A tap on the current tab goes back to its first screen.
        onSelect: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
      ),
    );
  }
}
