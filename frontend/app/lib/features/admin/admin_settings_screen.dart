import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/marketplace_labels.dart';
import '../../core/models/scan_settings.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/apify_usage_card.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(scanSettingsProvider);

    return Scaffold(
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(l10n.adminSettingsLoadError(error.toString()))),
        data: (settings) => _SettingsBody(settings: settings),
      ),
    );
  }
}

class _SettingsBody extends ConsumerStatefulWidget {
  final ScanSettings settings;

  const _SettingsBody({required this.settings});

  @override
  ConsumerState<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends ConsumerState<_SettingsBody> {
  late final _minController = TextEditingController(
    text: widget.settings.minIntervalMinutes.toString(),
  );
  late final _maxController = TextEditingController(
    text: widget.settings.maxIntervalMinutes.toString(),
  );
  late final _cityController = TextEditingController(
    text: widget.settings.defaultCity,
  );
  late final _stateController = TextEditingController(
    text: widget.settings.defaultState,
  );
  late final _blockedWordInputController = TextEditingController();
  late final List<String> _blockedWords = List.of(
    widget.settings.defaultBlockedWords,
  );

  // Um par de controllers min/max por marketplace conhecido
  // (availableMarketplaces) — pré-preenchido com o override existente, ou
  // com o fallback global quando o marketplace ainda não tem override
  // próprio.
  late final Map<String, TextEditingController> _marketplaceMinControllers = {
    for (final slug in availableMarketplaces)
      slug: TextEditingController(
        text:
            (_findMarketplaceInterval(slug)?.minIntervalMinutes ??
                    widget.settings.minIntervalMinutes)
                .toString(),
      ),
  };
  late final Map<String, TextEditingController> _marketplaceMaxControllers = {
    for (final slug in availableMarketplaces)
      slug: TextEditingController(
        text:
            (_findMarketplaceInterval(slug)?.maxIntervalMinutes ??
                    widget.settings.maxIntervalMinutes)
                .toString(),
      ),
  };

  MarketplaceScanInterval? _findMarketplaceInterval(String slug) {
    for (final interval in widget.settings.marketplaceIntervals) {
      if (interval.marketplaceSlug == slug) return interval;
    }
    return null;
  }

  bool _saving = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _blockedWordInputController.dispose();
    for (final c in _marketplaceMinControllers.values) {
      c.dispose();
    }
    for (final c in _marketplaceMaxControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _addBlockedWord() {
    final value = _blockedWordInputController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      if (!_blockedWords.any((w) => w.toLowerCase() == value.toLowerCase())) {
        _blockedWords.add(value);
      }
      _blockedWordInputController.clear();
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final min = int.tryParse(_minController.text.trim());
    final max = int.tryParse(_maxController.text.trim());
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();

    if (min == null ||
        max == null ||
        max < min ||
        city.isEmpty ||
        state.isEmpty) {
      setState(() {
        _errorMessage = l10n.adminSettingsValidationError;
        _successMessage = null;
      });
      return;
    }

    final marketplaceIntervals = <MarketplaceScanInterval>[];
    for (final slug in availableMarketplaces) {
      final mMin = int.tryParse(_marketplaceMinControllers[slug]!.text.trim());
      final mMax = int.tryParse(_marketplaceMaxControllers[slug]!.text.trim());
      if (mMin == null || mMax == null || mMax < mMin) {
        setState(() {
          _errorMessage = l10n.adminSettingsValidationError;
          _successMessage = null;
        });
        return;
      }
      marketplaceIntervals.add(
        MarketplaceScanInterval(
          marketplaceSlug: slug,
          minIntervalMinutes: mMin,
          maxIntervalMinutes: mMax,
        ),
      );
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await ref
          .read(adminServiceProvider)
          .updateScanSettings(
            ScanSettings(
              minIntervalMinutes: min,
              maxIntervalMinutes: max,
              defaultCity: city,
              defaultState: state,
              defaultBlockedWords: _blockedWords,
              marketplaceIntervals: marketplaceIntervals,
            ),
          );
      // A tela de Novo Alerta também lê scanSettingsProvider (hint de
      // região) — invalida para refletir a mudança sem precisar recarregar.
      ref.invalidate(scanSettingsProvider);
      if (mounted) {
        setState(() => _successMessage = l10n.adminSettingsSaveSuccess);
      }
    } on DioException {
      if (mounted) setState(() => _errorMessage = l10n.adminSettingsSaveError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.adminSettingsScanTitle,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.adminSettingsScanDescription,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.adminSettingsMinIntervalLabel,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _maxController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.adminSettingsMaxIntervalLabel,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.adminSettingsMarketplaceIntervalsTitle,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.adminSettingsMarketplaceIntervalsDescription,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    for (final slug in availableMarketplaces) ...[
                      Text(
                        marketplaceLabel(l10n, slug),
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _marketplaceMinControllers[slug],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.adminSettingsMinIntervalLabel,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _marketplaceMaxControllers[slug],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.adminSettingsMaxIntervalLabel,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (slug != availableMarketplaces.last)
                        const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.adminSettingsRegionTitle,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.adminSettingsRegionDescription,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _cityController,
                            decoration: InputDecoration(
                              labelText: l10n.adminSettingsDefaultCityLabel,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _stateController,
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 2,
                            decoration: InputDecoration(
                              labelText: l10n.adminSettingsDefaultStateLabel,
                              counterText: '',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.adminSettingsBlockedWordsTitle,
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: scheme.error),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.adminSettingsBlockedWordsDescription,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final word in _blockedWords)
                          InputChip(
                            label: Text(word),
                            onDeleted: () =>
                                setState(() => _blockedWords.remove(word)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _blockedWordInputController,
                            decoration: InputDecoration(
                              hintText: l10n.newWatchAddWordHint,
                            ),
                            onSubmitted: (_) => _addBlockedWord(),
                          ),
                        ),
                        IconButton(
                          onPressed: _addBlockedWord,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const ApifyUsageCard(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(_errorMessage!, style: TextStyle(color: scheme.error)),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 16),
              Text(_successMessage!, style: TextStyle(color: scheme.primary)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.adminSettingsSave),
            ),
          ],
        ),
      ),
    );
  }
}
