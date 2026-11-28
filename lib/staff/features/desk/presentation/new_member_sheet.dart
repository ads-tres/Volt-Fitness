import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/design/widgets/controls.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_messages.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/time/clock.dart' as clock;
import '../../../../core/time/date_text.dart';
import '../../../../core/time/local_date.dart';
import '../../../core/desk_session.dart';
import '../../../../core/utils/ethiopian_phone.dart';
import '../../gym/data/branches_repository.dart';
import '../../member/data/member_profile_repository.dart';
import '../data/member_search.dart';
import '../data/new_member_repository.dart';

/// What came of the form: the member added, the edit saved, or a phone
/// already registered that the desk wants to find instead.
typedef NewMemberOutcome = ({DeskMember? added, bool saved, String? findPhone});

/// The form for someone joining at the desk, filled in from what was typed
/// in search: digits go in the phone, anything else in the name. With
/// [editing], the same form changes that member's details.
Future<NewMemberOutcome?> showNewMemberSheet(BuildContext context, {String typed = '', DeskMemberProfile? editing}) {
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  return showModalBottomSheet<NewMemberOutcome>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card))),
    builder: (context) => NewMemberSheet(typed: typed, editing: editing),
  );
}

class NewMemberSheet extends ConsumerStatefulWidget {
  const NewMemberSheet({super.key, this.typed = '', this.editing});

  final String typed;

  /// The member whose details are changed, or null to add one.
  final DeskMemberProfile? editing;

  @override
  ConsumerState<NewMemberSheet> createState() => _NewMemberSheetState();
}

class _NewMemberSheetState extends ConsumerState<NewMemberSheet> {
  late final _name = TextEditingController();
  late final _phone = TextEditingController();
  final _email = TextEditingController();
  final _contactName = TextEditingController();
  final _contactPhone = TextEditingController();
  String? _gender;
  LocalDate? _dateOfBirth;
  String? _language;
  int? _homeBranchId;
  var _adding = false;
  Map<String, List<String>> _fieldErrors = const {};
  String? _error;

  /// Laravel's words for a phone another member of the gym has.
  static const _phoneTaken = 'has already been taken';

  @override
  void initState() {
    super.initState();
    if (widget.editing case final member?) {
      _name.text = member.name;
      _phone.text = member.phone.startsWith('+251') ? '0${member.phone.substring(4)}' : member.phone;
      _email.text = member.email ?? '';
      _contactName.text = member.emergencyContactName ?? '';
      final contactPhone = member.emergencyContactPhone;
      _contactPhone.text = contactPhone == null
          ? ''
          : contactPhone.startsWith('+251')
          ? '0${contactPhone.substring(4)}'
          : contactPhone;
      _gender = member.gender;
      _dateOfBirth = member.dateOfBirth;
      _language = member.messageLanguage;
      _homeBranchId = member.homeBranchId;
      return;
    }
    final typed = widget.typed.trim();
    if (RegExp(r'^[\d\s+]{3,}$').hasMatch(typed)) {
      _phone.text = typed;
    } else {
      _name.text = typed;
    }
  }

  @override
  void dispose() {
    for (final controller in [_name, _phone, _email, _contactName, _contactPhone]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Clears the API's refusals once something is typed, and redraws what
  /// depends on the text (the phone-change note).
  void _changed() => setState(() {
    _fieldErrors = const {};
    _error = null;
  });

  Future<void> _pickBirthday() async {
    final today = ref.read(clock.todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: (_dateOfBirth ?? today.addDays(-25 * 365)).toDateTime(),
      firstDate: today.addDays(-100 * 365).toDateTime(),
      lastDate: today.addDays(-1).toDateTime(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked == null || !mounted) return;
    setState(() => _dateOfBirth = LocalDate.of(picked));
  }

  Future<void> _add() async {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    setState(() {
      _adding = true;
      _fieldErrors = const {};
      _error = null;
    });
    try {
      final typed = NewMember(
        fullName: _name.text,
        phone: _phone.text,
        gender: _gender,
        dateOfBirth: _dateOfBirth,
        email: _email.text,
        messageLanguage: _language ?? ref.read(languageCodeProvider),
        emergencyContactName: _contactName.text,
        emergencyContactPhone: _contactPhone.text,
      );
      final repository = ref.read(newMemberRepositoryProvider);
      if (widget.editing case final member?) {
        final session = ref.read(deskSessionProvider);
        final deskBranch = session is DeskSignedIn ? session.branch?.id : null;
        await repository.update(member.id, typed, homeBranchId: _homeBranchId ?? deskBranch ?? 0);
        navigator.pop((added: null, saved: true, findPhone: null));
      } else {
        navigator.pop((added: await repository.add(typed), saved: false, findPhone: null));
      }
    } on ValidationFailure catch (failure) {
      if (!mounted) return;
      const shownByField = {
        'full_name',
        'phone',
        'email',
        'date_of_birth',
        'gender',
        'emergency_contact_name',
        'emergency_contact_phone',
        'home_branch_id',
      };
      setState(() {
        _adding = false;
        _fieldErrors = failure.fieldErrors;
        _error = failure.fieldErrors.keys.any(shownByField.contains)
            ? null
            : failure.fieldErrors.values.firstOrNull?.firstOrNull ?? failureMessage(l10n, failure);
      });
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() {
        _adding = false;
        _error = failureMessage(l10n, failure);
      });
    }
  }

  Widget _section(IconData icon, String title, String description, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(top: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 2),
        Text(description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );

  TextField _field(
    TextEditingController controller, {
    required Key key,
    required String label,
    required String errorKey,
    String? helper,
    String? prefix,
    Widget? icon,
    TextInputType? keyboard,
    TextCapitalization capitalization = TextCapitalization.none,
  }) => TextField(
    key: key,
    controller: controller,
    enabled: !_adding,
    keyboardType: keyboard,
    textCapitalization: capitalization,
    inputFormatters: keyboard == TextInputType.phone ? [FilteringTextInputFormatter.allow(RegExp(r'[\d\s+]'))] : null,
    onChanged: (_) => _changed(),
    decoration: InputDecoration(
      labelText: label,
      helperText: helper,
      prefixText: prefix,
      prefixIcon: icon,
      errorText: _fieldErrors[errorKey]?.firstOrNull,
      errorMaxLines: 3,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final dates = ref.watch(dateTextProvider);
    final branch = switch (ref.watch(deskSessionProvider)) {
      DeskSignedIn(branch: final branch?) => branch.name,
      _ => '',
    };
    final language = _language ?? ref.watch(languageCodeProvider);
    final phoneTaken = _fieldErrors['phone']?.any((error) => error.contains(_phoneTaken)) ?? false;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.person_add_alt_1_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    switch (widget.editing) {
                      final member? => l10n.editMemberTitle(member.name),
                      null => l10n.newMemberTitle,
                    },
                    style: textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.editing == null ? l10n.newMemberBody(branch) : l10n.editMemberBody,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            _section(Icons.badge_outlined, l10n.newMemberWho, l10n.newMemberWhoHelp, [
              _field(
                _name,
                key: const Key('new-member-name'),
                label: l10n.newMemberName,
                errorKey: 'full_name',
                capitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              _field(
                _phone,
                key: const Key('new-member-phone'),
                label: l10n.newMemberPhone,
                errorKey: 'phone',
                helper: l10n.newMemberPhoneHelp,
                icon: const Icon(Icons.phone_rounded),
                keyboard: TextInputType.phone,
              ),
              if (widget.editing case final member?
                  when (EthiopianPhone.normalize(_phone.text) ?? _phone.text.trim()) != member.phone &&
                      _phone.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    l10n.editMemberPhoneNote,
                    key: const Key('phone-change-note'),
                    style: textTheme.bodySmall?.copyWith(color: AppColors.danger),
                  ),
                ),
              if (phoneTaken)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop((added: null, saved: false, findPhone: _phone.text.trim())),
                    icon: const Icon(Icons.search_rounded, size: 18),
                    label: Text(l10n.newMemberFindThem),
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final (value, label) in [('female', l10n.newMemberFemale), ('male', l10n.newMemberMale)])
                    ChoiceChip(
                      label: Text(label),
                      selected: _gender == value,
                      onSelected: _adding ? null : (selected) => setState(() => _gender = selected ? value : null),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cake_outlined),
                title: Text(l10n.newMemberBirthday),
                subtitle: _fieldErrors['date_of_birth'] == null
                    ? null
                    : Text(_fieldErrors['date_of_birth']!.first, style: textTheme.bodySmall?.copyWith(color: AppColors.danger)),
                trailing: Text(
                  _dateOfBirth == null ? l10n.newMemberOptional : dates.date(_dateOfBirth!),
                  style: textTheme.titleSmall,
                ),
                onTap: _adding ? null : _pickBirthday,
              ),
            ]),
            if (widget.editing != null)
              _section(Icons.store_mall_directory_outlined, l10n.editMemberHomeBranch, l10n.editMemberHomeBranchHelp, [
                switch (ref.watch(deskBranchesProvider)) {
                  AsyncData(:final value) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final each in value)
                        ChoiceChip(
                          label: Text(each.name),
                          selected: _homeBranchId == each.id,
                          onSelected: _adding ? null : (_) => setState(() => _homeBranchId = each.id),
                        ),
                    ],
                  ),
                  _ => Text(widget.editing?.homeBranchName ?? '', style: textTheme.bodyMedium),
                },
                if (_fieldErrors['home_branch_id']?.firstOrNull case final error?)
                  Text(error, style: textTheme.bodySmall?.copyWith(color: AppColors.danger)),
              ]),
            _section(Icons.sms_outlined, l10n.newMemberMessages, l10n.newMemberMessagesHelp, [
              Wrap(
                spacing: 8,
                children: [
                  for (final (value, label) in [('en', 'English'), ('am', 'አማርኛ')])
                    ChoiceChip(
                      label: Text(label),
                      selected: language == value,
                      onSelected: _adding ? null : (_) => setState(() => _language = value),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _field(
                _email,
                key: const Key('new-member-email'),
                label: l10n.newMemberEmail,
                errorKey: 'email',
                helper: l10n.newMemberOptional,
                icon: const Icon(Icons.alternate_email_rounded),
                keyboard: TextInputType.emailAddress,
              ),
            ]),
            _section(Icons.contact_emergency_outlined, l10n.newMemberEmergency, l10n.newMemberEmergencyHelp, [
              _field(
                _contactName,
                key: const Key('new-member-contact-name'),
                label: l10n.newMemberContactName,
                errorKey: 'emergency_contact_name',
                capitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              _field(
                _contactPhone,
                key: const Key('new-member-contact-phone'),
                label: l10n.newMemberContactPhone,
                errorKey: 'emergency_contact_phone',
                icon: const Icon(Icons.phone_rounded),
                keyboard: TextInputType.phone,
              ),
            ]),
            if (_error case final error?) ...[
              const SizedBox(height: 16),
              Text(error, style: textTheme.bodyMedium?.copyWith(color: AppColors.danger)),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: widget.editing == null ? l10n.newMemberAdd : l10n.editMemberSave,
              isLoading: _adding,
              onPressed: _adding ? null : _add,
            ),
          ],
        ),
      ),
    );
  }
}
