import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'admin_providers.dart';
import 'widgets/admin_watch_card.dart';

class AdminWatchesScreen extends ConsumerWidget {
  const AdminWatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final watchesAsync = ref.watch(allWatchesProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: watchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(l10n.adminWatchesLoadError(error.toString()))),
        data: (watches) {
          if (watches.isEmpty) {
            return Center(
              child: Text(
                l10n.adminWatchesEmpty,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: watches.length,
            separatorBuilder: (context, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                AdminWatchCard(watch: watches[index]),
          );
        },
      ),
    );
  }
}
