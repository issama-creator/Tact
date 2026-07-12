import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/companion_prefs/companion_prefs.dart';
import '../../core/companion_prefs/companion_prefs_repository.dart';
import '../../core/hotwords/hotwords_repository.dart';
import '../../core/keyboard_settings/keyboard_settings.dart';
import '../../core/keyboard_settings/keyboard_settings_repository.dart';
import '../appearance/keyboard_theme.dart';
import '../platform/ime_platform.dart';

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
  int communicationScore = 100;
  int matBlockedCount = 0;
  int toxicSoftenedCount = 0;
  int aiAssistCount = 0;
  int cleanStreakDays = 0;
  int cleanRecordDays = 0;

  int hotwordsCount = 0;

  int orthographyUsed = 0;
  int orthographyLimit = 10;
  int punctuationUsed = 0;
  int punctuationLimit = 10;
  int improveTextUsed = 0;
  int improveTextLimit = 10;

  Future<void>? _hydrateInFlight;

  /// Single entry for disk → memory sync (dedupes parallel callers).
  Future<void> hydrate({bool forceRefresh = false}) {
    if (!forceRefresh) {
      final existing = _hydrateInFlight;
      if (existing != null) return existing;
    }
    final future = _hydrateBody(forceRefresh: forceRefresh);
    _hydrateInFlight = future;
    return future.whenComplete(() {
      if (identical(_hydrateInFlight, future)) _hydrateInFlight = null;
    });
  }

  /// Opens shared stores and hydrates UI from disk.
  Future<void> bindRepositories({
    required KeyboardSettingsRepository settingsRepo,
    required CompanionPrefsRepository prefsRepo,
  }) async {
    _settingsRepo = settingsRepo;
    _prefsRepo = prefsRepo;
    await hydrate();
  }

  Future<void> _hydrateBody({required bool forceRefresh}) async {
    var settingsRepo = _settingsRepo;
    var prefsRepo = _prefsRepo;
    if (settingsRepo == null || prefsRepo == null) {
      settingsRepo = await KeyboardSettingsRepository.open();
      prefsRepo = await CompanionPrefsRepository.open();
      _settingsRepo = settingsRepo;
      _prefsRepo = prefsRepo;
    }

    if (forceRefresh) {
      await settingsRepo.refresh();
      await prefsRepo.refresh();
    }

    final settings = await settingsRepo.load(refreshFromDisk: forceRefresh);
    final raw = await prefsRepo.peekRaw();

    if (raw == null || raw.isEmpty) {
      applyKeyboardSettings(settings, notify: false);
      applyCompanionPrefs(CompanionPrefs.defaults, notify: false);
      await prefsRepo.save(toCompanionPrefs());
      await settingsRepo.save(toKeyboardSettings());
    } else {
      final onDisk = CompanionPrefsRepository.parseRawUnmigrated(raw);
      final prefs = onDisk.withoutLegacyDemoSeed();
      applyKeyboardSettings(settings, notify: false);
      applyCompanionPrefs(prefs, notify: false);
      if (onDisk.isLegacyDemoSeed) {
        await prefsRepo.save(toCompanionPrefs());
      }
    }

    await refreshHotwordsCount(notify: false);
    notifyListeners();
  }

  /// Re-reads companion + keyboard prefs after external writes or app resume.
  Future<void> reloadFromDisk({bool notify = true}) =>
      hydrate(forceRefresh: true);

  /// Backward-compatible entry used by older call sites.
  Future<void> bindSettingsRepository(KeyboardSettingsRepository repo) async {
    final prefs = await CompanionPrefsRepository.open();
    await bindRepositories(settingsRepo: repo, prefsRepo: prefs);
  }

  Future<void> refreshHotwordsCount({bool notify = true}) async {
    try {
      await HotwordsRepository.open();
      final all = await HotwordsRepository.instance.loadAll();
      hotwordsCount = all.length;
      if (notify) notifyListeners();
    } catch (_) {}
  }

  void applyKeyboardSettings(KeyboardSettings settings, {bool notify = true}) {
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
    if (notify) notifyListeners();
  }

  void applyCompanionPrefs(CompanionPrefs prefs, {bool notify = true}) {
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
    if (notify) notifyListeners();
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
    unawaited(_persistThemeAndNotifyIme());
  }

  Future<void> _persistThemeAndNotifyIme() async {
    final prefs = _prefsRepo;
    final settings = _settingsRepo;
    if (prefs != null) {
      await prefs.save(toCompanionPrefs());
    }
    if (settings != null) {
      await settings.save(toKeyboardSettings());
    }
    await ImePlatform.notifyThemeChanged();
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

  /// Wipes dashboard counters so the user can track fresh activity.
  Future<void> clearAllStats() async {
    applyCompanionPrefs(toCompanionPrefs().withClearedStats(), notify: false);
    final repo = _prefsRepo;
    if (repo != null) {
      await repo.save(toCompanionPrefs());
    }
    notifyListeners();
  }
}
