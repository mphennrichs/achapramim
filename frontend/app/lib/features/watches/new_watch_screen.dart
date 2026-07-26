import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/marketplace_labels.dart';
import '../../core/models/scan_settings.dart';
import '../../core/models/watch.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import 'watch_providers.dart';
import 'widgets/word_list_card.dart';

final _editWatchProvider = FutureProvider.autoDispose.family<Watch, String>((
  ref,
  watchId,
) {
  return ref.watch(watchServiceProvider).get(watchId);
});

/// Carrega o Watch antes de montar o formulário de edição (NewWatchScreen
/// com initialWatch) — a tela em si é síncrona/stateful sobre os valores
/// iniciais, então precisa deles resolvidos antes de montar.
class EditWatchScreen extends ConsumerWidget {
  final String watchId;

  const EditWatchScreen({super.key, required this.watchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchAsync = ref.watch(_editWatchProvider(watchId));
    final l10n = AppLocalizations.of(context)!;

    return watchAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.editWatchTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.editWatchTitle)),
        body: Center(child: Text(l10n.watchDetailLoadError(error.toString()))),
      ),
      data: (watch) => NewWatchScreen(initialWatch: watch),
    );
  }
}

class NewWatchScreen extends ConsumerStatefulWidget {
  // Presente = modo edição de um Alerta existente (todos os campos
  // pré-preenchidos com os valores atuais, sem aplicar defaults globais, e
  // salvar chama update em vez de create). Ausente = criação, comportamento
  // original.
  final Watch? initialWatch;

  const NewWatchScreen({super.key, this.initialWatch});

  @override
  ConsumerState<NewWatchScreen> createState() => _NewWatchScreenState();
}

class _NewWatchScreenState extends ConsumerState<NewWatchScreen> {
  bool get _isEditing => widget.initialWatch != null;

  late final _nameController = TextEditingController(
    text: widget.initialWatch?.name ?? '',
  );
  late final _targetPriceController = TextEditingController(
    text: widget.initialWatch != null
        ? (widget.initialWatch!.targetPriceCents / 100).toStringAsFixed(2)
        : '',
  );
  late final _toleranceController = TextEditingController(
    text: widget.initialWatch?.tolerancePercent ?? '5',
  );
  late final _thresholdController = TextEditingController(
    text: widget.initialWatch?.priceDropThresholdPercent ?? '10',
  );
  late final _maxOffersController = TextEditingController(
    text: (widget.initialWatch?.maxOffers ?? 50).toString(),
  );
  final _keywordInputController = TextEditingController();
  final _blockedInputController = TextEditingController();
  late final _cityController = TextEditingController(
    text: widget.initialWatch?.city ?? '',
  );
  late final _stateController = TextEditingController(
    text: widget.initialWatch?.state ?? '',
  );

  late final List<String> _keywords = List.of(
    widget.initialWatch?.keywords ?? [],
  );
  late final List<String> _blockedWords = List.of(
    widget.initialWatch?.blockedWords ?? [],
  );
  late final Set<String> _selectedMarketplaces = Set.of(
    widget.initialWatch?.marketplaces ?? {'olx'},
  );
  late String _keywordMatchMode = widget.initialWatch?.keywordMatchMode ?? 'any';

  bool _saving = false;
  String? _errorMessage;
  // Evita sobrescrever cidade/estado/palavras-bloqueadas assim que o usuário
  // já os editou — o provider pode reemitir (ex.: refresh) depois do
  // preenchimento inicial. Sempre true em modo edição: os campos já vêm dos
  // valores reais do Alerta, não devem levar o seed/default global.
  bool _defaultsApplied = false;

  void _applyDefaults(ScanSettings settings) {
    if (_isEditing || _defaultsApplied) return;
    _defaultsApplied = true;
    _cityController.text = settings.defaultCity;
    _stateController.text = settings.defaultState;
    setState(() {
      _blockedWords.addAll(settings.defaultBlockedWords);
    });
  }

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
    final targetPrice = double.tryParse(
      _targetPriceController.text.replaceAll(',', '.'),
    );

    if (name.isEmpty ||
        targetPrice == null ||
        _selectedMarketplaces.isEmpty ||
        _keywords.isEmpty) {
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
      id: widget.initialWatch?.id ?? '',
      userId: widget.initialWatch?.userId ?? '',
      name: name,
      targetPriceCents: (targetPrice * 100).round(),
      tolerancePercent: _toleranceController.text.trim(),
      maxOffers: int.tryParse(_maxOffersController.text.trim()) ?? 50,
      priceDropThresholdPercent: _thresholdController.text.trim(),
      active: widget.initialWatch?.active ?? true,
      keywords: _keywords,
      blockedWords: _blockedWords,
      marketplaces: _selectedMarketplaces.toList(),
      // Vazio = usa o padrão global (ver ScanSettingsHandler/OLXFetcher).
      city: city.isEmpty ? null : city,
      state: state.isEmpty ? null : state,
      keywordMatchMode: _keywordMatchMode,
    );

    try {
      if (_isEditing) {
        await ref.read(watchServiceProvider).update(watch.id, watch);
      } else {
        await ref.read(watchServiceProvider).create(watch);
      }
      if (!mounted) return;
      // Invalida a lista antes de trocar de branch: o IndexedStack do shell
      // mantém WatchListScreen viva entre navegações (não recria como o
      // Navigator.push antigo fazia), então sem isso ela continuaria
      // mostrando o resultado já resolvido antes da criação/edição.
      ref.invalidate(watchListProvider);
      if (_isEditing) {
        context.pop();
      } else {
        context.go('/watches');
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(
          context,
        )!.newWatchSaveError('${e.response?.data ?? e.message}');
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    // Abaixo do breakpoint, pares de campo lado a lado (cidade/estado,
    // keywords/bloqueadas, preço/tolerância, gatilho/máximo) ficam
    // espremidos demais para o SegmentedButton e os TextFields — empilha em
    // Column em vez de dividir a largura ao meio.
    final isNarrow = MediaQuery.of(context).size.width < 600;

    ref.listen(scanSettingsProvider, (previous, next) {
      final settings = next.valueOrNull;
      if (settings != null) _applyDefaults(settings);
    });
    final initialSettings = ref.watch(scanSettingsProvider).valueOrNull;
    if (initialSettings != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _applyDefaults(initialSettings),
      );
    }

    return Scaffold(
      appBar: _isEditing ? AppBar(title: Text(l10n.editWatchTitle)) : null,
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
                        decoration: InputDecoration(
                          labelText: l10n.newWatchNameLabel,
                        ),
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
                        l10n.newWatchActiveMarketplaces,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final slug in availableMarketplaces)
                            FilterChip(
                              label: Text(marketplaceLabel(l10n, slug)),
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
                      Text(
                        l10n.newWatchRegionTitle,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _cityController,
                              decoration: InputDecoration(
                                labelText: l10n.newWatchCityLabel,
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
                                labelText: l10n.newWatchStateLabel,
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
              Builder(
                builder: (context) {
                  final keywordsCard = WordListCard(
                    label: l10n.newWatchKeywords,
                    hint: l10n.newWatchAddWordHint,
                    inputController: _keywordInputController,
                    words: _keywords,
                    onAdd: _addKeyword,
                    onRemove: (word) => setState(() => _keywords.remove(word)),
                    trailing: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SegmentedButton<String>(
                            segments: [
                              ButtonSegment(
                                value: 'any',
                                label: Text(l10n.newWatchKeywordModeAny),
                              ),
                              ButtonSegment(
                                value: 'all',
                                label: Text(l10n.newWatchKeywordModeAll),
                              ),
                            ],
                            selected: {_keywordMatchMode},
                            onSelectionChanged: (selection) => setState(
                              () => _keywordMatchMode = selection.first,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.newWatchKeywordModeHint,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                  final blockedWordsCard = WordListCard(
                    label: l10n.newWatchBlockedWords,
                    hint: l10n.newWatchAddWordHint,
                    inputController: _blockedInputController,
                    words: _blockedWords,
                    onAdd: _addBlockedWord,
                    onRemove: (word) =>
                        setState(() => _blockedWords.remove(word)),
                    isError: true,
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        keywordsCard,
                        const SizedBox(height: 16),
                        blockedWordsCard,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: keywordsCard),
                      const SizedBox(width: 16),
                      Expanded(child: blockedWordsCard),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.newWatchFinanceAndLimits,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 12),
                      _FieldPair(
                        stacked: isNarrow,
                        first: TextField(
                          controller: _targetPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.newWatchTargetPriceLabel,
                          ),
                        ),
                        second: TextField(
                          controller: _toleranceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.newWatchToleranceLabel,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _FieldPair(
                        stacked: isNarrow,
                        first: TextField(
                          controller: _thresholdController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.newWatchDropThresholdLabel,
                          ),
                        ),
                        second: TextField(
                          controller: _maxOffersController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.newWatchMaxOffersLabel,
                          ),
                        ),
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
                label: Text(
                  _isEditing ? l10n.editWatchSubmit : l10n.newWatchSubmit,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dois campos lado a lado em telas largas; empilhados (um por linha) em
/// telas estreitas, onde dividir a largura ao meio deixa os TextFields
/// apertados demais.
class _FieldPair extends StatelessWidget {
  final bool stacked;
  final Widget first;
  final Widget second;

  const _FieldPair({
    required this.stacked,
    required this.first,
    required this.second,
  });

  @override
  Widget build(BuildContext context) {
    if (stacked) {
      return Column(
        children: [first, const SizedBox(height: 12), second],
      );
    }
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 12),
        Expanded(child: second),
      ],
    );
  }
}
