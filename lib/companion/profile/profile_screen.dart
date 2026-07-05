import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/tact_theme.dart';
import '../widgets/tact_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.state});

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
                  title: 'Профиль',
                  subtitle: 'Статистика и лимиты использования',
                ),
                const SizedBox(height: 24),
                const Text(
                  'Лимиты на сегодня',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: TactColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TactCard(
                  child: Column(
                    children: [
                      _limitRow(
                        'Смягчить',
                        state.softenUsed,
                        state.softenLimit,
                        TactColors.orange,
                      ),
                      const SizedBox(height: 16),
                      _limitRow(
                        'Исправить',
                        state.correctUsed,
                        state.correctLimit,
                        TactColors.purple,
                      ),
                      const SizedBox(height: 16),
                      _limitRow(
                        'Улучшить',
                        state.improveUsed,
                        state.improveLimit,
                        TactColors.blue,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Лимиты обновятся через 14:32:11',
                        style: TextStyle(
                          fontSize: 12,
                          color: TactColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TactCard(
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Текущий план',
                              style: TextStyle(
                                fontSize: 13,
                                color: TactColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Free',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: TactColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: TactColors.purple,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Улучшить план'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TactCard(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      TactSettingsRow(
                        title: 'История активности',
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      TactSettingsRow(
                        title: 'Настройки аккаунта',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _limitRow(String label, int used, int limit, Color color) {
    final progress = used / limit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: TactColors.textPrimary,
              ),
            ),
            Text(
              '$used / $limit',
              style: const TextStyle(
                fontSize: 13,
                color: TactColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: const Color(0xFF27272A),
            color: color,
          ),
        ),
      ],
    );
  }
}
