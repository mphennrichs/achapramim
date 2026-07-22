import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/watch.dart';
import '../../core/providers.dart';
import 'app_shell.dart';

const _availableMarketplaces = ['olx', 'mercado_livre', 'facebook_marketplace'];
const _marketplaceLabels = {
  'olx': 'OLX Brasil',
  'mercado_livre': 'Mercado Livre',
  'facebook_marketplace': 'FB Marketplace',
};

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
  final _linkController = TextEditingController();
  final _keywordInputController = TextEditingController();
  final _blockedInputController = TextEditingController();

  final List<String> _keywords = [];
  final List<String> _blockedWords = [];
  final Set<String> _selectedMarketplaces = {'olx'};

  bool _analyzingLink = false;
  bool _saving = false;
  bool _aiFilled = false;
  bool _partialFailure = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _targetPriceController.dispose();
    _toleranceController.dispose();
    _thresholdController.dispose();
    _maxOffersController.dispose();
    _linkController.dispose();
    _keywordInputController.dispose();
    _blockedInputController.dispose();
    super.dispose();
  }

  Future<void> _analyzeLink() async {
    final url = _linkController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _analyzingLink = true;
      _errorMessage = null;
      _partialFailure = false;
    });

    try {
      final proposal = await ref.read(linkPreviewServiceProvider).preview(url);
      setState(() {
        if (proposal.name.isNotEmpty) _nameController.text = proposal.name;
        if (proposal.targetPriceCents > 0) {
          _targetPriceController.text =
              (proposal.targetPriceCents / 100).toStringAsFixed(2);
        }
        for (final keyword in proposal.keywords) {
          if (!_keywords.contains(keyword)) _keywords.add(keyword);
        }
        for (final blocked in proposal.blockedWords) {
          if (!_blockedWords.contains(blocked)) _blockedWords.add(blocked);
        }
        _aiFilled = true;
        _partialFailure = proposal.partialFailure;
      });
    } on DioException {
      setState(() {
        _errorMessage = 'Não foi possível analisar o link agora. Preencha manualmente.';
      });
    } finally {
      if (mounted) setState(() => _analyzingLink = false);
    }
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
        _errorMessage = 'Preencha nome, preço-alvo e ao menos um marketplace.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

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
    );

    try {
      await ref.read(watchServiceProvider).create(watch);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on DioException catch (e) {
      setState(() {
        _errorMessage = 'Falha ao salvar Watch: ${e.response?.data ?? e.message}';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppShell(
      title: 'Nova Consulta',
      selectedIndex: 1,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.link, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Criar a partir de Link',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cole a URL de um anúncio para gerar uma Proposta de Preenchimento — sempre editável, nunca cria o Watch sozinha.',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _linkController,
                              decoration: const InputDecoration(
                                hintText: 'https://www.olx.com.br/...',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: _analyzingLink ? null : _analyzeLink,
                            icon: _analyzingLink
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: const Text('Analisar'),
                          ),
                        ],
                      ),
                      if (_partialFailure) ...[
                        const SizedBox(height: 8),
                        Text(
                          'A análise foi parcial — revise os campos preenchidos e complete o restante manualmente.',
                          style: TextStyle(color: scheme.error, fontSize: 12),
                        ),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Identificação do Watch',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          if (_aiFilled)
                            Chip(
                              avatar: const Icon(Icons.auto_awesome, size: 16),
                              label: const Text('Sugerido por IA'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nome do Watch'),
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
                      label: 'Palavras-Chave',
                      inputController: _keywordInputController,
                      words: _keywords,
                      onAdd: _addKeyword,
                      onRemove: (word) => setState(() => _keywords.remove(word)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _WordListCard(
                      label: 'Palavras Bloqueadas',
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
                      Text('Marketplaces Ativos', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final slug in _availableMarketplaces)
                            FilterChip(
                              label: Text(_marketplaceLabels[slug]!),
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
                      Text('Financeiro e Limites', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _targetPriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Preço-Alvo (BRL)'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _toleranceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Tolerância (%)'),
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
                              decoration: const InputDecoration(
                                labelText: 'Gatilho de Queda (%)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _maxOffersController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Máximo de Ofertas'),
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
                label: const Text('Ativar Monitoramento'),
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
  final TextEditingController inputController;
  final List<String> words;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final bool isError;

  const _WordListCard({
    required this.label,
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
                    decoration: const InputDecoration(hintText: 'Adicionar...'),
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
