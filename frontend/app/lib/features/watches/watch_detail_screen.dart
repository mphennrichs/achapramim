import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import 'watch_providers.dart';
import 'widgets/offers_tab.dart';
import 'widgets/scans_tab.dart';
import 'widgets/watch_summary_header.dart';

class WatchDetailScreen extends ConsumerStatefulWidget {
  final String watchId;

  const WatchDetailScreen({super.key, required this.watchId});

  @override
  ConsumerState<WatchDetailScreen> createState() => _WatchDetailScreenState();
}

class _WatchDetailScreenState extends ConsumerState<WatchDetailScreen> {
  bool _deleting = false;

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.watchDeleteConfirmTitle),
        content: Text(l10n.watchDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.watchDeleteConfirmCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(l10n.watchDeleteConfirmConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await ref.read(watchServiceProvider).delete(widget.watchId);
      ref.invalidate(watchListProvider);
      if (mounted) context.go('/watches');
    } catch (error) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.watchDeleteError(error.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final watchAsync = ref.watch(watchProvider(widget.watchId));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          watchAsync.valueOrNull?.name ?? l10n.watchDetailFallbackTitle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.watchEditTooltip,
            onPressed: () async {
              await context.push('/watches/${widget.watchId}/edit');
              ref.invalidate(watchProvider(widget.watchId));
            },
          ),
          IconButton(
            icon: _deleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
            tooltip: l10n.watchDeleteTooltip,
            onPressed: _deleting ? null : _confirmDelete,
          ),
        ],
      ),
      body: watchAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(l10n.watchDetailLoadError(error.toString()))),
        data: (watch) => DefaultTabController(
          length: 2,
          child: Column(
            children: [
              WatchSummaryHeader(watch: watch),
              TabBar(
                tabs: [
                  Tab(text: l10n.watchDetailTabOffers),
                  Tab(text: l10n.watchDetailTabScans),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    OffersTab(watchId: widget.watchId),
                    ScansTab(watchId: widget.watchId),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
