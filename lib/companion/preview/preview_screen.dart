import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme/tact_theme.dart';
import '../widgets/tact_widgets.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key, required this.state});

  final CompanionAppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TactColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Предпросмотр'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Так будет выглядеть клавиатура и панель во время работы',
                style: TextStyle(
                  fontSize: 14,
                  color: TactColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: TactColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TactColors.surfaceBorder),
                ),
                child: Column(
                  children: [
                    const Spacer(),
                    _chatArea(),
                    const MiniKeyboardPreview(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _chatArea() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: TactColors.chatOutgoing,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Привет, как дела?',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: TactColors.chatIncoming,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Нормально, а у тебя?',
                style: TextStyle(color: TactColors.textPrimary, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
