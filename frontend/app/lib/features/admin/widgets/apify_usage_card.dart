import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';

/// Histórico de custo da conta Apify usada pelo Facebook Marketplace (ver
/// ADR 0006) — só leitura, consulta a API do Apify ao vivo via backend, sem
/// nenhum estado/edição própria.
class ApifyUsageCard extends ConsumerWidget {
  const ApifyUsageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final usageAsync = ref.watch(apifyUsageProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.adminSettingsApifyUsageTitle,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.adminSettingsApifyUsageDescription,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 16),
            usageAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(
                l10n.adminSettingsApifyUsageError(error.toString()),
                style: TextStyle(color: scheme.error),
              ),
              data: (usage) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.adminSettingsApifyUsageTotal(
                      usage.totalUsd.toStringAsFixed(4),
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (usage.runs.isEmpty)
                    Text(
                      l10n.adminSettingsApifyUsageEmpty,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: usage.runs.length,
                        separatorBuilder: (_, _) =>
                            Divider(color: scheme.outlineVariant),
                        itemBuilder: (context, index) {
                          final run = usage.runs[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat(
                                          'dd/MM/yyyy HH:mm',
                                        ).format(run.startedAt.toLocal()),
                                      ),
                                      Text(
                                        _apifyRunStatusLabel(l10n, run.status),
                                        style: TextStyle(
                                          color: scheme.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\$${run.usageUsd.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _apifyRunStatusLabel(AppLocalizations l10n, String status) {
  switch (status) {
    case 'READY':
      return l10n.apifyRunStatusReady;
    case 'RUNNING':
      return l10n.apifyRunStatusRunning;
    case 'SUCCEEDED':
      return l10n.apifyRunStatusSucceeded;
    case 'FAILED':
      return l10n.apifyRunStatusFailed;
    case 'ABORTING':
      return l10n.apifyRunStatusAborting;
    case 'ABORTED':
      return l10n.apifyRunStatusAborted;
    case 'TIMING-OUT':
      return l10n.apifyRunStatusTimingOut;
    case 'TIMED-OUT':
      return l10n.apifyRunStatusTimedOut;
    default:
      return status;
  }
}
