import 'package:flutter/material.dart';
import '../settings/settings_screen.dart';
import '../state/app_state.dart';
import '../theme/tact_theme.dart';
import '../widgets/tact_widgets.dart';

/// Quiet account screen — no marketing chrome, no duplicate limits.
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                const Text(
                  'Профиль',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: TactColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Аккаунт и план',
                  style: TextStyle(
                    fontSize: 13,
                    color: TactColors.textMuted,
                  ),
                ),
                const SizedBox(height: 28),
                TactCard(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: TactColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: TactColors.surfaceBorder,
                            width: 0.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'T',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: TactColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Гость',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: TactColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'План Free',
                              style: TextStyle(
                                fontSize: 13,
                                color: TactColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: TactColors.textSecondary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, TactLayout.minTouchTarget),
                        ),
                        child: const Text(
                          'Улучшить',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TactCard(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      TactSettingsRow(
                        title: 'История активности',
                        subtitle: 'Недавние действия',
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 12, endIndent: 12),
                      TactSettingsRow(
                        title: 'Настройки',
                        subtitle: 'Клавиатура, звук, язык',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SettingsScreen(state: state),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Center(
                  child: Text(
                    'TACT · 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: TactColors.textMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
