import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/user_profile.dart';
import '../../core/models/watch.dart';
import '../../core/providers.dart';

final allWatchesProvider = FutureProvider.autoDispose<List<Watch>>((ref) {
  return ref.watch(watchServiceProvider).listAll();
});

/// Um Alerta específico da listagem admin, já com dono, keywords, palavras
/// bloqueadas e região — tudo que `GET /api/watches?all=true` devolve (o
/// `GET /api/watches/{id}` do dono não traz os campos de dono).
final adminWatchProvider = FutureProvider.autoDispose.family<Watch, String>((
  ref,
  watchId,
) async {
  final watches = await ref.watch(allWatchesProvider.future);
  return watches.firstWhere((w) => w.id == watchId);
});

final adminUsersProvider = FutureProvider.autoDispose<List<UserProfile>>((ref) {
  return ref.watch(adminServiceProvider).listUsers();
});
