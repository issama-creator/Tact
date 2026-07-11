/// User toggles for keyboard intelligence — shared by companion and IME.
library;

/// Mode switches from the companion «Клавиатура» / «Настройки» screens.
final class KeyboardSettings {
  const KeyboardSettings({
    this.antiMat = true,
    this.antiToxic = true,
    this.fillerWords = true,
    this.textImprovement = true,
    this.vibration = true,
    this.sound = false,
  });

  static const defaults = KeyboardSettings();

  final bool antiMat;
  final bool antiToxic;
  final bool fillerWords;
  final bool textImprovement;
  final bool vibration;
  final bool sound;

  KeyboardSettings copyWith({
    bool? antiMat,
    bool? antiToxic,
    bool? fillerWords,
    bool? textImprovement,
    bool? vibration,
    bool? sound,
  }) =>
      KeyboardSettings(
        antiMat: antiMat ?? this.antiMat,
        antiToxic: antiToxic ?? this.antiToxic,
        fillerWords: fillerWords ?? this.fillerWords,
        textImprovement: textImprovement ?? this.textImprovement,
        vibration: vibration ?? this.vibration,
        sound: sound ?? this.sound,
      );

  Map<String, dynamic> toJson() => {
        'antiMat': antiMat,
        'antiToxic': antiToxic,
        'fillerWords': fillerWords,
        'textImprovement': textImprovement,
        'vibration': vibration,
        'sound': sound,
      };

  factory KeyboardSettings.fromJson(Map<String, dynamic> json) =>
      KeyboardSettings(
        antiMat: json['antiMat'] as bool? ?? true,
        antiToxic: json['antiToxic'] as bool? ?? true,
        fillerWords: json['fillerWords'] as bool? ?? true,
        textImprovement: json['textImprovement'] as bool? ?? true,
        vibration: json['vibration'] as bool? ?? true,
        sound: json['sound'] as bool? ?? false,
      );
}
