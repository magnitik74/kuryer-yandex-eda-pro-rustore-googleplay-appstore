import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../services/locale_service.dart';

class ProfileDialog extends StatefulWidget {
  const ProfileDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProfileDialog(),
    );
  }

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  final LocaleService _locale = LocaleService();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late String _selectedCountry;
  late String _selectedDialCode;

  final List<Map<String, String>> _countries = [
    {'id': 'ru', 'name': 'Россия 🇷🇺', 'code': '+7'},
    {'id': 'kz', 'name': 'Казахстан 🇰🇿', 'code': '+7'},
    {'id': 'uz', 'name': 'Узбекистан 🇺🇿', 'code': '+998'},
    {'id': 'kg', 'name': 'Кыргызстан 🇰🇬', 'code': '+996'},
    {'id': 'by', 'name': 'Беларусь 🇧🇾', 'code': '+375'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _locale.userName);
    _phoneController = TextEditingController(text: _locale.userPhone);
    _selectedCountry = _locale.workCountry;
    _selectedDialCode = _locale.phoneDialCode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    HapticFeedback.lightImpact();
    await _locale.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      dialCode: _selectedDialCode,
      country: _selectedCountry,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _locale.tr('deleteAccount'),
          style: const TextStyle(fontFamily: 'MontFamily', fontWeight: FontWeight.w700),
        ),
        content: Text(
          _locale.tr('deleteConfirm'),
          style: const TextStyle(fontFamily: 'MontFamily', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              _locale.tr('cancel'),
              style: const TextStyle(color: Color(0xFF6B6560)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA5455),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _locale.tr('delete'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _locale.deleteAccount();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль успешно удалён')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const textDark = Color(0xFF1A1A1A);
    const textGray = Color(0xFF6B6560);
    const primaryYellow = Color(0xFFFCE000);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E3DF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _locale.tr('profile'),
                style: const TextStyle(
                  fontFamily: 'MontFamily',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              _buildLangSelector(),
            ],
          ),
          const SizedBox(height: 18),

          // 1. Страна работы
          Text(
            _locale.tr('workCountry'),
            style: const TextStyle(
              fontFamily: 'MontFamily',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textGray,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F4F2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCountry,
                isExpanded: true,
                items: _countries.map((c) {
                  return DropdownMenuItem<String>(
                    value: c['id'],
                    child: Text(
                      c['name']!,
                      style: const TextStyle(
                        fontFamily: 'MontFamily',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCountry = val;
                      final match = _countries.firstWhere((c) => c['id'] == val);
                      _selectedDialCode = match['code']!;
                    });
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 2. Имя
          Text(
            _locale.tr('name'),
            style: const TextStyle(
              fontFamily: 'MontFamily',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textGray,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F4F2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Иван / Alisher',
                hintStyle: TextStyle(color: Color(0xFF9E9B97), fontSize: 14),
              ),
              style: const TextStyle(
                fontFamily: 'MontFamily',
                fontSize: 14,
                color: textDark,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 3. Телефон с префиксом флага
          Text(
            _locale.tr('phone'),
            style: const TextStyle(
              fontFamily: 'MontFamily',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textGray,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F4F2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _selectedDialCode,
                  style: const TextStyle(
                    fontFamily: 'MontFamily',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F4F2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '999 123-45-67',
                      hintStyle: TextStyle(color: Color(0xFF9E9B97), fontSize: 14),
                    ),
                    style: const TextStyle(
                      fontFamily: 'MontFamily',
                      fontSize: 14,
                      color: textDark,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Кнопка Сохранить
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryYellow,
                foregroundColor: textDark,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _locale.tr('save'),
                style: const TextStyle(
                  fontFamily: 'MontFamily',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Кнопка удаления аккаунта (Строго для Apple Guideline 5.1.1(v))
          Center(
            child: TextButton.icon(
              onPressed: _confirmDeleteAccount,
              icon: const Icon(PhosphorIcons.trash, color: Color(0xFFEA5455), size: 16),
              label: Text(
                _locale.tr('deleteAccount'),
                style: const TextStyle(
                  fontFamily: 'MontFamily',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEA5455),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangSelector() {
    final current = _locale.currentLang;
    final langs = [
      {'code': 'ru', 'label': '🇷🇺'},
      {'code': 'uz', 'label': '🇺🇿'},
      {'code': 'kg', 'label': '🇰🇬'},
      {'code': 'kz', 'label': '🇰🇿'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: langs.map((l) {
          final isSelected = l['code'] == current;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _locale.setLanguage(l['code']!);
              setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFCE000) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                l['label']!,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
