import 'dart:async';

import 'package:flutter/material.dart';

import '../settings/settings_screen.dart';
import '../shortcuts/shortcuts_screen.dart';
import '../state/app_state.dart';
import '../theme/tact_theme.dart';
import '../widgets/tact_widgets.dart';

/// Main dashboard — streak first, then protection facts.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.state});

  final CompanionAppState state;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CompanionAppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(state.hydrate(forceRefresh: true));
    });
  }

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
                SliverToBoxAdapter(child: _header(context)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _streakHero(),
                      const SizedBox(height: 14),
                      _protectionCard(),
                      const SizedBox(height: 14),
                      _scoreCompact(),
                      const SizedBox(height: 14),
                      _hotwordsRow(context),
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

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 0),
      child: Row(
        children: [
          const Text(
            'TACT',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: TactColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: TactColors.textPrimary),
            tooltip: 'Настройки',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SettingsScreen(state: state),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _streakHero() {
    final progress = state.cleanRecordDays <= 0
        ? 0.0
        : (state.cleanStreakDays / state.cleanRecordDays).clamp(0.0, 1.0);

    return TactCard(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Без мата и токсичности',
            style: TextStyle(
              fontSize: 13,
              color: TactColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${state.cleanStreakDays}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: TactColors.textPrimary,
                  height: 1,
                  letterSpacing: -1.2,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8, left: 8),
                child: Text(
                  'дн.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: TactColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'рекорд ${state.cleanRecordDays}',
                style: const TextStyle(
                  fontSize: 13,
                  color: TactColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: TactColors.green.withValues(alpha: 0.12),
              color: TactColors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _protectionCard() {
    return TactCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          _protectionRow(
            color: TactColors.red,
            label: 'Мат',
            detail: 'заблокировано',
            value: state.matBlockedCount,
          ),
          const Divider(height: 1),
          _protectionRow(
            color: TactColors.orange,
            label: 'Токсичность',
            detail: 'смягчено',
            value: state.toxicSoftenedCount,
          ),
          const Divider(height: 1),
          _protectionRow(
            color: TactColors.accent,
            label: 'ИИ-помощь',
            detail: 'раз',
            value: state.aiAssistCount,
          ),
        ],
      ),
    );
  }

  Widget _protectionRow({
    required Color color,
    required String label,
    required String detail,
    required int value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: TactColors.textPrimary,
                    ),
                  ),
                  TextSpan(
                    text: '  ·  $detail',
                    style: const TextStyle(
                      fontSize: 13,
                      color: TactColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreCompact() {
    return TactCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
      child: Row(
        children: [
          CommunicationScoreRing(
            score: state.communicationScore,
            maxScore: 100,
            size: 56,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Communication Score',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: TactColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _scoreSubtitle(state.communicationScore),
                  style: const TextStyle(
                    fontSize: 12,
                    color: TactColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _scoreSubtitle(int score) {
    if (score >= 80) return 'Спокойно и уважительно';
    if (score >= 50) return 'Есть прогресс';
    return 'TACT помогает с тоном';
  }

  Widget _hotwordsRow(BuildContext context) {
    final count = state.hotwordsCount;
    final hasAny = count > 0;
    final countLabel = count == 0
        ? 'Пока нет своих'
        : count == 1
            ? '1 сокращение'
            : '$count сокращений';

    return TactCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: TactColors.purple.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: TactColors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Hotwords',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: TactColors.textPrimary,
                  ),
                ),
              ),
              Text(
                countLabel,
                style: const TextStyle(
                  fontSize: 13,
                  color: TactColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Горячие слова — короткие триггеры, которые '
            'разворачиваются в готовую фразу на клавиатуре.',
            style: TextStyle(
              fontSize: 13,
              color: TactColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Например: др → Добрый день',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: TactColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: TactLayout.minTouchTarget,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ShortcutsScreen(),
                  ),
                );
                await state.refreshHotwordsCount();
              },
              icon: Icon(
                hasAny ? Icons.edit_rounded : Icons.add_rounded,
                size: 18,
              ),
              label: Text(
                hasAny ? 'Управлять hotwords' : 'Создать hotword',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: TactColors.purple,
                side: BorderSide(
                  color: TactColors.purple.withValues(alpha: 0.55),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
