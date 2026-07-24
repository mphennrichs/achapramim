import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/user_profile.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l10n.profileLoadError(error.toString()))),
        data: (profile) => _ProfileBody(profile: profile),
      ),
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  final UserProfile profile;

  const _ProfileBody({required this.profile});

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  late final _nameController = TextEditingController(text: widget.profile.name);
  late final _usernameController = TextEditingController(text: widget.profile.username);

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _savingProfile = false;
  String? _profileError;

  bool _changingPassword = false;
  String? _passwordError;
  String? _passwordSuccess;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();

    setState(() {
      _savingProfile = true;
      _profileError = null;
    });

    try {
      await ref.read(meServiceProvider).updateProfile(name: name, username: username);
      ref.invalidate(currentUserProfileProvider);
    } on DioException catch (e) {
      setState(() {
        _profileError = e.response?.statusCode == 409
            ? l10n.setUsernameTaken
            : l10n.profilePasswordChangeError;
      });
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    final l10n = AppLocalizations.of(context)!;
    final newPassword = _newPasswordController.text;

    if (newPassword.length < 6) {
      setState(() => _passwordError = l10n.profilePasswordTooShort);
      return;
    }
    if (newPassword != _confirmPasswordController.text) {
      setState(() => _passwordError = l10n.profilePasswordMismatch);
      return;
    }

    setState(() {
      _changingPassword = true;
      _passwordError = null;
      _passwordSuccess = null;
    });

    try {
      await ref.read(meServiceProvider).changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: newPassword,
          );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() => _passwordSuccess = l10n.profilePasswordChangeSuccess);
    } on DioException catch (e) {
      setState(() {
        _passwordError = e.response?.statusCode == 401
            ? l10n.profileCurrentPasswordWrong
            : l10n.profilePasswordChangeError;
      });
    } finally {
      if (mounted) setState(() => _changingPassword = false);
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
                    TextField(
                      readOnly: true,
                      controller: TextEditingController(text: widget.profile.email),
                      decoration: InputDecoration(labelText: l10n.profileEmailLabel),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: l10n.profileNameLabel),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(labelText: l10n.profileUsernameLabel),
                    ),
                    if (_profileError != null) ...[
                      const SizedBox(height: 12),
                      Text(_profileError!, style: TextStyle(color: scheme.error)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _savingProfile ? null : _saveProfile,
                      child: _savingProfile
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.profileSaveChanges),
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
                    Text(l10n.profileChangePasswordTitle, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: l10n.profileCurrentPasswordLabel),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: l10n.profileNewPasswordLabel),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: l10n.profileConfirmNewPasswordLabel),
                      onSubmitted: (_) => _changePassword(),
                    ),
                    if (_passwordError != null) ...[
                      const SizedBox(height: 12),
                      Text(_passwordError!, style: TextStyle(color: scheme.error)),
                    ],
                    if (_passwordSuccess != null) ...[
                      const SizedBox(height: 12),
                      Text(_passwordSuccess!, style: TextStyle(color: scheme.primary)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _changingPassword ? null : _changePassword,
                      child: _changingPassword
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.profileChangePasswordTitle),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
