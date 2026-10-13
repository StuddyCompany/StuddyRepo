import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/format_service.dart';
import '../services/role_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/profile_header.dart';
import '../widgets/studdy_button.dart';
import '../widgets/studdy_select_field.dart';
import '../widgets/studdy_text_field.dart';
import '../services/lesson_service.dart';
import '../utils/formatters.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _authService = AuthService();
  final _userService = UserService();
  final _roleService = RoleService();
  final _formatService = FormatService();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _university = TextEditingController();
  final _course = TextEditingController();
  final _rate = TextEditingController();
  final _about = TextEditingController();
  final _lessonService = LessonService();

  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _formats = [];
  Map<String, dynamic>? _role;
  Set<int> _formatIds = {};
  num? _initialRate;

  String? _avatarUrl;
  Uint8List? _avatarBytes;

  String? _firstNameError;
  String? _universityError;
  String? _courseError;
  String? _roleError;
  String? _rateError;
  String? _formatsError;

  bool _argsRead = false;
  bool _saving = false;

  bool get _isTutor => _role?['name'] == 'Репетитор';
  bool _profileLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    _argsRead = true;
    _loadProfile();
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

  Future<void> _loadLookups() async {
    final roles = await _roleService.getRoles();
    final formats = await _formatService.getFormats();
    if (!mounted) return;
    setState(() {
      _roles = roles;
      _formats = formats;
    });
  }

  Future<void> _loadProfile() async {
    final id = _authService.currentUser?.id;
    if (id == null) {
      setState(() => _profileLoading = false);
      return;
    }
    final profile = await _userService.getProfile(id);
    if (!mounted) return;
    setState(() {
      if (profile != null) {
        _fill(profile);
      }
      _profileLoading = false;
    });
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
    _avatarUrl = profile['avatar_url'] as String?;
    final links = (profile['user_lesson_formats'] as List?) ?? const [];
    _formatIds = {
      for (final link in links)
        if (link['format'] != null)
          (link['format'] as Map<String, dynamic>)['id'] as int,
    };
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _avatarBytes = bytes);
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
        _formatsError = null;
      });
    }
  }

  void _toggleFormat(int id) {
    setState(() {
      if (_formatIds.contains(id)) {
        _formatIds.remove(id);
      } else {
        _formatIds.add(id);
      }
      _formatsError = null;
    });
  }

  Future<void> _save() async {
    final isTutor = _isTutor;

    setState(() {
      _firstNameError = Validators.required(_firstName.text);
      _universityError = Validators.required(_university.text);
      _courseError = Validators.course(_course.text);
      _roleError = _role == null ? Validators.fillField : null;
      _rateError = isTutor ? Validators.hourlyRate(_rate.text) : null;
      _formatsError = isTutor && _formatIds.isEmpty ? 'Выберите формат' : null;
    });
    if ([
      _firstNameError,
      _universityError,
      _courseError,
      _roleError,
      _rateError,
      _formatsError,
    ].any((e) => e != null)) {
      return;
    }

    final newRate =
        isTutor ? num.parse(_rate.text.trim().replaceAll(',', '.')) : null;
    if (isTutor && newRate != _initialRate) {
      final active = await _lessonService.countActiveAsTeacher();
      if (!mounted) return;
      if (active > 0) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Новая стоимость часа',
                style: AppText.custom(20, AppColors.navy)),
            content: Text(
              'Новая ставка будет действовать только для новых заявок. '
              'У $active ${Formatters.plural(active, 'занятия', 'занятий', 'занятий')} '
              'цена останется прежней.',
              style: AppText.body,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Отмена', style: AppText.body),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Сохранить',
                    style: AppText.custom(16, AppColors.pink)),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final bytes = _avatarBytes;
    if (bytes != null) {
      final url = await _userService.uploadAvatar(bytes);
      if (!mounted) return;
      if (url == null) {
        setState(() => _saving = false);
        _showMessage('Не удалось загрузить фото');
        return;
      }
      _avatarUrl = url;
      _avatarBytes = null;
    }

    final ok = await _userService.updateProfile(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          university: _university.text.trim(),
          course: int.parse(_course.text.trim()),
          roleId: _role!['id'] as int,
          hourlyRate: isTutor
              ? num.parse(_rate.text.trim().replaceAll(',', '.'))
              : null,
          description: _about.text.trim(),
        ) &&
        await _userService.setFormats(isTutor ? _formatIds.toList() : []);
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
                avatarUrl: _avatarUrl,
                avatarBytes: _avatarBytes,
                onEditAvatar: _pickAvatar,
              ),
              if (_profileLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.navy),
                  ),
                )
              else
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
                        const SizedBox(height: 12),
                        _label('Формат занятий'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final f in _formats)
                              _FormatChip(
                                name: f['name'] as String,
                                selected: _formatIds.contains(f['id']),
                                onTap: () => _toggleFormat(f['id'] as int),
                              ),
                          ],
                        ),
                        if (_formatsError != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, top: 4),
                            child: Text(_formatsError!, style: AppText.caption),
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
                          label: 'Сохранить',
                          loading: _saving,
                          onPressed: _save),
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

class _FormatChip extends StatelessWidget {
  const _FormatChip({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.softBlue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            name,
            style:
                AppText.custom(15, selected ? AppColors.white : AppColors.navy),
          ),
        ),
      ),
    );
  }
}
