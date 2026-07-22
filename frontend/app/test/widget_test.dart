import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/auth/login_screen.dart';
import 'package:app/theme/app_theme.dart';

void main() {
  testWidgets('Tela de login exibe marca e formulário de acesso', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Achapramim'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'E-mail'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
  });

  test('AppTheme.light() usa brightness light por padrão', () {
    expect(AppTheme.light().brightness, Brightness.light);
  });
}
