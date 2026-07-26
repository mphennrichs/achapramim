import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/models/offer.dart';
import 'package:app/core/models/watch.dart';
import 'package:app/features/watches/widgets/offer_card.dart';
import 'package:app/features/watches/widgets/price_history_dialog.dart';
import 'package:app/features/watches/widgets/watch_card.dart';
import 'package:app/l10n/app_localizations.dart';

/// Garante que os cards/dialogs revisados para telas pequenas não estouram
/// (RenderFlex overflow) num viewport de celular real (390x844, iPhone
/// 12/13/14 padrão) — a checagem via `tester.takeException()` falha se
/// qualquer erro de layout for lançado durante o pump.
Future<void> pumpMobile(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
}

Watch _watch({required String name, List<String> marketplaces = const ['olx']}) {
  return Watch(
    id: 'w1',
    userId: 'u1',
    name: name,
    targetPriceCents: 250000,
    tolerancePercent: '10',
    maxOffers: 50,
    priceDropThresholdPercent: '10',
    active: true,
    keywords: const ['playstation', '5'],
    blockedWords: const [],
    marketplaces: marketplaces,
    city: null,
    state: null,
    keywordMatchMode: 'any',
  );
}

Offer _offer({required String title, bool available = true, bool monitored = false}) {
  return Offer(
    id: 'o1',
    marketplaceSlug: 'olx',
    url: 'https://olx.com.br/x',
    title: title,
    imageUrl: '',
    priceCents: 250000,
    classification: '0.87',
    available: available,
    createdAt: DateTime(2026, 1, 1),
    monitored: monitored,
  );
}

void main() {
  group('WatchCard em viewport mobile (390px)', () {
    testWidgets('nome curto não estoura', (tester) async {
      await pumpMobile(tester, WatchCard(watch: _watch(name: 'PS5')));
      expect(tester.takeException(), isNull);
    });

    testWidgets('nome longo com vários marketplaces não estoura', (tester) async {
      await pumpMobile(
        tester,
        WatchCard(
          watch: _watch(
            name: 'PlayStation 5 Slim Digital Edition novo lacrado com garantia',
            marketplaces: const ['olx', 'facebook_marketplace'],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('OfferCard em viewport mobile (390px)', () {
    testWidgets('título curto não estoura', (tester) async {
      await pumpMobile(
        tester,
        OfferCard(watchId: 'w1', offer: _offer(title: 'PS5 novo')),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('título longo, indisponível e monitorado não estoura', (tester) async {
      await pumpMobile(
        tester,
        OfferCard(
          watchId: 'w1',
          offer: _offer(
            title:
                'PlayStation 5 Slim Digital Edition novo lacrado com garantia estendida',
            available: false,
            monitored: true,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('PriceHistoryDialog em viewport mobile (390px)', () {
    testWidgets('largura fixa antiga (400) não estoura mais', (tester) async {
      await pumpMobile(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => PriceHistoryDialog(
                watchId: 'w1',
                offer: _offer(title: 'PS5 novo'),
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      // PriceHistoryDialog dispara uma request real ao montar (via
      // priceHistoryProvider) — sem servidor, o Dio falha rápido com
      // connection refused; drena esse timer antes do fim do teste para não
      // disparar o "Timer is still pending" do binding de teste.
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
