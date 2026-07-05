import 'package:flutter/material.dart';

import '../../core/hotwords/user_hotword.dart';
import '../theme/tact_theme.dart';
import '../widgets/tact_widgets.dart';
import 'shortcuts_repository.dart';

/// Hotwords screen — user creates trigger → expansion pairs for the keyboard.
class ShortcutsScreen extends StatefulWidget {
  const ShortcutsScreen({super.key});

  @override
  State<ShortcutsScreen> createState() => _ShortcutsScreenState();
}

class _ShortcutsScreenState extends State<ShortcutsScreen> {
  late final Future<ShortcutsRepository> _repoFuture;
  List<UserHotword> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repoFuture = ShortcutsRepository.open();
    _load();
  }

  Future<void> _load() async {
    final repo = await _repoFuture;
    final items = await repo.all();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _openEditor({UserHotword? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TactColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _HotwordEditorSheet(existing: existing),
    );
    if (saved == true) await _load();
  }

  Future<void> _delete(UserHotword item) async {
    final repo = await _repoFuture;
    await repo.delete(item.id);
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
        title: const Text('Сокращения'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: TactColors.purple,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Добавить'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: TactColors.purple))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                const TactSectionHeader(
                  title: 'Ваши hotwords',
                  subtitle:
                      'Сокращение + пробел → подсказки в панели клавиатуры. '
                      'Ваши варианты всегда в приоритете.',
                ),
                const SizedBox(height: 16),
                if (_items.isEmpty)
                  const TactCard(
                    child: Text(
                      'Пока пусто. Например: др → Добрый день',
                      style: TextStyle(color: TactColors.textSecondary),
                    ),
                  )
                else
                  TactCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Column(
                      children: [
                        for (var i = 0; i < _items.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          _HotwordRow(
                            item: _items[i],
                            onEdit: () => _openEditor(existing: _items[i]),
                            onDelete: () => _delete(_items[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Как это работает',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: TactColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const TactCard(
                  child: Text(
                    '1. Создайте сокращение, например «др».\n'
                    '2. Укажите текст «Добрый день».\n'
                    '3. В чате наберите др + пробел.\n'
                    '4. В панели появится: др → Добрый день — нажмите, чтобы вставить.',
                    style: TextStyle(
                      fontSize: 13,
                      color: TactColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _HotwordRow extends StatelessWidget {
  const _HotwordRow({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final UserHotword item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        item.trigger,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: TactColors.purple,
        ),
      ),
      subtitle: Text(
        '→ ${item.expansion}',
        style: const TextStyle(color: TactColors.textPrimary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: TactColors.textMuted,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: TactColors.red,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _HotwordEditorSheet extends StatefulWidget {
  const _HotwordEditorSheet({this.existing});

  final UserHotword? existing;

  @override
  State<_HotwordEditorSheet> createState() => _HotwordEditorSheetState();
}

class _HotwordEditorSheetState extends State<_HotwordEditorSheet> {
  late final TextEditingController _trigger;
  late final TextEditingController _expansion;
  String? _error;

  @override
  void initState() {
    super.initState();
    _trigger = TextEditingController(text: widget.existing?.trigger ?? '');
    _expansion = TextEditingController(text: widget.existing?.expansion ?? '');
  }

  @override
  void dispose() {
    _trigger.dispose();
    _expansion.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      final repo = await ShortcutsRepository.open();
      await repo.upsert(
        id: widget.existing?.id,
        trigger: _trigger.text,
        expansion: _expansion.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existing == null ? 'Новое сокращение' : 'Изменить',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: TactColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _trigger,
            decoration: const InputDecoration(
              labelText: 'Сокращение',
              hintText: 'др',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _expansion,
            decoration: const InputDecoration(
              labelText: 'Текст',
              hintText: 'Добрый день',
              border: OutlineInputBorder(),
            ),
            minLines: 1,
            maxLines: 3,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: TactColors.red, fontSize: 12)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(backgroundColor: TactColors.purple),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}
