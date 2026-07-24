import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/user_profile.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

final _usersProvider = FutureProvider.autoDispose<List<UserProfile>>((ref) {
  return ref.watch(adminServiceProvider).listUsers();
});

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final usersAsync = ref.watch(_usersProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateDialog(context, ref),
        icon: const Icon(Icons.person_add),
        label: Text(l10n.adminUsersCreate),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l10n.adminUsersLoadError(error.toString()))),
        data: (users) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (context, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _UserCard(user: users[index]),
        ),
      ),
    );
  }

  void _openCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _CreateUserDialog(
        onCreated: () => ref.invalidate(_usersProvider),
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final UserProfile user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(user.email, style: TextStyle(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(user.role == 'admin' ? l10n.adminUsersRoleAdmin : l10n.adminUsersRoleUser),
                      ),
                      Chip(
                        label: Text(user.active ? l10n.adminUsersActive : l10n.adminUsersInactive),
                        backgroundColor: user.active
                            ? scheme.primaryContainer
                            : scheme.errorContainer,
                      ),
                      if (user.usernamePending)
                        Chip(label: Text(l10n.adminUsersUsernamePending)),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                final admin = ref.read(adminServiceProvider);
                try {
                  if (value == 'toggle_active') {
                    await admin.setUserActive(user.id, !user.active);
                  } else if (value == 'toggle_role') {
                    await admin.setUserRole(user.id, user.role == 'admin' ? 'user' : 'admin');
                  }
                  ref.invalidate(_usersProvider);
                } on DioException {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.adminUsersUpdateError)),
                    );
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle_active',
                  child: Text(user.active ? l10n.adminUsersInactive : l10n.adminUsersActive),
                ),
                PopupMenuItem(
                  value: 'toggle_role',
                  child: Text(user.role == 'admin' ? l10n.adminUsersRoleUser : l10n.adminUsersRoleAdmin),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateUserDialog extends ConsumerStatefulWidget {
  final VoidCallback onCreated;

  const _CreateUserDialog({required this.onCreated});

  @override
  ConsumerState<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<_CreateUserDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'user';
  bool _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(adminServiceProvider).createUser(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            role: _role,
          );
      widget.onCreated();
      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!
            .adminUsersCreateError('${e.response?.data ?? e.message}');
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(l10n.adminUsersCreate),
      content: SizedBox(
        width: 400,
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
              decoration: InputDecoration(labelText: l10n.adminUsersPasswordLabel),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: InputDecoration(labelText: l10n.adminUsersRoleLabel),
              items: [
                DropdownMenuItem(value: 'user', child: Text(l10n.adminUsersRoleUser)),
                DropdownMenuItem(value: 'admin', child: Text(l10n.adminUsersRoleAdmin)),
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
          onPressed: _saving ? null : _submit,
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
