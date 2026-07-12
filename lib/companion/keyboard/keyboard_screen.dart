import 'package:flutter/material.dart';
import '../shortcuts/shortcuts_screen.dart';
import '../state/app_state.dart';
import '../theme/tact_theme.dart';
import '../widgets/daily_limits_card.dart';
import '../widgets/ime_status_card.dart';
import '../widgets/tact_widgets.dart';

class KeyboardScreen extends StatelessWidget {
  const KeyboardScreen({super.key, required this.state});

  final CompanionAppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TactColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: state,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const TactSectionHeader(
                  title: 'Клавиатура',
                  subtitle: 'Настройте функции клавиатуры под себя',
                ),
                const SizedBox(height: 20),
                const ImeStatusCard(),
                const SizedBox(height: 24),
                const TactSectionLabel('Режимы проверки'),
                const SizedBox(height: 8),
                TactCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Column(
                    children: [
                      TactToggleRow(
                        icon: Icons.shield_rounded,
                        iconColor: TactColors.red,
                        iconBg: TactColors.red.withValues(alpha: 0.12),
                        title: 'Anti-Mat',
                        subtitle: 'Блокировка мата и оскорблений',
                        value: state.antiMat,
                        onChanged: state.setAntiMat,
                      ),
                      const Divider(height: 1),
                      TactToggleRow(
                        icon: Icons.vibration_rounded,
                        iconColor: TactColors.red,
                        iconBg: TactColors.red.withValues(alpha: 0.12),
                        title: 'Вибрация при мате',
                        subtitle: 'Виброотклик, когда найден мат',
                        value: state.matVibration,
                        onChanged: state.setMatVibration,
                      ),
                      const Divider(height: 1),
                      TactToggleRow(
                        icon: Icons.warning_amber_rounded,
                        iconColor: TactColors.orange,
                        iconBg: TactColors.orange.withValues(alpha: 0.12),
                        title: 'Anti-Toxic',
                        subtitle: 'Предупреждение о резком тоне',
                        value: state.antiToxic,
                        onChanged: state.setAntiToxic,
                      ),
                      const Divider(height: 1),
                      TactToggleRow(
                        icon: Icons.auto_awesome_rounded,
                        iconColor: TactColors.accent,
                        iconBg: TactColors.accent.withValues(alpha: 0.12),
                        title: 'ИИ-помощник',
                        subtitle: 'Исправляйте ошибки и следите за пунктуацией',
                        value: state.aiAssistant,
                        onChanged: state.setAiAssistant,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TactCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TactSettingsRow(
                    title: 'Сокращения (hotwords)',
                    subtitle: 'др → Добрый день и свои варианты',
                    showChevron: true,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ShortcutsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const TactSectionLabel('Лимиты на сегодня'),
                const SizedBox(height: 8),
                DailyLimitsCard(state: state),
              ],
            );
          },
        ),
      ),
    );
  }
}
