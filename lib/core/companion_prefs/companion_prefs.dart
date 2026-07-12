/// Companion-only preferences and dashboard stats — local JSON in SharedPreferences.
library;

/// Appearance, tips, language, limits and protection counters for the companion UI.
final class CompanionPrefs {
  const CompanionPrefs({
    this.selectedThemeIndex = 2,
    this.selectedPanelColorIndex = 0,
    this.panelHeight = 0.55,
    this.keyboardLanguage = 'Русский',
    this.showTips = true,
    this.communicationScore = 100,
    this.matBlockedCount = 0,
    this.toxicSoftenedCount = 0,
    this.aiAssistCount = 0,
    this.cleanStreakDays = 0,
    this.cleanRecordDays = 0,
    this.orthographyUsed = 0,
    this.orthographyLimit = 10,
    this.punctuationUsed = 0,
    this.punctuationLimit = 10,
    this.improveTextUsed = 0,
    this.improveTextLimit = 10,
  });

  static const defaults = CompanionPrefs();

  final int selectedThemeIndex;
  final int selectedPanelColorIndex;
  final double panelHeight;
  final String keyboardLanguage;
  final bool showTips;

  final int communicationScore;
  final int matBlockedCount;
  final int toxicSoftenedCount;
  final int aiAssistCount;
  final int cleanStreakDays;
  final int cleanRecordDays;

  final int orthographyUsed;
  final int orthographyLimit;
  final int punctuationUsed;
  final int punctuationLimit;
  final int improveTextUsed;
  final int improveTextLimit;

  CompanionPrefs copyWith({
    int? selectedThemeIndex,
    int? selectedPanelColorIndex,
    double? panelHeight,
    String? keyboardLanguage,
    bool? showTips,
    int? communicationScore,
    int? matBlockedCount,
    int? toxicSoftenedCount,
    int? aiAssistCount,
    int? cleanStreakDays,
    int? cleanRecordDays,
    int? orthographyUsed,
    int? orthographyLimit,
    int? punctuationUsed,
    int? punctuationLimit,
    int? improveTextUsed,
    int? improveTextLimit,
  }) =>
      CompanionPrefs(
        selectedThemeIndex: selectedThemeIndex ?? this.selectedThemeIndex,
        selectedPanelColorIndex:
            selectedPanelColorIndex ?? this.selectedPanelColorIndex,
        panelHeight: panelHeight ?? this.panelHeight,
        keyboardLanguage: keyboardLanguage ?? this.keyboardLanguage,
        showTips: showTips ?? this.showTips,
        communicationScore: communicationScore ?? this.communicationScore,
        matBlockedCount: matBlockedCount ?? this.matBlockedCount,
        toxicSoftenedCount: toxicSoftenedCount ?? this.toxicSoftenedCount,
        aiAssistCount: aiAssistCount ?? this.aiAssistCount,
        cleanStreakDays: cleanStreakDays ?? this.cleanStreakDays,
        cleanRecordDays: cleanRecordDays ?? this.cleanRecordDays,
        orthographyUsed: orthographyUsed ?? this.orthographyUsed,
        orthographyLimit: orthographyLimit ?? this.orthographyLimit,
        punctuationUsed: punctuationUsed ?? this.punctuationUsed,
        punctuationLimit: punctuationLimit ?? this.punctuationLimit,
        improveTextUsed: improveTextUsed ?? this.improveTextUsed,
        improveTextLimit: improveTextLimit ?? this.improveTextLimit,
      );

  /// Resets dashboard counters; keeps theme, limits and other prefs.
  CompanionPrefs withClearedStats() => copyWith(
        communicationScore: 100,
        matBlockedCount: 0,
        toxicSoftenedCount: 0,
        aiAssistCount: 0,
        cleanStreakDays: 0,
        cleanRecordDays: 0,
        orthographyUsed: 0,
        punctuationUsed: 0,
        improveTextUsed: 0,
      );

  /// Old companion builds seeded these demo counters on first save.
  static const legacyDemoSeed = CompanionPrefs(
    communicationScore: 87,
    matBlockedCount: 48,
    toxicSoftenedCount: 23,
    aiAssistCount: 31,
    cleanStreakDays: 12,
    cleanRecordDays: 28,
    orthographyUsed: 3,
    punctuationUsed: 5,
    improveTextUsed: 2,
  );

  bool get isLegacyDemoSeed =>
      communicationScore == legacyDemoSeed.communicationScore &&
      matBlockedCount == legacyDemoSeed.matBlockedCount &&
      toxicSoftenedCount == legacyDemoSeed.toxicSoftenedCount &&
      aiAssistCount == legacyDemoSeed.aiAssistCount &&
      cleanStreakDays == legacyDemoSeed.cleanStreakDays &&
      cleanRecordDays == legacyDemoSeed.cleanRecordDays &&
      orthographyUsed == legacyDemoSeed.orthographyUsed &&
      punctuationUsed == legacyDemoSeed.punctuationUsed &&
      improveTextUsed == legacyDemoSeed.improveTextUsed;

  /// Drops the baked-in demo dashboard so real usage can accumulate.
  CompanionPrefs withoutLegacyDemoSeed() =>
      isLegacyDemoSeed ? withClearedStats() : this;

  Map<String, dynamic> toJson() => {
        'selectedThemeIndex': selectedThemeIndex,
        'selectedPanelColorIndex': selectedPanelColorIndex,
        'panelHeight': panelHeight,
        'keyboardLanguage': keyboardLanguage,
        'showTips': showTips,
        'communicationScore': communicationScore,
        'matBlockedCount': matBlockedCount,
        'toxicSoftenedCount': toxicSoftenedCount,
        'aiAssistCount': aiAssistCount,
        'cleanStreakDays': cleanStreakDays,
        'cleanRecordDays': cleanRecordDays,
        'orthographyUsed': orthographyUsed,
        'orthographyLimit': orthographyLimit,
        'punctuationUsed': punctuationUsed,
        'punctuationLimit': punctuationLimit,
        'improveTextUsed': improveTextUsed,
        'improveTextLimit': improveTextLimit,
      };

  factory CompanionPrefs.fromJson(Map<String, dynamic> json) {
    int i(String key, int fallback) =>
        (json[key] as num?)?.toInt() ?? fallback;
    double d(String key, double fallback) =>
        (json[key] as num?)?.toDouble() ?? fallback;

    return CompanionPrefs(
      selectedThemeIndex: i('selectedThemeIndex', 2),
      selectedPanelColorIndex: i('selectedPanelColorIndex', 0),
      panelHeight: d('panelHeight', 0.55).clamp(0.0, 1.0),
      keyboardLanguage: json['keyboardLanguage'] as String? ?? 'Русский',
      showTips: json['showTips'] as bool? ?? true,
      communicationScore: i('communicationScore', 100).clamp(0, 100),
      matBlockedCount: i('matBlockedCount', 0).clamp(0, 999999),
      toxicSoftenedCount: i('toxicSoftenedCount', 0).clamp(0, 999999),
      aiAssistCount: i('aiAssistCount', 0).clamp(0, 999999),
      cleanStreakDays: i('cleanStreakDays', 0).clamp(0, 99999),
      cleanRecordDays: i('cleanRecordDays', 0).clamp(0, 99999),
      orthographyUsed: i('orthographyUsed', 0).clamp(0, 9999),
      orthographyLimit: i('orthographyLimit', 10).clamp(1, 9999),
      punctuationUsed: i('punctuationUsed', 0).clamp(0, 9999),
      punctuationLimit: i('punctuationLimit', 10).clamp(1, 9999),
      improveTextUsed: i('improveTextUsed', 0).clamp(0, 9999),
      improveTextLimit: i('improveTextLimit', 10).clamp(1, 9999),
    );
  }
}
