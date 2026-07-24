import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persiste a preferência de tema (claro/escuro/sistema) localmente no
/// dispositivo — é preferência de UI, não dado de negócio, então não vai
/// para o backend nem é sincronizada entre dispositivos.
class ThemeStorage {
  final FlutterSecureStorage _storage;

  ThemeStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _themeModeKey = 'theme_mode';

  Future<ThemeMode> readThemeMode() async {
    final value = await _storage.read(key: _themeModeKey);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _storage.write(key: _themeModeKey, value: mode.name);
  }
}
