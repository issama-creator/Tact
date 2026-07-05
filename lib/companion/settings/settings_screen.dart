import 'package:flutter/material.dart';
import '../platform/ime_platform.dart';
import '../state/app_state.dart';
import '../theme/tact_theme.dart';
import '../widgets/tact_widgets.dart';

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
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionTitle('Клавиатура'),
              TactCard(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    TactSettingsRow(
                      title: 'Сменить на Gboard / другую',
                      subtitle: 'Выбор клавиатуры',
                      onTap: ImePlatform.showInputMethodPicker,
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
                      onTap: () {},
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
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: TactColors.textSecondary,
        ),
      ),
    );
  }

  void _pickLanguage(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: TactColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Русский',
                    style: TextStyle(color: TactColors.textPrimary)),
                onTap: () {
                  state.setKeyboardLanguage('Русский');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('English',
                    style: TextStyle(color: TactColors.textPrimary)),
                onTap: () {
                  state.setKeyboardLanguage('English');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
