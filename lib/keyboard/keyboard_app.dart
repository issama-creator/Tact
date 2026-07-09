/// Composition root for the IME suggestion bar.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/bridge/ime_bridge_facade.dart';
import 'actions/actions_engine.dart';
import 'actions/undo_stack.dart';
import 'dictionaries/dictionary_manager.dart';
import 'dictionaries/hotwords_loader.dart';
import 'dictionaries/personal_words_loader.dart';
import 'input/input_pipeline.dart';
import 'intelligence/local_intelligence_engine.dart';
import 'intelligence/undo_tracker.dart';
import 'panel/panel_state.dart';
import 'theme/keyboard_theme.dart';
import 'ui/panel_actions.dart';
import 'ui/suggestion_bar.dart';

/// Wires bridge → pipeline → intelligence engine → actions → suggestion bar.
class KeyboardApp extends StatefulWidget {
  const KeyboardApp({super.key});

  @override
  State<KeyboardApp> createState() => _KeyboardAppState();
}

class _KeyboardAppState extends State<KeyboardApp> {
  late final ImeBridge _bridge;
  late final UndoTracker _undoTracker;
  late final LocalIntelligenceEngine _engine;
  late final InputPipeline _pipeline;
  late final ActionsEngine _actions;
  late final UndoStack _undoStack;
  late final HotwordsLoader _hotwords;
  late final PersonalWordsLoader _personalWords;
  /// Panel-only listenable — updates never call [setState] on the app shell.
  final ValueNotifier<PanelState> _panel =
      ValueNotifier<PanelState>(const PanelIdle());
  Color _backgroundColor = KeyboardTheme.keyboardBackground;

  @override
  void initState() {
    super.initState();
    _bridge = ImeBridge();
    _bridge.onThemeArgb = (argb) => _onTheme(Color(argb & 0xFFFFFFFF));
    _undoTracker = UndoTracker();
    _undoStack = UndoStack();
    _engine = LocalIntelligenceEngine(undo: _undoTracker);
    _hotwords = HotwordsLoader(_engine);
    _personalWords = PersonalWordsLoader(_engine);
    _actions = ActionsEngine(
      bridge: _bridge,
      undoStack: _undoStack,
      undoTracker: _undoTracker,
      onPanel: _onPanel,
    );
    _pipeline = InputPipeline(
      bridge: _bridge,
      engine: _engine,
      onPanel: _onPanel,
      onActionContext: _actions.rememberContext,
      onFieldCleared: _actions.onFieldCleared,
    );
    _bridge.attachHandler();
    _bridge.onInputViewStarted = _reloadUserLexicon;
    _bridge.onFieldFinished = () {
      _pipeline.onFieldFinished();
      _actions.onFieldCleared();
    };
    _pipeline.start();
    unawaited(_bridge.signalReady());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await DictionaryManager.open();
      _engine.reloadDictionaries();
      await _reloadUserLexicon();
    });
  }

  Future<void> _reloadUserLexicon() async {
    await _reloadHotwords();
    await _personalWords.reload();
  }

  Future<void> _reloadHotwords() => _hotwords.reload();

  @override
  void dispose() {
    _panel.dispose();
    _actions.dispose();
    _pipeline.dispose();
    _bridge.dispose();
    super.dispose();
  }

  void _onPanel(PanelState state) {
    if (!mounted) return;
    _pipeline.adoptPanel(state);
    if (panelModesEqual(_panel.value, state)) return;
    if (kDebugMode) {
      debugPrint('[TACT UI] render panel=${state.runtimeType}');
    }
    _panel.value = state;
    unawaited(_bridge.requestRepaint());
  }

  void _onTheme(Color color) {
    if (!mounted) return;
    if (_backgroundColor.value == color.value) return;
    setState(() => _backgroundColor = color);
    unawaited(_bridge.requestRepaint());
  }

  Future<void> _onPanelTap(PanelAction action) async {
    switch (action) {
      case PanelActionUndo():
        await _actions.undo();
      case PanelActionFixSpell(:final panel, :final candidate):
        await _actions.fixSpell(panel, candidate: candidate);
      case PanelActionRemoveMat(:final panel):
        await _actions.removeMat(panel);
      case PanelActionSoftenToxic(:final panel):
        await _actions.softenToxic(panel);
      case PanelActionImprove():
        await _actions.improve();
      case PanelActionShortcut(:final expansion):
        await _actions.expandShortcut(expansion);
      case PanelActionSuggestion(:final word):
        await _actions.insertSuggestion(word);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shell is stable on panel changes — only [ListenableBuilder] subtree rebuilds.
    return ColoredBox(
      key: const Key('keyboard_app_shell'),
      color: _backgroundColor,
      child: SizedBox.expand(
        child: ListenableBuilder(
          listenable: _panel,
          builder: (context, _) {
            return RepaintBoundary(
              child: SuggestionBar(
                panel: _panel.value,
                backgroundColor: _backgroundColor,
                onAction: _onPanelTap,
              ),
            );
          },
        ),
      ),
    );
  }
}
