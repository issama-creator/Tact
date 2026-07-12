import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/companion_prefs/companion_prefs.dart';
import '../../core/companion_prefs/companion_prefs_repository.dart';
import '../../core/hotwords/hotwords_repository.dart';
import '../../core/keyboard_settings/keyboard_settings.dart';
import '../../core/keyboard_settings/keyboard_settings_repository.dart';
import '../appearance/keyboard_theme.dart';

/// Companion UI state — loads/saves modes, theme, stats and limits locally.
class CompanionAppState extends ChangeNotifier {
  KeyboardSettingsRepository? _settingsRepo;
  CompanionPrefsRepository? _prefsRepo;

  // ── Keyboard modes (also in KeyboardSettings for IME) ─────────────
  bool antiMat = true;
  bool antiToxic = true;
  bool aiAssistant = true;
  double aiIntensity = 0.55;
  bool matVibration = true;

  // ── Appearance ────────────────────────────────────────────────────
  int selectedThemeIndex = 2;
  int selectedPanelColorIndex = 0;
  double panelHeight = 0.55;

  // ── Settings ──────────────────────────────────────────────────────
  String keyboardLanguage = 'Русский';
  bool vibration = true;
  bool sound = false;
  bool showTips = true;

  // ── Dashboard stats / limits ──────────────────────────────────────
  int communicationScore = 87;
  int matBlockedCount = 48;
  int toxicSoftenedCount = 23;
  int aiAssistCount = 31;
  int cleanStreakDays = 12;
  int cleanRecordDays = 28;

  int hotwordsCount = 0;

  int orthographyUsed = 3;
  int orthographyLimit = 10;
  int punctuationUsed = 5;
  int punctuationLimit = 10;
  int improveTextUsed = 2;
  int improveTextLimit = 10;

  /// Opens shared stores and hydrates UI from disk.
  Future<void> bindRepositories({
    required KeyboardSettingsRepository settingsRepo,
    required CompanionPrefsRepository prefsRepo,
  }) async {
    _settingsRepo = settingsRepo;
    _prefsRepo = prefsRepo;
    applyKeyboardSettings(await settingsRepo.load());
    applyCompanionPrefs(await prefsRepo.load());
    // Seed disk so IME can read theme even before first manual change.
    _persistCompanionPrefs();
    _persistKeyboardModes();
    await refreshHotwordsCount();
  }

  /// Backward-compatible entry used by older call sites.
  Future<void> bindSettingsRepository(KeyboardSettingsRepository repo) async {
    final prefs = await CompanionPrefsRepository.open();
    await bindRepositories(settingsRepo: repo, prefsRepo: prefs);
  }

  Future<void> refreshHotwordsCount() async {
    try {
      await HotwordsRepository.open();
      final all = await HotwordsRepository.instance.loadAll();
      hotwordsCount = all.length;
      notifyListeners();
    } catch (_) {}
  }

  void applyKeyboardSettings(KeyboardSettings settings) {
    antiMat = settings.antiMat;
    antiToxic = settings.antiToxic;
    aiAssistant = settings.aiAssistant;
    aiIntensity = settings.aiIntensity;
    matVibration = settings.matVibration;
    vibration = settings.vibration;
    sound = settings.sound;
    // Prefer companion prefs for theme; fall back to settings if prefs missing.
    if (_prefsRepo == null) {
      selectedThemeIndex =
          settings.themeIndex.clamp(0, KeyboardThemeStyle.all.length - 1);
    }
    notifyListeners();
  }

  void applyCompanionPrefs(CompanionPrefs prefs) {
    selectedThemeIndex =
        prefs.selectedThemeIndex.clamp(0, KeyboardThemeStyle.all.length - 1);
    selectedPanelColorIndex = prefs.selectedPanelColorIndex;
    panelHeight = prefs.panelHeight;
    keyboardLanguage = prefs.keyboardLanguage;
    showTips = prefs.showTips;
    communicationScore = prefs.communicationScore;
    matBlockedCount = prefs.matBlockedCount;
    toxicSoftenedCount = prefs.toxicSoftenedCount;
    aiAssistCount = prefs.aiAssistCount;
    cleanStreakDays = prefs.cleanStreakDays;
    cleanRecordDays = prefs.cleanRecordDays;
    orthographyUsed = prefs.orthographyUsed;
    orthographyLimit = prefs.orthographyLimit;
    punctuationUsed = prefs.punctuationUsed;
    punctuationLimit = prefs.punctuationLimit;
    improveTextUsed = prefs.improveTextUsed;
    improveTextLimit = prefs.improveTextLimit;
    notifyListeners();
  }

  KeyboardSettings toKeyboardSettings() => KeyboardSettings(
        antiMat: antiMat,
        antiToxic: antiToxic,
        aiAssistant: aiAssistant,
        aiIntensity: aiIntensity,
        matVibration: matVibration,
        vibration: vibration,
        sound: sound,
        themeIndex: selectedThemeIndex,
      );

  CompanionPrefs toCompanionPrefs() => CompanionPrefs(
        selectedThemeIndex: selectedThemeIndex,
        selectedPanelColorIndex: selectedPanelColorIndex,
        panelHeight: panelHeight,
        keyboardLanguage: keyboardLanguage,
        showTips: showTips,
        communicationScore: communicationScore,
        matBlockedCount: matBlockedCount,
        toxicSoftenedCount: toxicSoftenedCount,
        aiAssistCount: aiAssistCount,
        cleanStreakDays: cleanStreakDays,
        cleanRecordDays: cleanRecordDays,
        orthographyUsed: orthographyUsed,
        orthographyLimit: orthographyLimit,
        punctuationUsed: punctuationUsed,
        punctuationLimit: punctuationLimit,
        improveTextUsed: improveTextUsed,
        improveTextLimit: improveTextLimit,
      );

  void _persistKeyboardModes() {
    final repo = _settingsRepo;
    if (repo == null) return;
    unawaited(repo.save(toKeyboardSettings()));
  }

  void _persistCompanionPrefs() {
    final repo = _prefsRepo;
    if (repo == null) return;
    unawaited(repo.save(toCompanionPrefs()));
  }

  void setAntiMat(bool v) {
    antiMat = v;
    notifyListeners();
    _persistKeyboardModes();
  }

  void setMatVibration(bool v) {
    matVibration = v;
    notifyListeners();
    _persistKeyboardModes();
  }

  void setAntiToxic(bool v) {
    antiToxic = v;
    notifyListeners();
    _persistKeyboardModes();
  }

  void setAiAssistant(bool v) {
    aiAssistant = v;
    notifyListeners();
    _persistKeyboardModes();
  }

  void setAiIntensity(double v) {
    aiIntensity = v.clamp(0.0, 1.0);
    notifyListeners();
    _persistKeyboardModes();
  }

  void setThemeIndex(int i) {
    selectedThemeIndex = i.clamp(0, KeyboardThemeStyle.all.length - 1);
    notifyListeners();
    _persistCompanionPrefs();
    // Also write themeIndex into keyboard_settings for native IME readers.
    _persistKeyboardModes();
  }

  void setPanelColorIndex(int i) {
    selectedPanelColorIndex = i;
    notifyListeners();
    _persistCompanionPrefs();
  }

  void setPanelHeight(double v) {
    panelHeight = v;
    notifyListeners();
    _persistCompanionPrefs();
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
    _persistCompanionPrefs();
  }

  void setKeyboardLanguage(String lang) {
    keyboardLanguage = lang;
    notifyListeners();
    _persistCompanionPrefs();
  }

  /// Persist dashboard counters after IME / local updates.
  void updateStats({
    int? communicationScore,
    int? matBlockedCount,
    int? toxicSoftenedCount,
    int? aiAssistCount,
    int? cleanStreakDays,
    int? cleanRecordDays,
    int? orthographyUsed,
    int? punctuationUsed,
    int? improveTextUsed,
  }) {
    if (communicationScore != null) {
      this.communicationScore = communicationScore.clamp(0, 100);
    }
    if (matBlockedCount != null) this.matBlockedCount = matBlockedCount;
    if (toxicSoftenedCount != null) {
      this.toxicSoftenedCount = toxicSoftenedCount;
    }
    if (aiAssistCount != null) this.aiAssistCount = aiAssistCount;
    if (cleanStreakDays != null) this.cleanStreakDays = cleanStreakDays;
    if (cleanRecordDays != null) this.cleanRecordDays = cleanRecordDays;
    if (orthographyUsed != null) this.orthographyUsed = orthographyUsed;
    if (punctuationUsed != null) this.punctuationUsed = punctuationUsed;
    if (improveTextUsed != null) this.improveTextUsed = improveTextUsed;
    notifyListeners();
    _persistCompanionPrefs();
  }
}
