import 'package:flutter/material.dart';

import 'appearance/appearance_screen.dart';
import 'home/home_screen.dart';
import 'keyboard/keyboard_screen.dart';
import 'profile/profile_screen.dart';
import 'platform/ime_platform.dart';
import 'state/app_state.dart';
import 'theme/tact_theme.dart';
import 'widgets/tact_bottom_nav.dart';

/// Companion app shell — bottom navigation + shared state.
class CompanionShell extends StatefulWidget {
  const CompanionShell({super.key, required this.state});

  final CompanionAppState state;

  @override
  State<CompanionShell> createState() => _CompanionShellState();
}

class _CompanionShellState extends State<CompanionShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(state: widget.state),
      KeyboardScreen(state: widget.state),
      AppearanceScreen(state: widget.state),
      ProfileScreen(state: widget.state),
    ];

    return Scaffold(
      backgroundColor: TactColors.background,
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: TactBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

/// Root MaterialApp for the TACT companion.
class CompanionApp extends StatefulWidget {
  const CompanionApp({super.key});

  @override
  State<CompanionApp> createState() => _CompanionAppState();
}

class _CompanionAppState extends State<CompanionApp> {
  final _state = CompanionAppState();

  @override
  void initState() {
    super.initState();
    ImePlatform.ensureInitialized();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TACT',
      theme: buildTactTheme(),
      home: CompanionShell(state: _state),
    );
  }
}
