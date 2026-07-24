import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/scan_settings.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

final _scanSettingsProvider = FutureProvider.autoDispose<ScanSettings>((ref) {
  return ref.watch(adminServiceProvider).getScanSettings();
});

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(_scanSettingsProvider);

    return Scaffold(
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l10n.adminSettingsLoadError(error.toString()))),
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
  late final _minController =
      TextEditingController(text: widget.settings.minIntervalMinutes.toString());
  late final _maxController =
      TextEditingController(text: widget.settings.maxIntervalMinutes.toString());

  bool _saving = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final min = int.tryParse(_minController.text.trim());
    final max = int.tryParse(_maxController.text.trim());

    if (min == null || max == null || max < min) {
      setState(() {
        _errorMessage = l10n.adminSettingsValidationError;
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await ref.read(adminServiceProvider).updateScanSettings(
            minIntervalMinutes: min,
            maxIntervalMinutes: max,
          );
      setState(() => _successMessage = l10n.adminSettingsSaveSuccess);
    } on DioException {
      setState(() => _errorMessage = l10n.adminSettingsSaveError);
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
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.adminSettingsScanTitle, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Text(
                  l10n.adminSettingsScanDescription,
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l10n.adminSettingsMinIntervalLabel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _maxController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l10n.adminSettingsMaxIntervalLabel),
                      ),
                    ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: TextStyle(color: scheme.error)),
                ],
                if (_successMessage != null) ...[
                  const SizedBox(height: 12),
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
        ),
      ),
    );
  }
}
