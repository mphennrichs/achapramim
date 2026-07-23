import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

/// Tela do Primeiro Acesso (ver CONTEXT.md): exibida sempre que o User
/// autenticado ainda não definiu seu Username. Bloqueia o restante do app —
/// não há como navegar para fora daqui sem concluir esta etapa.
class SetUsernameScreen extends ConsumerStatefulWidget {
  const SetUsernameScreen({super.key});

  @override
  ConsumerState<SetUsernameScreen> createState() => _SetUsernameScreenState();
}

class _SetUsernameScreenState extends ConsumerState<SetUsernameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _saving = false;
  String? _errorMessage;

  static final _usernamePattern = RegExp(r'^[a-z0-9_]{3,30}$');

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await ref.read(meServiceProvider).setUsername(_usernameController.text.trim());
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/watches');
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.statusCode == 409
            ? 'Este username já está em uso. Escolha outro.'
            : 'Não foi possível salvar. Tente novamente.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.person_pin, color: scheme.primary, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Escolha seu username',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Identificador único e permanente — não poderá ser alterado depois. '
                    'Você poderá usá-lo para entrar, junto com seu e-mail.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _usernameController,
                    autofocus: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      helperText: 'Minúsculas, números e underscore. 3 a 30 caracteres.',
                    ),
                    validator: (value) {
                      if (value == null || !_usernamePattern.hasMatch(value)) {
                        return 'Use 3 a 30 letras minúsculas, números ou _';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(_errorMessage!, style: TextStyle(color: scheme.error)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Confirmar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
