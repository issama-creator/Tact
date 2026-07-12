/// User toggles for keyboard intelligence — shared by companion and IME.
library;

/// Mode switches from the companion «Клавиатура» / «Настройки» screens.
final class KeyboardSettings {
  const KeyboardSettings({
    this.antiMat = true,
    this.antiToxic = true,
    this.fillerWords = false,
    this.textImprovement = false,
    this.aiAssistant = true,
    this.aiIntensity = 0.55,
    this.vibration = true,
    this.matVibration = true,
    this.sound = false,
  });

  static const defaults = KeyboardSettings();

  final bool antiMat;
  final bool antiToxic;
  /// Legacy — kept in JSON; UI removed.
  final bool fillerWords;
  /// Legacy — kept in JSON; replaced by [aiAssistant].
  final bool textImprovement;
  /// Sentence-end AI chips (орфография / пунктуация / улучшить).
  final bool aiAssistant;
  /// 0.0–1.0 — higher = show chips sooner (closer to 20 chars).
  final double aiIntensity;
  /// Key-tap haptics.
  final bool vibration;
  /// Stronger haptic when mat is detected.
  final bool matVibration;
  final bool sound;

  KeyboardSettings copyWith({
    bool? antiMat,
    bool? antiToxic,
    bool? fillerWords,
    bool? textImprovement,
    bool? aiAssistant,
    double? aiIntensity,
    bool? vibration,
    bool? matVibration,
    bool? sound,
  }) =>
      KeyboardSettings(
        antiMat: antiMat ?? this.antiMat,
        antiToxic: antiToxic ?? this.antiToxic,
        fillerWords: fillerWords ?? this.fillerWords,
        textImprovement: textImprovement ?? this.textImprovement,
        aiAssistant: aiAssistant ?? this.aiAssistant,
        aiIntensity: aiIntensity ?? this.aiIntensity,
        vibration: vibration ?? this.vibration,
        matVibration: matVibration ?? this.matVibration,
        sound: sound ?? this.sound,
      );

  Map<String, dynamic> toJson() => {
        'antiMat': antiMat,
        'antiToxic': antiToxic,
        'fillerWords': fillerWords,
        'textImprovement': textImprovement,
        'aiAssistant': aiAssistant,
        'aiIntensity': aiIntensity,
        'vibration': vibration,
        'matVibration': matVibration,
        'sound': sound,
      };

  factory KeyboardSettings.fromJson(Map<String, dynamic> json) {
    final intensity = (json['aiIntensity'] as num?)?.toDouble() ?? 0.55;
    return KeyboardSettings(
      antiMat: json['antiMat'] as bool? ?? true,
      antiToxic: json['antiToxic'] as bool? ?? true,
      fillerWords: json['fillerWords'] as bool? ?? false,
      textImprovement: json['textImprovement'] as bool? ?? false,
      // Prefer new flag; fall back to legacy textImprovement if absent.
      aiAssistant: json['aiAssistant'] as bool? ??
          (json['textImprovement'] as bool? ?? true),
      aiIntensity: intensity.clamp(0.0, 1.0),
      vibration: json['vibration'] as bool? ?? true,
      matVibration: json['matVibration'] as bool? ?? true,
      sound: json['sound'] as bool? ?? false,
    );
  }
}
