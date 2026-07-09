import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tact/keyboard/input/text_context.dart';
import 'package:tact/keyboard/panel/panel_state.dart';
import 'package:tact/keyboard/ui/suggestion_bar.dart';

import 'package:tact/keyboard/theme/keyboard_theme.dart';

Future<void> _pumpBar(
  WidgetTester tester, {
  required PanelState panel,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 38,
          child: SuggestionBar(
            panel: panel,
            backgroundColor: KeyboardTheme.panelBarBackground,
            onAction: (_) async {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('PanelIdle renders empty strip', (tester) async {
    await _pumpBar(tester, panel: const PanelIdle());
    expect(find.text('Обнаружен мат'), findsNothing);
    expect(find.textContaining('→'), findsNothing);
    expect(find.text('Tact'), findsNothing);
  });

  testWidgets('PanelMat renders mat status strip', (tester) async {
    await _pumpBar(
      tester,
      panel: const PanelMat(word: 'хуй', range: EditRange(0, 3)),
    );
    expect(find.text('Обнаружен мат'), findsOneWidget);
    expect(find.text('х**'), findsOneWidget);
    expect(find.text('Убрать →'), findsOneWidget);
    expect(find.text('хуй'), findsNothing);
  });

  testWidgets('PanelMat compacts message on narrow screens', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 38,
            child: SuggestionBar(
              panel: const PanelMat(word: 'хуй', range: EditRange(0, 3)),
              backgroundColor: KeyboardTheme.panelBarBackground,
              onAction: (_) async {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.bySemanticsLabel('Обнаружен мат · х**'), findsOneWidget);
    expect(find.text('Убрать →'), findsOneWidget);
  });

  testWidgets('PanelShortcut renders expansion chips', (tester) async {
    await _pumpBar(
      tester,
      panel: const PanelShortcut(
        trigger: 'др',
        expansions: ['Добрый день', 'Доброе утро'],
        range: EditRange(0, 2),
      ),
    );
    expect(find.text('др → Добрый день'), findsOneWidget);
    expect(find.text('др → Доброе утро'), findsOneWidget);
  });

  testWidgets('PanelSpell renders spell strip and candidates', (tester) async {
    await _pumpBar(
      tester,
      panel: const PanelSpell(
        word: 'helo',
        candidates: ['hello', 'help'],
        range: EditRange(0, 4),
      ),
    );
    expect(find.text('helo'), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
    expect(find.text('help'), findsOneWidget);
  });

  testWidgets('PanelSuggestions renders next-word chips', (tester) async {
    await _pumpBar(
      tester,
      panel: const PanelSuggestions(
        words: ['мир', 'друг', 'всем'],
      ),
    );
    expect(find.text('мир'), findsOneWidget);
    expect(find.text('друг'), findsOneWidget);
    expect(find.text('всем'), findsOneWidget);
  });

  testWidgets('panel state swap rebuilds visible content', (tester) async {
    await _pumpBar(
      tester,
      panel: const PanelMat(word: 'хуй', range: EditRange(0, 3)),
    );
    expect(find.text('Обнаружен мат'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 38,
            child: SuggestionBar(
              panel: const PanelShortcut(
                trigger: 'др',
                expansions: ['Добрый день'],
                range: EditRange(0, 2),
              ),
              backgroundColor: KeyboardTheme.panelBarBackground,
              onAction: (_) async {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Обнаружен мат'), findsNothing);
    expect(find.text('др → Добрый день'), findsOneWidget);
  });
}
