/// User toggles for keyboard intelligence — shared by companion and IME.
library;

/// Mode switches from the companion «Клавиатура» screen.
final class KeyboardSettings {
  const KeyboardSettings({
    this.antiMat = true,
    this.antiToxic = true,
    this.fillerWords = true,
    this.errorCorrection = true,
    this.textImprovement = true,
  });

  static const defaults = KeyboardSettings();

  final bool antiMat;
  final bool antiToxic;
  final bool fillerWords;
  final bool errorCorrection;
  final bool textImprovement;

  KeyboardSettings copyWith({
    bool? antiMat,
    bool? antiToxic,
    bool? fillerWords,
    bool? errorCorrection,
    bool? textImprovement,
  }) =>
      KeyboardSettings(
        antiMat: antiMat ?? this.antiMat,
        antiToxic: antiToxic ?? this.antiToxic,
        fillerWords: fillerWords ?? this.fillerWords,
        errorCorrection: errorCorrection ?? this.errorCorrection,
        textImprovement: textImprovement ?? this.textImprovement,
      );

  Map<String, dynamic> toJson() => {
        'antiMat': antiMat,
        'antiToxic': antiToxic,
        'fillerWords': fillerWords,
        'errorCorrection': errorCorrection,
        'textImprovement': textImprovement,
      };

  factory KeyboardSettings.fromJson(Map<String, dynamic> json) =>
      KeyboardSettings(
        antiMat: json['antiMat'] as bool? ?? true,
        antiToxic: json['antiToxic'] as bool? ?? true,
        fillerWords: json['fillerWords'] as bool? ?? true,
        errorCorrection: json['errorCorrection'] as bool? ?? true,
        textImprovement: json['textImprovement'] as bool? ?? true,
      );
}
