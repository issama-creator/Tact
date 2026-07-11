/// Composition root for the IME suggestion bar.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/bridge/ime_bridge_facade.dart';
import '../../core/keyboard_settings/keyboard_settings.dart';
import '../../core/keyboard_settings/keyboard_settings_repository.dart';
import 'actions/actions_engine.dart';
import 'actions/undo_stack.dart';
import 'dictionaries/dictionary_manager.dart';
import 'dictionaries/hotwords_loader.dart';
import 'dictionaries/keyboard_settings_loader.dart';
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
  late final KeyboardSettingsLoader _keyboardSettings;
  Timer? _lexiconSyncTimer;
  Timer? _repaintDebounce;
  Future<void>? _reloadInFlight;
  var _inputViewActive = false;
  var _lastVibration = true;
  var _lastSound = false;
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
    _keyboardSettings = KeyboardSettingsLoader(_engine);
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
      onMatBlock: _actions.removeMat,
    );
    _bridge.attachHandler();
    _bridge.onInputViewStarted = () {
      _inputViewActive = true;
      _ensureLexiconSyncTimer();
      unawaited(_reloadUserLexicon());
    };
    _bridge.onFieldFinished = () {
      _inputViewActive = false;
      _lexiconSyncTimer?.cancel();
      _lexiconSyncTimer = null;
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

  void _ensureLexiconSyncTimer() {
    if (_lexiconSyncTimer != null) return;
    // Companion writes from another engine — light poll only while typing.
    _lexiconSyncTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        if (!_inputViewActive) return;
        unawaited(_reloadUserLexicon());
      },
    );
  }

  Future<void> _reloadUserLexicon() {
    final existing = _reloadInFlight;
    if (existing != null) return existing;
    final future = _reloadUserLexiconBody();
    _reloadInFlight = future;
    return future.whenComplete(() {
      if (identical(_reloadInFlight, future)) _reloadInFlight = null;
    });
  }

  Future<void> _reloadUserLexiconBody() async {
    await _keyboardSettings.ensureOpen();
    await _hotwords.ensureOpen();
    await _personalWords.ensureOpen();
    // One SharedPreferences.reload for the whole batch.
    await KeyboardSettingsRepository.instance.refresh();
    final settings = await _keyboardSettings.reloadPeek();
    await _hotwords.reloadPeek();
    await _personalWords.reloadPeek();
    if (settings != null) {
      await _applyFeedback(settings);
    }
  }

  Future<void> _applyFeedback(KeyboardSettings settings) async {
    if (settings.vibration == _lastVibration && settings.sound == _lastSound) {
      return;
    }
    _lastVibration = settings.vibration;
    _lastSound = settings.sound;
    await _bridge.setFeedback(
      vibration: settings.vibration,
      sound: settings.sound,
    );
  }

  @override
  void dispose() {
    _lexiconSyncTimer?.cancel();
    _repaintDebounce?.cancel();
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
    _scheduleRepaint();
  }

  void _scheduleRepaint() {
    _repaintDebounce?.cancel();
    _repaintDebounce = Timer(const Duration(milliseconds: 16), () {
      unawaited(_bridge.requestRepaint());
    });
  }

  void _onTheme(Color color) {
    if (!mounted) return;
    if (_backgroundColor.value == color.value) return;
    setState(() => _backgroundColor = color);
    _scheduleRepaint();
  }

  Future<void> _onPanelTap(PanelAction action) async {
    switch (action) {
      case PanelActionUndo():
        await _actions.undo();
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
                backgroundColor: KeyboardTheme.panelBarBackground,
                onAction: _onPanelTap,
              ),
            );
          },
        ),
      ),
    );
  }
}
