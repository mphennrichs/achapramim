import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/models/notification.dart';
import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';

final _notificationsProvider = FutureProvider.autoDispose<
  List<AppNotification>
>((ref) {
  return ref.watch(notificationServiceProvider).list();
});

void showNotificationsDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => const _NotificationsDialog(),
  );
}

class _NotificationsDialog extends ConsumerWidget {
  const _NotificationsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final notificationsAsync = ref.watch(_notificationsProvider);

    // Largura fixa (420) estoura em telas estreitas — limitada ao espaço
    // disponível descontando o insetPadding padrão do AlertDialog (40 de
    // cada lado).
    final maxWidth = MediaQuery.sizeOf(context).width - 80;

    return AlertDialog(
      title: Text(l10n.notificationsTitle),
      content: SizedBox(
        width: maxWidth < 420 ? maxWidth : 420,
        height: 400,
        child: notificationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(l10n.notificationsLoadError(error.toString())),
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return Center(
                child: Text(
                  l10n.notificationsEmpty,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              );
            }
            return ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (context, _) => const Divider(height: 1),
              itemBuilder: (context, index) => _NotificationTile(
                notification: notifications[index],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await ref.read(notificationServiceProvider).markAllRead();
            ref.invalidate(_notificationsProvider);
            ref.invalidate(unreadNotificationCountProvider);
          },
          child: Text(l10n.notificationsMarkAllRead),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.notificationsClose),
        ),
      ],
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final priceLabel =
        'R\$ ${(notification.offerPriceCents / 100).toStringAsFixed(2).replaceAll('.', ',')}';

    return ListTile(
      tileColor: notification.isRead
          ? null
          : scheme.primaryContainer.withValues(alpha: 0.3),
      leading: Icon(Icons.trending_down, color: scheme.primary),
      title: Text(l10n.notificationsPriceDropTitle(notification.watchName)),
      subtitle: Text(
        '${l10n.notificationsPriceDropBody(notification.offerTitle, priceLabel)}\n'
        '${dateFormat.format(notification.createdAt.toLocal())}',
      ),
      isThreeLine: true,
      onTap: () async {
        if (!notification.isRead) {
          await ref
              .read(notificationServiceProvider)
              .markRead(notification.id);
          ref.invalidate(_notificationsProvider);
          ref.invalidate(unreadNotificationCountProvider);
        }
        if (context.mounted) {
          Navigator.of(context).pop();
          context.push('/watches/${notification.watchId}');
        }
      },
    );
  }
}
