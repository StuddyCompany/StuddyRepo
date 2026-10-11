import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/discipline_service.dart';
import '../../services/role_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/studdy_button.dart';
import '../../widgets/studdy_select_field.dart';
import '../../widgets/studdy_text_field.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _userService = UserService();
  final _roleService = RoleService();
  final _disciplineService = DisciplineService();

  final _university = TextEditingController();
  final _course = TextEditingController();

  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _disciplines = [];
  bool _lookupsLoading = true;

  Map<String, dynamic>? _role;
  Set<int> _selectedDisciplineIds = {};

  String? _universityError;
  String? _courseError;
  String? _roleError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  @override
  void dispose() {
    _university.dispose();
    _course.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    final roles = await _roleService.getRoles();
    final disciplines = await _disciplineService.getDisciplines();
    if (!mounted) return;
    setState(() {
      _roles = roles;
      _disciplines = disciplines;
      _lookupsLoading = false;
    });
  }

  String get _disciplinesText => _disciplines
      .where((d) => _selectedDisciplineIds.contains(d['id']))
      .map((d) => d['name'] as String)
      .join(', ');

  Future<void> _pickRole() async {
    if (_roles.isEmpty) {
      _showMessage(_lookupsLoading ? 'Загружаем список…' : 'Список ролей пуст');
      return;
    }
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            for (final role in _roles)
              ListTile(
                title: Text(role['name'] as String,
                    style: AppText.field.copyWith(fontSize: 18)),
                trailing: role['id'] == _role?['id']
                    ? const Icon(Icons.check, color: AppColors.navy)
                    : null,
                onTap: () => Navigator.pop(ctx, role),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        _role = picked;
        _roleError = null;
      });
    }
  }

  Future<void> _pickDisciplines() async {
    if (_disciplines.isEmpty) {
      _showMessage(
          _lookupsLoading ? 'Загружаем список…' : 'Список дисциплин пуст');
      return;
    }
    final selected = {..._selectedDisciplineIds};

    final result = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(top: 12),
                    children: [
                      for (final d in _disciplines)
                        CheckboxListTile(
                          value: selected.contains(d['id']),
                          activeColor: AppColors.navy,
                          title: Text(d['name'] as String,
                              style: AppText.field.copyWith(fontSize: 18)),
                          onChanged: (checked) => setSheetState(() {
                            final id = d['id'] as int;
                            if (checked == true) {
                              selected.add(id);
                            } else {
                              selected.remove(id);
                            }
                          }),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: StuddyButton(
                    label: 'Готово',
                    onPressed: () => Navigator.pop(ctx, selected),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null) setState(() => _selectedDisciplineIds = result);
  }

  Future<void> _save() async {
    setState(() {
      _universityError = Validators.required(_university.text);
      _courseError = Validators.course(_course.text);
      _roleError = _role == null ? Validators.fillField : null;
    });
    if (_universityError != null ||
        _courseError != null ||
        _roleError != null) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final ok = await _userService.saveProfile(
      university: _university.text.trim(),
      course: int.parse(_course.text.trim()),
      roleId: _role!['id'] as int,
      disciplineIds: _selectedDisciplineIds.toList(),
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      _showMessage('Не удалось сохранить. Попробуйте ещё раз');
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: AppColors.navy),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 36),
                  child: Text('Заполните информацию о себе',
                      style: AppText.screenTitle),
                ),
                const SizedBox(height: 18),
                StuddyTextField(
                  controller: _university,
                  hint: 'ВУЗ',
                  hintColor: AppColors.navy,
                  errorText: _universityError,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    if (_universityError != null) {
                      setState(() => _universityError = null);
                    }
                  },
                ),
                const SizedBox(height: 18),
                StuddyTextField(
                  controller: _course,
                  hint: 'Курс',
                  hintColor: AppColors.navy,
                  errorText: _courseError,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (_courseError != null) {
                      setState(() => _courseError = null);
                    }
                  },
                ),
                const SizedBox(height: 18),
                StuddySelectField(
                  label: 'Роль',
                  value: _role?['name'] as String?,
                  errorText: _roleError,
                  onTap: _pickRole,
                ),
                const SizedBox(height: 18),
                StuddySelectField(
                  label: 'Изучаемые дисциплины',
                  value: _disciplinesText,
                  onTap: _pickDisciplines,
                ),
                const SizedBox(height: 122),
                StuddyButton(
                    label: 'Сохранить', loading: _saving, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
