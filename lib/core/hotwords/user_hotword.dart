/// User-defined hotword — trigger typed in the field, expansion inserted on tap.
library;

final class UserHotword {
  const UserHotword({
    required this.id,
    required this.trigger,
    required this.expansion,
    required this.updatedAtMs,
  });

  final String id;
  final String trigger;
  final String expansion;
  final int updatedAtMs;

  UserHotword copyWith({
    String? id,
    String? trigger,
    String? expansion,
    int? updatedAtMs,
  }) {
    return UserHotword(
      id: id ?? this.id,
      trigger: trigger ?? this.trigger,
      expansion: expansion ?? this.expansion,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trigger': trigger,
        'expansion': expansion,
        'updatedAtMs': updatedAtMs,
      };

  factory UserHotword.fromJson(Map<String, dynamic> json) {
    return UserHotword(
      id: json['id'] as String? ?? '',
      trigger: json['trigger'] as String? ?? '',
      expansion: json['expansion'] as String? ?? '',
      updatedAtMs: json['updatedAtMs'] as int? ?? 0,
    );
  }
}
