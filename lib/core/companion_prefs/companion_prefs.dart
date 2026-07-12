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
    this.communicationScore = 87,
    this.matBlockedCount = 48,
    this.toxicSoftenedCount = 23,
    this.aiAssistCount = 31,
    this.cleanStreakDays = 12,
    this.cleanRecordDays = 28,
    this.orthographyUsed = 3,
    this.orthographyLimit = 10,
    this.punctuationUsed = 5,
    this.punctuationLimit = 10,
    this.improveTextUsed = 2,
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
      communicationScore: i('communicationScore', 87).clamp(0, 100),
      matBlockedCount: i('matBlockedCount', 48).clamp(0, 999999),
      toxicSoftenedCount: i('toxicSoftenedCount', 23).clamp(0, 999999),
      aiAssistCount: i('aiAssistCount', 31).clamp(0, 999999),
      cleanStreakDays: i('cleanStreakDays', 12).clamp(0, 99999),
      cleanRecordDays: i('cleanRecordDays', 28).clamp(0, 99999),
      orthographyUsed: i('orthographyUsed', 3).clamp(0, 9999),
      orthographyLimit: i('orthographyLimit', 10).clamp(1, 9999),
      punctuationUsed: i('punctuationUsed', 5).clamp(0, 9999),
      punctuationLimit: i('punctuationLimit', 10).clamp(1, 9999),
      improveTextUsed: i('improveTextUsed', 2).clamp(0, 9999),
      improveTextLimit: i('improveTextLimit', 10).clamp(1, 9999),
    );
  }
}
