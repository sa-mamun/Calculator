import 'package:flutter/material.dart';

import '../controllers/history_controller.dart';
import '../logic/number_format.dart';
import '../models/history_entry.dart';

/// The history list, shown as a draggable bottom sheet.
///
/// Tapping an entry returns its result so the caller can drop it into the
/// current expression, which is the main reason to keep history at all.
class HistorySheet extends StatelessWidget {
  const HistorySheet({super.key, required this.controller});

  final HistoryController controller;

  /// Opens the sheet and completes with the result the user picked, or null.
  static Future<String?> show(
    BuildContext context,
    HistoryController controller,
  ) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      builder: (_) => HistorySheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final entries = controller.entries;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
                  child: Row(
                    children: [
                      Text('History', style: theme.textTheme.titleLarge),
                      const Spacer(),
                      if (entries.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => _confirmClear(context),
                          icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                          label: const Text('Clear'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: entries.isEmpty
                      ? _EmptyState(scheme: scheme)
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: entries.length,
                          itemBuilder: (context, index) => _HistoryTile(
                            entry: entries[index],
                            onTap: () =>
                                Navigator.of(context).pop(entries[index].result),
                            onDismissed: () => controller.removeAt(index),
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('This removes every saved calculation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) controller.clear();
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.onTap,
    required this.onDismissed,
  });

  final HistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Dismissible(
      key: ValueKey('${entry.at.microsecondsSinceEpoch}-${entry.expression}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: scheme.errorContainer,
        child: Icon(Icons.delete_outline_rounded, color: scheme.onErrorContainer),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          entry.expression,
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        subtitle: Text(
          // Stored plain so it can be fed back into an expression; grouped
          // here so it matches the main display.
          _grouped(entry.result),
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

String _grouped(String result) {
  final value = num.tryParse(result);
  return value == null ? result : NumberFormatter.format(value);
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 44, color: scheme.outline),
          const SizedBox(height: 12),
          Text(
            'No calculations yet',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
