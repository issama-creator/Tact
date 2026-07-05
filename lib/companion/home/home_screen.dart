import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/tact_theme.dart';
import '../widgets/tact_widgets.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.state});

  final CompanionAppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TactColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: state,
          builder: (context, _) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu_rounded,
                              color: TactColors.textPrimary),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    SettingsScreen(state: state),
                              ),
                            );
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'TACT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: TactColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.workspace_premium_rounded,
                              color: TactColors.gold, size: 26),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _scoreCard(),
                      const SizedBox(height: 16),
                      _statsRow(),
                      const SizedBox(height: 16),
                      _streakCard(),
                      const SizedBox(height: 16),
                      _tipCard(),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _scoreCard() {
    return TactCard(
      child: Row(
        children: [
          CommunicationScoreRing(
            score: state.communicationScore,
            maxScore: 100,
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ваш Communication Score',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: TactColors.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Отличная работа! Вы общаетесь четко и уважительно',
                  style: TextStyle(
                    fontSize: 13,
                    color: TactColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(
          child: _statTile(
            icon: Icons.edit_rounded,
            color: TactColors.purple,
            label: 'Исправлено',
            value: '${state.correctedCount}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            icon: Icons.favorite_rounded,
            color: TactColors.orange,
            label: 'Смягчено',
            value: '${state.softenedCount}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            icon: Icons.auto_awesome_rounded,
            color: TactColors.blue,
            label: 'Улучшено',
            value: '${state.improvedCount}',
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return TactCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: TactColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: TactColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _streakCard() {
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return TactCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: TactColors.orange, size: 22),
              const SizedBox(width: 8),
              Text(
                'Серия ${state.streakDays} дней',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: TactColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final done = i < state.streakDays;
              return Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? TactColors.purple.withValues(alpha: 0.2)
                          : const Color(0xFF27272A),
                      border: Border.all(
                        color: done ? TactColors.purple : TactColors.surfaceBorder,
                      ),
                    ),
                    child: done
                        ? const Icon(Icons.check, size: 16, color: TactColors.purple)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    days[i],
                    style: const TextStyle(
                      fontSize: 10,
                      color: TactColors.textMuted,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _tipCard() {
    return TactCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: TactColors.purple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.emoji_emotions_outlined,
                color: TactColors.purple, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Совет дня',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TactColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Перед отправкой важного сообщения сделайте паузу — '
                  'TACT подскажет, если тон звучит резко.',
                  style: TextStyle(
                    fontSize: 12,
                    color: TactColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
