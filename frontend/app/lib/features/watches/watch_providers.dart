import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/offer.dart';
import '../../core/models/watch.dart';
import '../../core/providers.dart';

final watchListProvider = FutureProvider.autoDispose<List<Watch>>((ref) {
  return ref.watch(watchServiceProvider).list();
});

final watchProvider = FutureProvider.autoDispose.family<Watch, String>((
  ref,
  watchId,
) {
  return ref.watch(watchServiceProvider).get(watchId);
});

final offersProvider = FutureProvider.autoDispose.family<List<Offer>, String>((
  ref,
  watchId,
) {
  return ref.watch(watchServiceProvider).offers(watchId);
});

final scansProvider = FutureProvider.autoDispose
    .family<List<ScanSummary>, String>((ref, watchId) {
      return ref.watch(watchServiceProvider).scans(watchId);
    });

final priceHistoryProvider = FutureProvider.autoDispose
    .family<List<PricePoint>, ({String watchId, String offerId})>((ref, args) {
      return ref
          .watch(watchServiceProvider)
          .priceHistory(args.watchId, args.offerId);
    });
