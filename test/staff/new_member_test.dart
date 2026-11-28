import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_mobile/core/errors/failure.dart';
import 'package:gym_mobile/core/network/api_client.dart';
import 'package:gym_mobile/core/time/local_date.dart';
import 'package:gym_mobile/staff/core/desk_session.dart';
import 'package:gym_mobile/staff/fake_front_desk.dart';
import 'package:gym_mobile/staff/features/desk/data/member_search.dart';
import 'package:gym_mobile/staff/features/desk/data/new_member_repository.dart';

import '../support/test_doubles.dart';

void main() {
  Future<ProviderContainer> desk({StubAdapter? adapter, String phone = FakeFrontDesk.staffPhone, String role = 'owner'}) async {
    final container = ProviderContainer.test(
      overrides: await testOverrides(
        fakeBackend: adapter == null,
        fakeAdapter: FakeFrontDesk(latency: Duration.zero, now: () => testNow),
      ),
    );
    if (adapter != null) container.read(dioProvider).httpClientAdapter = adapter;
    final session = container.read(deskSessionProvider.notifier);
    await session.signIn(
      token: adapter == null ? 'fake-desk-token:$phone' : '9|desk',
      name: 'Demo',
      gyms: [DeskGym(slug: 'demo-gym', name: 'Demo Gym', role: role, worksAtAllBranches: true)],
    );
    await session.selectBranch(const DeskBranch(id: 1, name: 'Main Branch'));
    return container;
  }

  Future<Map<String, List<String>>> refusals(Future<void> Function() call) async {
    try {
      await call();
    } on ValidationFailure catch (failure) {
      return failure.fieldErrors;
    }
    return const {};
  }

  test('sends the member as the API takes it, at the desk\'s branch, with phones as E.164', () async {
    final adapter = StubAdapter(
      (_) => jsonResponse(201, {
        'data': {'id': 12, 'full_name': 'Selam Tesfaye', 'phone': '+251944556677', 'membership': null, 'photo_url': null},
      }),
    );
    final added = await (await desk(adapter: adapter))
        .read(newMemberRepositoryProvider)
        .add(
          NewMember(
            fullName: ' Selam Tesfaye ',
            phone: '0944 55 66 77',
            gender: 'female',
            dateOfBirth: LocalDate(1998, 3, 4),
            messageLanguage: 'am',
            emergencyContactName: 'Tesfaye',
            emergencyContactPhone: '0911223344',
          ),
        );

    expect(adapter.requests.single.path, '/organizations/demo-gym/members');
    expect(adapter.requests.single.data, {
      'full_name': 'Selam Tesfaye',
      'phone': '+251944556677',
      'home_branch_id': 1,
      'gender': 'female',
      'date_of_birth': '1998-03-04',
      'message_language': 'am',
      'emergency_contact_name': 'Tesfaye',
      'emergency_contact_phone': '+251911223344',
    });
    expect(added.id, 12);
    expect(added.name, 'Selam Tesfaye');
  });

  test('only owners, managers and receptionists add, sell and freeze; only owners and managers cancel', () async {
    expect((await desk(role: 'owner')).read(deskRolesProvider), (mayAddMembers: true, maySell: true, mayFreeze: true, mayCancel: true, maySeePayments: true, maySeeRevenueInsights: true, maySeeInsights: true));
    expect(
      (await desk(role: 'receptionist')).read(deskRolesProvider),
      (mayAddMembers: true, maySell: true, mayFreeze: true, mayCancel: false, maySeePayments: true, maySeeRevenueInsights: false, maySeeInsights: false),
    );
    expect((await desk(role: 'manager')).read(deskRolesProvider).mayCancel, isTrue);
    expect((await desk(role: 'trainer')).read(deskRolesProvider).maySeePayments, isFalse);
    expect(
      (await desk(role: 'accountant')).read(deskRolesProvider),
      (mayAddMembers: false, maySell: false, mayFreeze: false, mayCancel: false, maySeePayments: true, maySeeRevenueInsights: true, maySeeInsights: false),
    );
  });

  test('the fake adds a member who is then found, and refuses a taken phone and half a contact', () async {
    final container = await desk();
    final members = container.read(newMemberRepositoryProvider);

    final selam = await members.add(const NewMember(fullName: 'Selam Tesfaye', phone: '0944556677'));
    final found = await container.read(memberSearchProvider('selam').future);
    expect(found.single.id, selam.id);
    expect(found.single.status, isNull, reason: 'no plan yet');

    final errors = await refusals(
      () => members.add(const NewMember(fullName: '', phone: '0911 234 567', emergencyContactName: 'Mother')),
    );
    expect(errors['full_name'], ['The full name field is required.']);
    expect(errors['phone'], ['The phone has already been taken.'], reason: "Abebe's number");
    expect(errors['emergency_contact_phone'], [
      'The emergency contact phone field is required when emergency contact name is present.',
    ]);
  });

  test('an edit sends every field, so an emptied one is cleared', () async {
    final adapter = StubAdapter((_) => jsonResponse(200, {'data': <String, Object?>{}}));
    await (await desk(adapter: adapter))
        .read(newMemberRepositoryProvider)
        .update(3, const NewMember(fullName: 'Hana G. Girma', phone: '0933 456 789'), homeBranchId: 2);

    expect(adapter.requests.single.method, 'PUT');
    expect(adapter.requests.single.path, '/organizations/demo-gym/members/3');
    expect(adapter.requests.single.data, {
      'full_name': 'Hana G. Girma',
      'phone': '+251933456789',
      'home_branch_id': 2,
      'gender': null,
      'date_of_birth': null,
      'email': null,
      'message_language': null,
      'emergency_contact_name': null,
      'emergency_contact_phone': null,
    });
  });

  test('the fake keeps a member\'s own phone, refuses another\'s, and shows the edit everywhere', () async {
    final container = await desk();
    final members = container.read(newMemberRepositoryProvider);

    try {
      await members.update(3, const NewMember(fullName: 'Hana Girma', phone: '0911 234 567'), homeBranchId: 1);
      fail('Abebe\'s phone was taken');
    } on ValidationFailure catch (failure) {
      expect(failure.fieldErrors['phone'], ['The phone has already been taken.']);
    }

    await members.update(3, const NewMember(fullName: 'Hana G. Girma', phone: '0933 456 789'), homeBranchId: 1);
    final found = await container.read(memberSearchProvider('girma').future);
    expect(found.single.name, 'Hana G. Girma');
  });
}
