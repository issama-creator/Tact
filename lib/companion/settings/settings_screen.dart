import 'package:flutter/material.dart';
import '../platform/ime_platform.dart';
import '../state/app_state.dart';
import '../theme/tact_theme.dart';
import '../widgets/keyboard_picker_sheet.dart';
import '../widgets/tact_widgets.dart';
import 'personal_words_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});

  final CompanionAppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TactColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Настройки'),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: state,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.all(TactLayout.screenPadding),
              children: [
              _sectionTitle('Клавиатура'),
              TactCard(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    TactSettingsRow(
                      title: 'Сменить клавиатуру',
                      subtitle: 'TACT или Gboard',
                      onTap: () => showKeyboardPickerSheet(context),
                    ),
                    const Divider(height: 1),
                    TactSettingsRow(
                      title: 'Управление клавиатурами',
                      subtitle: 'Включить Gboard обратно',
                      onTap: ImePlatform.openImeSettings,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle('Общие'),
              TactCard(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    TactSettingsRow(
                      title: 'Язык клавиатуры',
                      subtitle: state.keyboardLanguage,
                      showChevron: true,
                      onTap: () => _pickLanguage(context),
                    ),
                    const Divider(height: 1),
                    TactSettingsRow(
                      title: 'Вибрация',
                      trailing: Switch(
                        value: state.vibration,
                        onChanged: state.setVibration,
                      ),
                      showChevron: false,
                    ),
                    const Divider(height: 1),
                    TactSettingsRow(
                      title: 'Звук',
                      trailing: Switch(
                        value: state.sound,
                        onChanged: state.setSound,
                      ),
                      showChevron: false,
                    ),
                    const Divider(height: 1),
                    TactSettingsRow(
                      title: 'Показывать подсказки',
                      trailing: Switch(
                        value: state.showTips,
                        onChanged: state.setShowTips,
                      ),
                      showChevron: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle('Словари'),
              TactCard(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TactSettingsRow(
                  title: 'Личный словарь',
                  subtitle: 'Имена, бренды, сленг',
                  showChevron: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PersonalWordsScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle('Конфиденциальность'),
              TactCard(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    const TactSettingsRow(
                      title: 'Обработка данных',
                      subtitle: 'Локальная обработка',
                      showChevron: true,
                    ),
                    const Divider(height: 1),
                    const TactSettingsRow(
                      title: 'Отправка текста в AI',
                      subtitle: 'Только по нажатию кнопки',
                      showChevron: true,
                    ),
                    const Divider(height: 1),
                    TactSettingsRow(
                      title: 'Очистить статистику',
                      titleColor: TactColors.red,
                      showChevron: false,
                      onTap: () => _confirmClearStats(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle('О приложении'),
              const TactCard(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: TactSettingsRow(
                  title: 'Версия',
                  subtitle: '1.0.0 (23)',
                  showChevron: false,
                ),
              ),
            ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: TactColors.textSecondary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  void _confirmClearStats(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TactColors.surfaceElevated,
        title: const Text(
          'Очистить статистику?',
          style: TextStyle(color: TactColors.textPrimary),
        ),
        content: const Text(
          'Сбросятся счётчики, серия и Communication Score. '
          'Лимиты ИИ и настройки клавиатуры не изменятся.',
          style: TextStyle(color: TactColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              await state.clearAllStats();
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Статистика очищена')),
                );
              }
            },
            child: const Text(
              'Очистить',
              style: TextStyle(color: TactColors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _pickLanguage(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Язык клавиатуры',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: TactColors.textPrimary,
                  ),
                ),
              ),
            ),
            _languageTile(ctx, 'Русский'),
            _languageTile(ctx, 'English'),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _languageTile(BuildContext context, String label) {
    final selected = state.keyboardLanguage == label;
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(color: TactColors.textPrimary),
      ),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: TactColors.purple)
          : null,
      onTap: () {
        state.setKeyboardLanguage(label);
        Navigator.pop(context);
      },
    );
  }
}
