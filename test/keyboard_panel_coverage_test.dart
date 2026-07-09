import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tact/keyboard/input/text_context.dart';
import 'package:tact/keyboard/keyboard_app.dart';
import 'package:tact/keyboard/panel/panel_state.dart';
import 'package:tact/keyboard/theme/keyboard_theme.dart';
import 'package:tact/keyboard/ui/suggestion_bar.dart';

/// Mirrors native [KeyboardRootView]: suggestion slot + key grid below.
class _ImeKeyboardChrome extends StatelessWidget {
  const _ImeKeyboardChrome({
    required this.panelSlot,
    this.barHeight = 38,
    this.keyAreaHeight = 200,
    this.width = 400,
  });

  final Widget panelSlot;
  final double barHeight;
  final double keyAreaHeight;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: KeyboardTheme.keyboardBackground,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              key: const Key('panel_slot'),
              width: width,
              height: barHeight,
              child: panelSlot,
            ),
            SizedBox(
              key: const Key('key_grid'),
              width: width,
              height: keyAreaHeight,
              child: const ColoredBox(
                color: KeyboardTheme.keyboardBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _pumpInChrome(
  WidgetTester tester, {
  required PanelState panel,
  double barHeight = 38,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: _ImeKeyboardChrome(
        barHeight: barHeight,
        panelSlot: SuggestionBar(
          panel: panel,
          backgroundColor: KeyboardTheme.panelBarBackground,
          onAction: (_) async {},
        ),
      ),
    ),
  );
  await tester.pump();
}

Rect _rect(WidgetTester tester, Finder finder) =>
    tester.getRect(finder);

void main() {
  group('panel fills suggestion slot above key grid', () {
    for (final panel in <PanelState>[
      const PanelIdle(),
      const PanelMat(word: 'хуй', range: EditRange(0, 3)),
      const PanelShortcut(
        trigger: 'др',
        expansions: ['Добрый день'],
        range: EditRange(0, 2),
      ),
      const PanelSpell(
        word: 'helo',
        candidates: ['hello', 'help'],
        range: EditRange(0, 4),
      ),
      const PanelSuggestions(words: ['мир', 'друг']),
    ]) {
      testWidgets('${panel.runtimeType} covers full bar', (tester) async {
        await _pumpInChrome(tester, panel: panel);
        final slot = _rect(tester, find.byKey(const Key('panel_slot')));
        final root = _rect(tester, find.byKey(const Key('suggestion_bar_root')));
        expect(root.size, slot.size);
        expect(root.topLeft, slot.topLeft);
      });
    }
  });

  testWidgets('idle panel uses soft strip background', (tester) async {
    await _pumpInChrome(tester, panel: const PanelIdle());
    final box = tester.widget<ColoredBox>(
      find.byKey(const Key('suggestion_bar_root')),
    );
    expect(box.color, KeyboardTheme.panelBarBackground);
  });

  testWidgets('idle panel paints keyboard bg over entire slot', (tester) async {
    await _pumpInChrome(tester, panel: const PanelIdle());
    final slot = _rect(tester, find.byKey(const Key('panel_slot')));
    expect(_rect(tester, find.byKey(const Key('suggestion_bar_root'))), slot);
  });

  testWidgets('panel does not shrink below native bar height', (tester) async {
    await _pumpInChrome(tester, panel: const PanelMat(
      word: 'хуй',
      range: EditRange(0, 3),
    ));
    expect(
      _rect(tester, find.byKey(const Key('suggestion_bar_root'))).height,
      38,
    );
  });

  testWidgets('landscape bar height still fully covered', (tester) async {
    await _pumpInChrome(
      tester,
      panel: const PanelIdle(),
      barHeight: 32,
    );
    final slot = _rect(tester, find.byKey(const Key('panel_slot')));
    expect(_rect(tester, find.byKey(const Key('suggestion_bar_root'))), slot);
  });

  group('KeyboardApp in IME constraints', () {
    const channel = MethodChannel('com.example.tact.ime/bridge');

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => null);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    Future<void> pumpKeyboardApp(WidgetTester tester, {double height = 52}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            key: const Key('flutter_view_slot'),
            width: 400,
            height: height,
            child: const KeyboardApp(),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('fills FlutterView slot edge-to-edge', (tester) async {
      await pumpKeyboardApp(tester);
      final slot = _rect(tester, find.byKey(const Key('flutter_view_slot')));
      final app = _rect(tester, find.byType(KeyboardApp));
      expect(app.size, slot.size);
    });

    testWidgets('default background matches keyboard theme', (tester) async {
      await pumpKeyboardApp(tester);
      final shell = tester.widget<ColoredBox>(
        find.byKey(const Key('keyboard_app_shell')),
      );
      expect(shell.color, KeyboardTheme.keyboardBackground);
    });

    testWidgets('setTheme from native updates panel background', (tester) async {
      await pumpKeyboardApp(tester);
      const newBg = Color(0xFF222228);
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(
          const MethodCall('setTheme', {'background': 0xFF222228}),
        ),
        (_) {},
      );
      await tester.pump();

      final shell = tester.widget<ColoredBox>(
        find.byKey(const Key('keyboard_app_shell')),
      );
      expect(shell.color, newBg);
    });
  });
}
