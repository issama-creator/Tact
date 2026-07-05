import 'package:flutter/material.dart';
import '../platform/ime_platform.dart';
import '../state/app_state.dart';
import '../theme/tact_theme.dart';
import '../widgets/ime_status_card.dart';
import '../widgets/tact_widgets.dart';
class KeyboardScreen extends StatelessWidget {
  const KeyboardScreen({super.key, required this.state});

  final CompanionAppState state;

  Future<void> _useTact() async {
    final status = await ImePlatform.getImeStatus();
    if (!status.tactEnabled) {
      await ImePlatform.openImeSettings();
      return;
    }
    await ImePlatform.activateTact();
  }

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
                const SizedBox(height: 12),
                _imeSetupCard(),
                const SizedBox(height: 24),
                const Text(
                  'Режимы проверки',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: TactColors.textPrimary,
                  ),
                ),
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
                        icon: Icons.chat_bubble_outline_rounded,
                        iconColor: TactColors.purple,
                        iconBg: TactColors.purple.withValues(alpha: 0.12),
                        title: 'Слова-паразиты',
                        subtitle: 'Поиск слов-паразитов',
                        value: state.fillerWords,
                        onChanged: state.setFillerWords,
                      ),
                      const Divider(height: 1),
                      TactToggleRow(
                        icon: Icons.spellcheck_rounded,
                        iconColor: TactColors.blue,
                        iconBg: TactColors.blue.withValues(alpha: 0.12),
                        title: 'Исправление ошибок',
                        subtitle: 'Орфография и пунктуация',
                        value: state.errorCorrection,
                        onChanged: state.setErrorCorrection,
                      ),
                      const Divider(height: 1),
                      TactToggleRow(
                        icon: Icons.auto_awesome_rounded,
                        iconColor: TactColors.yellow,
                        iconBg: TactColors.yellow.withValues(alpha: 0.12),
                        title: 'Улучшение текста',
                        subtitle: 'AI-улучшение стиля и ясности',
                        value: state.textImprovement,
                        onChanged: state.setTextImprovement,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Предпросмотр панели',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: TactColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const TactCard(child: PanelPreviewBar()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _imeSetupCard() {
    return TactCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Переключение клавиатуры',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: TactColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gboard и TACT могут быть включены одновременно. '
            'Выберите активную клавиатуру кнопкой ниже или 🌐 на клавиатуре.',
            style: TextStyle(fontSize: 12, color: TactColors.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _useTact,
              style: FilledButton.styleFrom(
                backgroundColor: TactColors.purple,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Использовать TACT', style: TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => ImePlatform.activateGboard(),
              style: OutlinedButton.styleFrom(
                foregroundColor: TactColors.textPrimary,
                side: const BorderSide(color: TactColors.surfaceBorder),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Использовать Gboard', style: TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: ImePlatform.openImeSettings,
            style: OutlinedButton.styleFrom(
              foregroundColor: TactColors.textMuted,
              side: const BorderSide(color: TactColors.surfaceBorder),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text(
              'Управление клавиатурами в системе',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
