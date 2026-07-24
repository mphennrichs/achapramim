import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/theme_storage.dart';

/// Preferência de tema do usuário — carrega do storage local ao iniciar
/// (super(ThemeMode.system) é o valor inicial só até a leitura assíncrona
/// resolver, evitando flash de um tema errado antes de saber a preferência
/// salva) e persiste a cada mudança feita na tela de Perfil.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final ThemeStorage _storage;

  ThemeModeNotifier(this._storage) : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    state = await _storage.readThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _storage.saveThemeMode(mode);
  }
}

final themeStorageProvider = Provider<ThemeStorage>((ref) => ThemeStorage());

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier(ref.watch(themeStorageProvider));
});
