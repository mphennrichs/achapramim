import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/status_colors.dart';

/// Mesmo padrão do backend (username_format) — validação client-side só
/// para feedback imediato, o backend permanece a fonte de verdade.
final usernamePattern = RegExp(r'^[a-z0-9_]{3,30}$');

enum _UsernameCheckState { idle, checking, available, taken, invalid }

/// Campo de username com checagem de disponibilidade ao vivo (debounced) via
/// GET /api/users/username-available — reutilizado no diálogo de criação e
/// no de edição, já que a validação é idêntica nos dois casos.
class UsernameField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String? excludeCurrentValue;
  final ValueChanged<bool> onValidityChanged;

  const UsernameField({
    super.key,
    required this.controller,
    required this.onValidityChanged,
    this.excludeCurrentValue,
  });

  @override
  ConsumerState<UsernameField> createState() => _UsernameFieldState();
}

class _UsernameFieldState extends ConsumerState<UsernameField> {
  _UsernameCheckState _state = _UsernameCheckState.idle;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    final value = widget.controller.text.trim();

    if (value.isEmpty) {
      setState(() => _state = _UsernameCheckState.idle);
      widget.onValidityChanged(true); // vazio é válido (campo opcional)
      return;
    }
    if (value == widget.excludeCurrentValue) {
      setState(() => _state = _UsernameCheckState.idle);
      widget.onValidityChanged(true);
      return;
    }
    if (!usernamePattern.hasMatch(value)) {
      setState(() => _state = _UsernameCheckState.invalid);
      widget.onValidityChanged(false);
      return;
    }

    setState(() => _state = _UsernameCheckState.checking);
    widget.onValidityChanged(false);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final available = await ref
            .read(adminServiceProvider)
            .isUsernameAvailable(value);
        if (!mounted || widget.controller.text.trim() != value) return;
        setState(
          () => _state = available
              ? _UsernameCheckState.available
              : _UsernameCheckState.taken,
        );
        widget.onValidityChanged(available);
      } on DioException {
        if (!mounted) return;
        setState(() => _state = _UsernameCheckState.idle);
        widget.onValidityChanged(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    final (helperText, helperColor) = switch (_state) {
      _UsernameCheckState.idle => (
        l10n.adminUsersUsernameHint,
        scheme.onSurfaceVariant,
      ),
      _UsernameCheckState.checking => (
        l10n.adminUsersUsernameChecking,
        scheme.onSurfaceVariant,
      ),
      _UsernameCheckState.available => (
        l10n.adminUsersUsernameAvailable,
        successColor,
      ),
      _UsernameCheckState.taken => (l10n.adminUsersUsernameTaken, scheme.error),
      _UsernameCheckState.invalid => (
        l10n.adminUsersUsernameInvalid,
        scheme.error,
      ),
    };

    return TextField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: l10n.adminUsersUsernameLabel,
        helperText: helperText,
        helperStyle: TextStyle(color: helperColor),
        helperMaxLines: 2,
        suffixIcon: _state == _UsernameCheckState.checking
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
    );
  }
}
