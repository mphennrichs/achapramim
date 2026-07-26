import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_profile.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import 'username_field.dart';

class SetUsernameDialog extends ConsumerStatefulWidget {
  final UserProfile user;
  final VoidCallback onSaved;

  const SetUsernameDialog({super.key, required this.user, required this.onSaved});

  @override
  ConsumerState<SetUsernameDialog> createState() => _SetUsernameDialogState();
}

class _SetUsernameDialogState extends ConsumerState<SetUsernameDialog> {
  late final _usernameController = TextEditingController(
    text: widget.user.username ?? '',
  );
  bool _valid = true;
  bool _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty || !_valid) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(adminServiceProvider)
          .setUsername(widget.user.id, username);
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(
          context,
        )!.adminUsersUsernameSaveError('${e.response?.data ?? e.message}');
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    // Largura fixa (400) estoura em telas estreitas — limitada ao espaço
    // disponível descontando o insetPadding padrão do AlertDialog (40 de
    // cada lado).
    final maxWidth = MediaQuery.sizeOf(context).width - 80;

    return AlertDialog(
      title: Text(l10n.adminUsersUsernameDialogTitle(widget.user.name)),
      content: SizedBox(
        width: maxWidth < 400 ? maxWidth : 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UsernameField(
              controller: _usernameController,
              excludeCurrentValue: widget.user.username,
              onValidityChanged: (valid) => setState(() => _valid = valid),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: TextStyle(color: scheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.adminUsersCancel),
        ),
        FilledButton(
          onPressed:
              _saving || !_valid || _usernameController.text.trim().isEmpty
              ? null
              : _submit,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.adminUsersUsernameSave),
        ),
      ],
    );
  }
}
