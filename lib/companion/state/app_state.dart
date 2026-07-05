import 'package:flutter/foundation.dart';

/// In-memory companion app state. UI-only for now — engines wire in later.
class CompanionAppState extends ChangeNotifier {
  // ── Keyboard modes ────────────────────────────────────────────────
  bool antiMat = true;
  bool antiToxic = true;
  bool fillerWords = true;
  bool errorCorrection = true;
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

  void setAntiMat(bool v) {
    antiMat = v;
    notifyListeners();
  }

  void setAntiToxic(bool v) {
    antiToxic = v;
    notifyListeners();
  }

  void setFillerWords(bool v) {
    fillerWords = v;
    notifyListeners();
  }

  void setErrorCorrection(bool v) {
    errorCorrection = v;
    notifyListeners();
  }

  void setTextImprovement(bool v) {
    textImprovement = v;
    notifyListeners();
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
  }

  void setSound(bool v) {
    sound = v;
    notifyListeners();
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
