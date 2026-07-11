import 'package:flutter/material.dart';

import '../../core/personal_words/personal_words_repository.dart';
import '../theme/tact_theme.dart';
import '../widgets/tact_widgets.dart';

/// Personal dictionary — custom words for suggestions.
class PersonalWordsScreen extends StatefulWidget {
  const PersonalWordsScreen({super.key});

  @override
  State<PersonalWordsScreen> createState() => _PersonalWordsScreenState();
}

class _PersonalWordsScreenState extends State<PersonalWordsScreen> {
  late final Future<PersonalWordsRepository> _repoFuture;
  Set<String> _items = {};
  bool _loading = true;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repoFuture = PersonalWordsRepository.open();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = await _repoFuture;
    final items = await repo.loadAll();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final word = _controller.text.trim();
    if (word.length < 2) return;
    final repo = await _repoFuture;
    await repo.add(word);
    _controller.clear();
    await _load();
  }

  Future<void> _remove(String word) async {
    final repo = await _repoFuture;
    await repo.remove(word);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TactColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Личный словарь'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: TactColors.purple))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const TactSectionHeader(
                  title: 'Ваши слова',
                  subtitle:
                      'Имена, бренды и сленг — TACT учтёт их в подсказках.',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          labelText: 'Добавить слово',
                          hintText: 'TACT, мск, красава',
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _add(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _add,
                      child: const Text('Добавить'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_items.isEmpty)
                  const TactCard(
                    child: Text(
                      'Пока пусто. Добавьте имена, ники и аббревиатуры.',
                      style: TextStyle(color: TactColors.textSecondary),
                    ),
                  )
                else
                  TactCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Builder(
                      builder: (context) {
                        final sorted = _items.toList()..sort();
                        return Column(
                          children: [
                            for (var i = 0; i < sorted.length; i++) ...[
                              if (i > 0) const Divider(height: 1),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  sorted[i],
                                  style: const TextStyle(
                                    color: TactColors.textPrimary,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 20),
                                  color: TactColors.textMuted,
                                  tooltip: 'Удалить',
                                  onPressed: () => _remove(sorted[i]),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}
