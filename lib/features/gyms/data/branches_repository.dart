import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/json.dart';
import '../../../core/tenant/gym_path.dart';
import '../../../core/tenant/selected_organization.dart';
import '../../../core/time/local_date.dart';
import '../domain/gym_branch.dart';

/// The selected gym's branches, by name, with their opening hours
/// (`GET /me/gyms/{gym}/branches`). Throws a [Failure] when it fails.
final class BranchesRepository {
  const BranchesRepository(this._api, this._gym);

  final ApiClient _api;
  final String? Function() _gym;

  Future<List<GymBranch>> branches() async {
    final response = await _api.get(gymPath(_gym(), '/branches'));
    return readResponse(
      () => [for (final branch in (response! as Map<String, dynamic>).objects('data')) gymBranchFromJson(branch)],
    );
  }
}

GymBranch gymBranchFromJson(Map<String, dynamic> json) => GymBranch(
  id: '${json.field<Object>('id')}',
  name: json.field<String>('name'),
  address: json.optional<String>('address'),
  hours: [
    for (final day in json.objects('opening_hours'))
      OpeningHours(
        weekday: day.field<int>('weekday'),
        opensAt: _minutes(day.field<String>('opens_at')),
        closesAt: _minutes(day.field<String>('closes_at')),
      ),
  ],
  closures: [
    for (final closure in json.objects('closures'))
      BranchClosure(
        id: '${closure.field<Object>('id')}',
        startsOn: LocalDate.parse(closure.field<String>('starts_on')),
        endsOn: LocalDate.parse(closure.field<String>('ends_on')),
        reason: closure.optional<String>('reason'),
        opensAt: switch (closure.optional<String>('opens_at')) {
          final time? => _minutes(time),
          null => null,
        },
        closesAt: switch (closure.optional<String>('closes_at')) {
          final time? => _minutes(time),
          null => null,
        },
        repeatsYearly: closure.optional<bool>('repeats_yearly') ?? false,
        ethiopianDate: closure.optional<String>('ethiopian_date'),
      ),
  ]..sort((a, b) => a.startsOn.compareTo(b.startsOn)),
);

/// `06:30` as minutes after midnight.
int _minutes(String time) {
  final [hours, minutes, ...] = time.split(':');
  return int.parse(hours) * 60 + int.parse(minutes);
}

final branchesRepositoryProvider = Provider<BranchesRepository>(
  (ref) => BranchesRepository(ref.watch(apiClientProvider), () => ref.read(selectedOrganizationProvider)?.id),
);

final gymBranchesProvider = FutureProvider.autoDispose<List<GymBranch>>((ref) {
  ref.watch(selectedOrganizationProvider.select((organization) => organization?.id));
  return ref.watch(branchesRepositoryProvider).branches();
});
