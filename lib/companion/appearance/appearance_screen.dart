import 'package:flutter/material.dart';
import '../preview/preview_screen.dart';
import '../state/app_state.dart';
import '../theme/tact_theme.dart';
import '../widgets/tact_widgets.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key, required this.state});

  final CompanionAppState state;

  static const _themes = [
    _ThemeData('Тёмная', Color(0xFF2A2A2E), Color(0xFF171719)),
    _ThemeData('Светлая', Color(0xFFE5E7EB), Color(0xFFF3F4F6)),
    _ThemeData('Midnight', Color(0xFF312E81), Color(0xFF1E1B4B)),
    _ThemeData('Graphite', Color(0xFF52525B), Color(0xFF27272A)),
    _ThemeData('Ocean', Color(0xFF0EA5E9), Color(0xFF0C4A6E)),
    _ThemeData('Sunset', Color(0xFFF97316), Color(0xFF7C2D12)),
  ];

  static const _panelColors = [
    Color(0xFF14141A),
    Color(0xFF1E1B4B),
    Color(0xFF312E81),
    Color(0xFF0C4A6E),
    Color(0xFF7C2D12),
    Color(0xFF14532D),
    null, // gradient
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossCount = width >= 720 ? 4 : width >= 480 ? 3 : 2;

    return Scaffold(
      backgroundColor: TactColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: state,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.all(TactLayout.screenPadding),
              children: [
                const TactSectionHeader(
                  title: 'Внешний вид',
                  subtitle: 'Настройте внешний вид клавиатуры и панели',
                ),
                const SizedBox(height: TactLayout.sectionGap),
                const TactSectionLabel('Темы клавиатуры'),
                const SizedBox(height: TactLayout.itemGap),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCount,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _themes.length,
                  itemBuilder: (context, i) {
                    final theme = _themes[i];
                    final selected = state.selectedThemeIndex == i;
                    return Semantics(
                      button: true,
                      selected: selected,
                      label: 'Тема ${theme.name}',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => state.setThemeIndex(i),
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            children: [
                              Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  decoration: BoxDecoration(
                                    color: theme.bg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected
                                          ? TactColors.purple
                                          : TactColors.surfaceBorder,
                                      width: selected ? 2 : 0.5,
                                    ),
                                  ),
                                  child: _miniKeys(theme.keyColor),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                theme.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: selected
                                      ? TactColors.purple
                                      : TactColors.textSecondary,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: TactLayout.sectionGap),
                const TactSectionLabel('Фон панели'),
                const SizedBox(height: TactLayout.itemGap),
                SizedBox(
                  height: TactLayout.minTouchTarget,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _panelColors.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final selected = state.selectedPanelColorIndex == i;
                      final color = _panelColors[i];
                      return Semantics(
                        button: true,
                        selected: selected,
                        label: color == null ? 'Градиент' : 'Цвет панели',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => state.setPanelColorIndex(i),
                            customBorder: const CircleBorder(),
                            child: SizedBox(
                              width: TactLayout.minTouchTarget,
                              height: TactLayout.minTouchTarget,
                              child: Center(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color ?? TactColors.purple,
                                    gradient: color == null
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFF8B5CF6),
                                              Color(0xFF3B82F6),
                                            ],
                                          )
                                        : null,
                                    border: Border.all(
                                      color: selected
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: TactLayout.sectionGap),
                const TactSectionLabel('Высота панели'),
                const SizedBox(height: 8),
                Semantics(
                  label: 'Высота панели',
                  child: Row(
                    children: [
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          color: TactColors.textMuted, size: 20),
                      Expanded(
                        child: Slider(
                          value: state.panelHeight,
                          onChanged: state.setPanelHeight,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_up_rounded,
                          color: TactColors.textMuted, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PreviewScreen(state: state),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Предпросмотр'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TactColors.purple,
                      side: const BorderSide(color: TactColors.purple),
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _miniKeys(Color keyColor) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: List.generate(
              4,
              (_) => Expanded(
                child: Container(
                  height: 8,
                  margin: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: keyColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: List.generate(
              4,
              (_) => Expanded(
                child: Container(
                  height: 8,
                  margin: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: keyColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeData {
  const _ThemeData(this.name, this.keyColor, this.bg);
  final String name;
  final Color keyColor;
  final Color bg;
}
