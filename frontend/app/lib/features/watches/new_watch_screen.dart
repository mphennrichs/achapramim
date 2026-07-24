import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/watch.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import 'watch_list_screen.dart';

const _availableMarketplaces = ['olx', 'mercado_livre', 'facebook_marketplace'];

String _marketplaceLabel(AppLocalizations l10n, String slug) {
  switch (slug) {
    case 'olx':
      return l10n.marketplaceOlx;
    case 'mercado_livre':
      return l10n.marketplaceMercadoLivre;
    case 'facebook_marketplace':
      return l10n.marketplaceFacebook;
    default:
      return slug;
  }
}

class NewWatchScreen extends ConsumerStatefulWidget {
  const NewWatchScreen({super.key});

  @override
  ConsumerState<NewWatchScreen> createState() => _NewWatchScreenState();
}

class _NewWatchScreenState extends ConsumerState<NewWatchScreen> {
  final _nameController = TextEditingController();
  final _targetPriceController = TextEditingController();
  final _toleranceController = TextEditingController(text: '5');
  final _thresholdController = TextEditingController(text: '10');
  final _maxOffersController = TextEditingController(text: '50');
  final _keywordInputController = TextEditingController();
  final _blockedInputController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  final List<String> _keywords = [];
  final List<String> _blockedWords = [];
  final Set<String> _selectedMarketplaces = {'olx'};

  bool _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _targetPriceController.dispose();
    _toleranceController.dispose();
    _thresholdController.dispose();
    _maxOffersController.dispose();
    _keywordInputController.dispose();
    _blockedInputController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _addKeyword() {
    final value = _keywordInputController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      if (!_keywords.contains(value)) _keywords.add(value);
      _keywordInputController.clear();
    });
  }

  void _addBlockedWord() {
    final value = _blockedInputController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      if (!_blockedWords.contains(value)) _blockedWords.add(value);
      _blockedInputController.clear();
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final targetPrice = double.tryParse(_targetPriceController.text.replaceAll(',', '.'));

    if (name.isEmpty || targetPrice == null || _selectedMarketplaces.isEmpty) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.newWatchValidationError;
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final city = _cityController.text.trim();
    final state = _stateController.text.trim();

    final watch = Watch(
      id: '',
      userId: '',
      name: name,
      targetPriceCents: (targetPrice * 100).round(),
      tolerancePercent: _toleranceController.text.trim(),
      maxOffers: int.tryParse(_maxOffersController.text.trim()) ?? 50,
      priceDropThresholdPercent: _thresholdController.text.trim(),
      active: true,
      keywords: _keywords,
      blockedWords: _blockedWords,
      marketplaces: _selectedMarketplaces.toList(),
      // Vazio = usa o padrão global (ver ScanSettingsHandler/OLXFetcher).
      city: city.isEmpty ? null : city,
      state: state.isEmpty ? null : state,
    );

    try {
      await ref.read(watchServiceProvider).create(watch);
      if (!mounted) return;
      // Invalida a lista antes de trocar de branch: o IndexedStack do shell
      // mantém WatchListScreen viva entre navegações (não recria como o
      // Navigator.push antigo fazia), então sem isso ela continuaria
      // mostrando o resultado já resolvido antes da criação.
      ref.invalidate(watchListProvider);
      context.go('/watches');
    } on DioException catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!
            .newWatchSaveError('${e.response?.data ?? e.message}');
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Criação a partir de link (via LLM) fica oculta: não faz
              // parte do MVP, que só cobre criação manual do Watch.
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.newWatchIdentification,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: l10n.newWatchNameLabel),
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
                      Text(l10n.newWatchRegionTitle, style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _cityController,
                              decoration: InputDecoration(labelText: l10n.newWatchCityLabel),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _stateController,
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 2,
                              decoration: InputDecoration(
                                labelText: l10n.newWatchStateLabel,
                                counterText: '',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Consumer(
                        builder: (context, ref, _) {
                          final settings = ref.watch(scanSettingsProvider);
                          return settings.when(
                            data: (s) => Text(
                              l10n.newWatchRegionHint(s.defaultCity, s.defaultState),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, _) => const SizedBox.shrink(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _WordListCard(
                      label: l10n.newWatchKeywords,
                      hint: l10n.newWatchAddWordHint,
                      inputController: _keywordInputController,
                      words: _keywords,
                      onAdd: _addKeyword,
                      onRemove: (word) => setState(() => _keywords.remove(word)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _WordListCard(
                      label: l10n.newWatchBlockedWords,
                      hint: l10n.newWatchAddWordHint,
                      inputController: _blockedInputController,
                      words: _blockedWords,
                      onAdd: _addBlockedWord,
                      onRemove: (word) => setState(() => _blockedWords.remove(word)),
                      isError: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.newWatchActiveMarketplaces, style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final slug in _availableMarketplaces)
                            FilterChip(
                              label: Text(_marketplaceLabel(l10n, slug)),
                              selected: _selectedMarketplaces.contains(slug),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedMarketplaces.add(slug);
                                  } else {
                                    _selectedMarketplaces.remove(slug);
                                  }
                                });
                              },
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
                      Text(l10n.newWatchFinanceAndLimits, style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _targetPriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(labelText: l10n.newWatchTargetPriceLabel),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _toleranceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(labelText: l10n.newWatchToleranceLabel),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _thresholdController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.newWatchDropThresholdLabel,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _maxOffersController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(labelText: l10n.newWatchMaxOffersLabel),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(_errorMessage!, style: TextStyle(color: scheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(l10n.newWatchSubmit),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordListCard extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController inputController;
  final List<String> words;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final bool isError;

  const _WordListCard({
    required this.label,
    required this.hint,
    required this.inputController,
    required this.words,
    required this.onAdd,
    required this.onRemove,
    this.isError = false,
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
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: accent),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final word in words)
                  InputChip(
                    label: Text(word),
                    onDeleted: () => onRemove(word),
                  ),
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
          ],
        ),
      ),
    );
  }
}
