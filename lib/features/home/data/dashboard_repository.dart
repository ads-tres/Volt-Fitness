import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/errors/failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/json.dart';
import '../../../core/network/loaded.dart';
import '../../../core/storage/preferences_store.dart';
import '../../../core/tenant/selected_organization.dart';
import '../domain/dashboard.dart';
import 'member_json.dart';

/// The home screen's data for the selected gym. The last copy is cached per
/// gym, so the app opens with it instantly and offline, then refreshes.
final class DashboardController extends Notifier<Loaded<Dashboard>> {
  static const _cacheKey = '${userDataPrefix}dashboard.';

  @override
  Loaded<Dashboard> build() {
    final organizationId = ref.watch(selectedOrganizationProvider.select((organization) => organization?.id));
    if (organizationId == null) return const Loaded();
    unawaited(Future.microtask(refresh));
    return Loaded(value: _cached(organizationId), isLoading: true);
  }

  Future<void> refresh() async {
    final organizationId = ref.read(selectedOrganizationProvider)?.id;
    if (!ref.mounted || organizationId == null) return;
    state = state.loading();
    try {
      final json = dataObject(await ref.read(apiClientProvider).get('/me/dashboard'));
      final dashboard = readResponse(() => dashboardFromJson(json));
      await ref.read(preferencesStoreProvider).setString('$_cacheKey$organizationId', jsonEncode(json));
      if (ref.mounted) state = Loaded(value: dashboard);
    } on Failure catch (failure) {
      if (ref.mounted) state = state.failed(failure);
    }
  }

  Dashboard? _cached(String organizationId) {
    final stored = ref.read(preferencesStoreProvider).getString('$_cacheKey$organizationId');
    if (stored == null) return null;
    try {
      return dashboardFromJson(jsonDecode(stored) as Map<String, dynamic>);
    } on Object {
      // Cached by an older app version in another shape; refresh replaces it.
      return null;
    }
  }
}

final dashboardProvider = NotifierProvider<DashboardController, Loaded<Dashboard>>(DashboardController.new);
