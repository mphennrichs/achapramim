import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_profile.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../admin_providers.dart';
import 'set_username_dialog.dart';

class UserCard extends ConsumerWidget {
  final UserProfile user;

  const UserCard({super.key, required this.user});

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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          user.role == 'admin'
                              ? l10n.adminUsersRoleAdmin
                              : l10n.adminUsersRoleUser,
                        ),
                      ),
                      Chip(
                        label: Text(
                          user.active
                              ? l10n.adminUsersActive
                              : l10n.adminUsersInactive,
                          style: TextStyle(
                            color: user.active
                                ? scheme.onPrimaryContainer
                                : scheme.onErrorContainer,
                          ),
                        ),
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
                if (value == 'edit_username') {
                  showDialog(
                    context: context,
                    builder: (context) => SetUsernameDialog(
                      user: user,
                      onSaved: () => ref.invalidate(adminUsersProvider),
                    ),
                  );
                  return;
                }
                final admin = ref.read(adminServiceProvider);
                try {
                  if (value == 'toggle_active') {
                    await admin.setUserActive(user.id, !user.active);
                  } else if (value == 'toggle_role') {
                    await admin.setUserRole(
                      user.id,
                      user.role == 'admin' ? 'user' : 'admin',
                    );
                  }
                  ref.invalidate(adminUsersProvider);
                } on DioException {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.adminUsersUpdateError,
                        ),
                      ),
                    );
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle_active',
                  child: Text(
                    user.active
                        ? l10n.adminUsersInactive
                        : l10n.adminUsersActive,
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_role',
                  child: Text(
                    user.role == 'admin'
                        ? l10n.adminUsersRoleUser
                        : l10n.adminUsersRoleAdmin,
                  ),
                ),
                PopupMenuItem(
                  value: 'edit_username',
                  child: Text(
                    user.usernamePending
                        ? l10n.adminUsersSetUsername
                        : l10n.adminUsersEditUsername,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
