import 'package:flutter/material.dart';

class WordListCard extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController inputController;
  final List<String> words;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final bool isError;
  final Widget? trailing;

  const WordListCard({
    super.key,
    required this.label,
    required this.hint,
    required this.inputController,
    required this.words,
    required this.onAdd,
    required this.onRemove,
    this.isError = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = isError ? scheme.error : scheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: accent),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final word in words)
                  InputChip(label: Text(word), onDeleted: () => onRemove(word)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: inputController,
                    decoration: InputDecoration(hintText: hint),
                    onSubmitted: (_) => onAdd(),
                  ),
                ),
                IconButton(onPressed: onAdd, icon: const Icon(Icons.add)),
              ],
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
