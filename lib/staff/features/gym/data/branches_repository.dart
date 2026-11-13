import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/json.dart';
import '../../../core/desk_session.dart';

/// The branches of the chosen gym that the staff member works at.
/// It depends on the gym alone, so choosing a branch doesn't load it again.
final deskBranchesProvider = FutureProvider.autoDispose<List<DeskBranch>>((ref) async {
  ref.watch(deskSessionProvider.select((session) => session is DeskSignedIn ? session.gym?.slug : null));
  final response = await ref.watch(apiClientProvider).get(deskPath(ref.read(deskSessionProvider), '/branches'));
  return readResponse(
    () => [
      for (final branch in (response! as Map<String, dynamic>).objects('data'))
        DeskBranch(id: branch.field<int>('id'), name: branch.field<String>('name')),
    ],
  );
});
