import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/status_colors.dart';
import '../watch_providers.dart';

class ScansTab extends ConsumerWidget {
  final String watchId;

  const ScansTab({super.key, required this.watchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scansAsync = ref.watch(scansProvider(watchId));
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return scansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text(l10n.watchDetailScansLoadError(error.toString()))),
      data: (scans) {
        if (scans.isEmpty) {
          return Center(
            child: Text(
              l10n.watchDetailNoScans,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: scans.length,
          separatorBuilder: (context, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final scan = scans[index];
            return ListTile(
              leading: Tooltip(
                message: _scanStatusLabel(l10n, scan.status),
                child: StatusIcon(status: scan.status),
              ),
              title: Text(dateFormat.format(scan.startedAt.toLocal())),
              subtitle: Text(
                scan.failedMarketplaces.isNotEmpty
                    ? '${l10n.watchDetailScanFailures(scan.failedMarketplaces.join(', '))}\n'
                          '${l10n.watchDetailScanNewAndSeen(scan.newOffersCount, scan.seenOffersCount)}'
                    : '${_scanStatusLabel(l10n, scan.status)}\n'
                          '${l10n.watchDetailScanNewAndSeen(scan.newOffersCount, scan.seenOffersCount)}',
              ),
              isThreeLine: true,
              trailing: Text(l10n.watchDetailOffersFound(scan.offersFound)),
            );
          },
        );
      },
    );
  }
}

class StatusIcon extends StatelessWidget {
  final String status;

  const StatusIcon({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'success':
        return const Icon(Icons.check_circle, color: successColor);
      case 'partial':
        return const Icon(Icons.warning_amber, color: warningColor);
      case 'failed':
        return Icon(Icons.error, color: scheme.error);
      default:
        return const Icon(Icons.hourglass_empty);
    }
  }
}

String _scanStatusLabel(AppLocalizations l10n, String status) {
  switch (status) {
    case 'success':
      return l10n.scanStatusSuccess;
    case 'partial':
      return l10n.scanStatusPartial;
    case 'failed':
      return l10n.scanStatusFailed;
    default:
      return l10n.scanStatusPending;
  }
}
