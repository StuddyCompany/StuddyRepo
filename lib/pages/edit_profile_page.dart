import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/role_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/profile_header.dart';
import '../widgets/studdy_button.dart';
import '../widgets/studdy_select_field.dart';
import '../widgets/studdy_text_field.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _authService = AuthService();
  final _userService = UserService();
  final _roleService = RoleService();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _university = TextEditingController();
  final _course = TextEditingController();
  final _rate = TextEditingController();
  final _about = TextEditingController();

  List<Map<String, dynamic>> _roles = [];
  Map<String, dynamic>? _role;

  String? _firstNameError;
  String? _universityError;
  String? _courseError;
  String? _roleError;
  String? _rateError;

  bool _argsRead = false;
  bool _saving = false;

  bool get _isTutor => _role?['name'] == 'Репетитор';

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    _argsRead = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _fill(args);
    } else {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _university.dispose();
    _course.dispose();
    _rate.dispose();
    _about.dispose();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    final roles = await _roleService.getRoles();
    if (!mounted) return;
    setState(() => _roles = roles);
  }

  Future<void> _loadProfile() async {
    final id = _authService.currentUser?.id;
    if (id == null) return;
    final profile = await _userService.getProfile(id);
    if (!mounted || profile == null) return;
    setState(() => _fill(profile));
  }

  void _fill(Map<String, dynamic> profile) {
    _firstName.text = (profile['first_name'] as String?) ?? '';
    _lastName.text = (profile['last_name'] as String?) ?? '';
    _university.text = (profile['university'] as String?) ?? '';
    _course.text = profile['course']?.toString() ?? '';
    _about.text = (profile['description'] as String?) ?? '';
    final rate = profile['hourly_rate'] as num?;
    if (rate != null) {
      _rate.text = rate == rate.roundToDouble()
          ? rate.toInt().toString()
          : rate.toString();
    }
    _role = profile['role'] as Map<String, dynamic>?;
  }

  Future<void> _pickRole() async {
    if (_roles.isEmpty) {
      _showMessage('Загружаем список…');
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
        _rateError = null;
      });
    }
  }

  Future<void> _save() async {
    final isTutor = _isTutor;

    setState(() {
      _firstNameError = Validators.required(_firstName.text);
      _universityError = Validators.required(_university.text);
      _courseError = Validators.course(_course.text);
      _roleError = _role == null ? Validators.fillField : null;
      _rateError = isTutor ? Validators.hourlyRate(_rate.text) : null;
    });
    if ([
      _firstNameError,
      _universityError,
      _courseError,
      _roleError,
      _rateError
    ].any((e) => e != null)) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final ok = await _userService.updateProfile(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      university: _university.text.trim(),
      course: int.parse(_course.text.trim()),
      roleId: _role!['id'] as int,
      hourlyRate:
          isTutor ? num.parse(_rate.text.trim().replaceAll(',', '.')) : null,
      description: _about.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      _showMessage('Профиль сохранён');
      Navigator.pop(context, true);
    } else {
      _showMessage('Не удалось сохранить. Попробуйте ещё раз');
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: AppColors.navy),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 6),
      child: Text(text, style: AppText.custom(14, AppColors.navy50)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(bottom: bottom + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileHeader(
                title: 'Редактирование',
                onBack: () => Navigator.pop(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 18),
                    _label('Имя'),
                    StuddyTextField(
                      controller: _firstName,
                      hint: 'Имя',
                      errorText: _firstNameError,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        if (_firstNameError != null) {
                          setState(() => _firstNameError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _label('Фамилия'),
                    StuddyTextField(
                      controller: _lastName,
                      hint: 'Фамилия',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    _label('ВУЗ'),
                    StuddyTextField(
                      controller: _university,
                      hint: 'ВУЗ',
                      errorText: _universityError,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        if (_universityError != null) {
                          setState(() => _universityError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 110,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _label('Курс'),
                              StuddyTextField(
                                controller: _course,
                                hint: 'Курс',
                                errorText: _courseError,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                onChanged: (_) {
                                  if (_courseError != null) {
                                    setState(() => _courseError = null);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _label('Роль'),
                              StuddySelectField(
                                label: 'Роль',
                                value: _role?['name'] as String?,
                                errorText: _roleError,
                                onTap: _pickRole,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_isTutor) ...[
                      const SizedBox(height: 12),
                      _label('Стоимость часа, ₽'),
                      StuddyTextField(
                        controller: _rate,
                        hint: 'Например, 800',
                        errorText: _rateError,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textInputAction: TextInputAction.done,
                        onChanged: (_) {
                          if (_rateError != null) {
                            setState(() => _rateError = null);
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    _label('О себе'),
                    Container(
                      height: 120,
                      padding: const EdgeInsets.fromLTRB(28, 16, 20, 16),
                      decoration: BoxDecoration(
                        color: AppColors.fieldFill,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: TextField(
                        controller: _about,
                        maxLines: null,
                        expands: true,
                        keyboardType: TextInputType.multiline,
                        style: AppText.custom(16, AppColors.navy),
                        cursorColor: AppColors.navy,
                        decoration: InputDecoration.collapsed(
                          hintText: 'Расскажите о себе',
                          hintStyle: AppText.custom(16, AppColors.navy50),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    StuddyButton(
                        label: 'Сохранить', loading: _saving, onPressed: _save),
                    const SizedBox(height: 40),
                    Center(
                      child: GestureDetector(
                        onTap: _signOut,
                        child: Text(
                          'Выйти из аккаунта',
                          style: AppText.custom(16, AppColors.pink),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
