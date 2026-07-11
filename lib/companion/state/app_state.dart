import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/keyboard_settings/keyboard_settings.dart';
import '../../core/keyboard_settings/keyboard_settings_repository.dart';

/// Companion UI state — persists keyboard mode toggles to shared KV.
class CompanionAppState extends ChangeNotifier {
  KeyboardSettingsRepository? _settingsRepo;

  // ── Keyboard modes ────────────────────────────────────────────────
  bool antiMat = true;
  bool antiToxic = true;
  bool fillerWords = true;
  bool textImprovement = true;

  // ── Appearance ────────────────────────────────────────────────────
  int selectedThemeIndex = 2; // Midnight
  int selectedPanelColorIndex = 0;
  double panelHeight = 0.55;

  // ── Settings ──────────────────────────────────────────────────────
  String keyboardLanguage = 'Русский';
  bool vibration = true;
  bool sound = false;
  bool showTips = true;

  // ── Stats (demo values from mockup) ───────────────────────────────
  final int communicationScore = 87;
  final int correctedCount = 124;
  final int softenedCount = 37;
  final int improvedCount = 82;
  final int streakDays = 7;

  final int softenUsed = 12;
  final int softenLimit = 30;
  final int correctUsed = 18;
  final int correctLimit = 50;
  final int improveUsed = 7;
  final int improveLimit = 30;

  Future<void> bindSettingsRepository(KeyboardSettingsRepository repo) async {
    _settingsRepo = repo;
    applyKeyboardSettings(await repo.load());
  }

  void applyKeyboardSettings(KeyboardSettings settings) {
    antiMat = settings.antiMat;
    antiToxic = settings.antiToxic;
    fillerWords = settings.fillerWords;
    textImprovement = settings.textImprovement;
    vibration = settings.vibration;
    sound = settings.sound;
    notifyListeners();
  }

  KeyboardSettings toKeyboardSettings() => KeyboardSettings(
        antiMat: antiMat,
        antiToxic: antiToxic,
        fillerWords: fillerWords,
        textImprovement: textImprovement,
        vibration: vibration,
        sound: sound,
      );

  void _persistKeyboardModes() {
    final repo = _settingsRepo;
    if (repo == null) return;
    unawaited(repo.save(toKeyboardSettings()));
  }

  void setAntiMat(bool v) {
    antiMat = v;
    notifyListeners();
    _persistKeyboardModes();
  }

  void setAntiToxic(bool v) {
    antiToxic = v;
    notifyListeners();
    _persistKeyboardModes();
  }

  void setFillerWords(bool v) {
    fillerWords = v;
    notifyListeners();
    _persistKeyboardModes();
  }

  void setTextImprovement(bool v) {
    textImprovement = v;
    notifyListeners();
    _persistKeyboardModes();
  }

  void setThemeIndex(int i) {
    selectedThemeIndex = i;
    notifyListeners();
  }

  void setPanelColorIndex(int i) {
    selectedPanelColorIndex = i;
    notifyListeners();
  }

  void setPanelHeight(double v) {
    panelHeight = v;
    notifyListeners();
  }

  void setVibration(bool v) {
    vibration = v;
    notifyListeners();
    _persistKeyboardModes();
  }

  void setSound(bool v) {
    sound = v;
    notifyListeners();
    _persistKeyboardModes();
  }

  void setShowTips(bool v) {
    showTips = v;
    notifyListeners();
  }

  void setKeyboardLanguage(String lang) {
    keyboardLanguage = lang;
    notifyListeners();
  }
}
