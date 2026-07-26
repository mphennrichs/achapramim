import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import 'username_field.dart';

class CreateUserDialog extends ConsumerStatefulWidget {
  final VoidCallback onCreated;

  const CreateUserDialog({super.key, required this.onCreated});

  @override
  ConsumerState<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<CreateUserDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  String _role = 'user';
  bool _usernameValid = true;
  bool _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_usernameValid) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final username = _usernameController.text.trim();
    try {
      await ref
          .read(adminServiceProvider)
          .createUser(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            role: _role,
            username: username.isEmpty ? null : username,
          );
      widget.onCreated();
      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(
          context,
        )!.adminUsersCreateError('${e.response?.data ?? e.message}');
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
      title: Text(l10n.adminUsersCreate),
      content: SizedBox(
        width: maxWidth < 400 ? maxWidth : 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.adminUsersNameLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: l10n.adminUsersEmailLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.adminUsersPasswordLabel,
              ),
            ),
            const SizedBox(height: 12),
            UsernameField(
              controller: _usernameController,
              onValidityChanged: (valid) =>
                  setState(() => _usernameValid = valid),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: InputDecoration(labelText: l10n.adminUsersRoleLabel),
              items: [
                DropdownMenuItem(
                  value: 'user',
                  child: Text(l10n.adminUsersRoleUser),
                ),
                DropdownMenuItem(
                  value: 'admin',
                  child: Text(l10n.adminUsersRoleAdmin),
                ),
              ],
              onChanged: (value) => setState(() => _role = value ?? 'user'),
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
          onPressed: _saving || !_usernameValid ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.adminUsersCreateSubmit),
        ),
      ],
    );
  }
}
