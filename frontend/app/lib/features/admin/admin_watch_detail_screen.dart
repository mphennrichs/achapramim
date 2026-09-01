import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/watch.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../watches/widgets/offers_tab.dart';
import '../watches/widgets/scans_tab.dart';
import '../watches/widgets/watch_summary_header.dart';
import 'admin_providers.dart';

/// Detalhe de um Alerta na visão admin: mesmos Offers/Scans da tela do dono,
/// mais dono, região, modo de palavras-chave e as listas de palavras. Pausar
/// e excluir ficam na AppBar (o backend autoriza admin — ver getOwnedWatch).
class AdminWatchDetailScreen extends ConsumerStatefulWidget {
  final String watchId;

  const AdminWatchDetailScreen({super.key, required this.watchId});

  @override
  ConsumerState<AdminWatchDetailScreen> createState() =>
      _AdminWatchDetailScreenState();
}

class _AdminWatchDetailScreenState
    extends ConsumerState<AdminWatchDetailScreen> {
  bool _busy = false;

  Future<void> _setActive(bool active) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await ref.read(watchServiceProvider).setActive(widget.watchId, active);
      ref.invalidate(allWatchesProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminWatchesSetActiveError(error.toString())),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete(Watch watch) async {
    final l10n = AppLocalizations.of(context)!;
    final owner = watch.ownerName ?? watch.ownerEmail ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminWatchesDeleteConfirmTitle),
        content: Text(l10n.adminWatchesDeleteConfirmMessage(watch.name, owner)),
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

    setState(() => _busy = true);
    try {
      await ref.read(watchServiceProvider).delete(watch.id);
      ref.invalidate(allWatchesProvider);
      if (mounted) context.go('/admin/watches');
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.adminWatchesDeleteError(error.toString())),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final watchAsync = ref.watch(adminWatchProvider(widget.watchId));
    final watch = watchAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(watch?.name ?? l10n.watchDetailFallbackTitle),
        actions: [
          if (watch != null) ...[
            Switch(value: watch.active, onChanged: _busy ? null : _setActive),
            IconButton(
              icon: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              tooltip: l10n.adminWatchesDeleteTooltip,
              onPressed: _busy ? null : () => _confirmDelete(watch),
            ),
          ],
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
              _AdminWatchInfo(watch: watch),
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

class _AdminWatchInfo extends StatelessWidget {
  final Watch watch;

  const _AdminWatchInfo({required this.watch});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final region = watch.city != null && watch.city!.isNotEmpty
        ? '${watch.city}/${watch.state ?? ''}'
        : l10n.adminWatchDetailRegionDefault;
    final modeLabel = watch.keywordMatchMode == 'all'
        ? l10n.newWatchKeywordModeAll
        : l10n.newWatchKeywordModeAny;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      constraints: const BoxConstraints(maxHeight: 260),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (watch.ownerName != null && watch.ownerEmail != null)
              Text(
                l10n.adminWatchesOwnerLabel(
                  watch.ownerName!,
                  watch.ownerEmail!,
                ),
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.place_outlined, size: 18),
                  label: Text(region),
                ),
                Chip(
                  label: Text(l10n.adminWatchDetailKeywordModeLabel(modeLabel)),
                ),
              ],
            ),
            if (watch.keywords.isNotEmpty) ...[
              const SizedBox(height: 12),
              _WordSection(label: l10n.newWatchKeywords, words: watch.keywords),
            ],
            if (watch.blockedWords.isNotEmpty) ...[
              const SizedBox(height: 12),
              _WordSection(
                label: l10n.newWatchBlockedWords,
                words: watch.blockedWords,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WordSection extends StatelessWidget {
  final String label;
  final List<String> words;

  const _WordSection({required this.label, required this.words});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: scheme.primary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final w in words) Chip(label: Text(w))],
        ),
      ],
    );
  }
}
