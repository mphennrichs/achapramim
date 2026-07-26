import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/user_profile.dart';
import '../../core/models/watch.dart';
import '../../core/providers.dart';

final allWatchesProvider = FutureProvider.autoDispose<List<Watch>>((ref) {
  return ref.watch(watchServiceProvider).listAll();
});

final adminUsersProvider = FutureProvider.autoDispose<List<UserProfile>>((
  ref,
) {
  return ref.watch(adminServiceProvider).listUsers();
});
