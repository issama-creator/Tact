import 'package:flutter/material.dart';
import '../preview/preview_screen.dart';
import '../state/app_state.dart';
import '../theme/tact_theme.dart';
import '../widgets/tact_widgets.dart';
import 'keyboard_theme.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key, required this.state});

  final CompanionAppState state;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossCount = width >= 720 ? 4 : width >= 480 ? 3 : 2;
    final themes = KeyboardThemeStyle.all;

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
                  subtitle: 'Настройте внешний вид клавиатуры',
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
                    childAspectRatio: 0.92,
                  ),
                  itemCount: themes.length,
                  itemBuilder: (context, i) {
                    final theme = themes[i];
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
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected
                                          ? TactColors.purple
                                          : TactColors.surfaceBorder,
                                      width: selected ? 2 : 0.5,
                                    ),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: TactColors.purple
                                                  .withValues(alpha: 0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      selected ? 10 : 11.5,
                                    ),
                                    child: ColoredBox(
                                      color: theme.background,
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: SizedBox(
                                            width: 168,
                                            child: MiniKeyboardPreview(
                                              style: theme,
                                              compact: true,
                                              showPanel: false,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
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
}
