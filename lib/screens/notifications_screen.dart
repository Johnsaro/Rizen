import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../models/game_notification.dart';
import '../theme/night_guild_background.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CultivationBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () => Navigator.pop(context),
                      color: cs.onSurface,
                    ),
                    Expanded(
                      child: Text(
                        'DIVINE SENSE',
                        style: GoogleFonts.cinzel(
                          color: cs.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    ValueListenableBuilder<List<GameNotification>>(
                      valueListenable: notificationsNotifier,
                      builder: (_, notifications, _) => TextButton(
                        onPressed: notifications.isEmpty
                            ? null
                            : () => gameService.clearNotifications(),
                        child: Text(
                          'CLEAR ALL',
                          style: TextStyle(
                            color: notifications.isEmpty
                                ? cs.primary.withValues(alpha: 0.4)
                                : cs.primary,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<List<GameNotification>>(
                  valueListenable: notificationsNotifier,
                  builder: (_, notifications, _) {
                    if (notifications.isEmpty) {
                      return Center(
                        child: Text(
                          'Your divine sense is quiet. No whispers.',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.45),
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: _buildList(notifications, cs),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildList(
    List<GameNotification> notifications,
    ColorScheme cs,
  ) {
    final List<Widget> items = [];
    String? lastGroup;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final notif in notifications) {
      final notifDay = DateTime(
        notif.createdAt.year,
        notif.createdAt.month,
        notif.createdAt.day,
      );
      final String group;
      if (notifDay == today) {
        group = 'RECENT WHISPERS';
      } else if (notifDay == yesterday) {
        group = 'PRIOR CYCLE';
      } else {
        group = 'ANCIENT RECORDS';
      }

      if (group != lastGroup) {
        lastGroup = group;
        items.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 6),
            child: Text(
              group,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.35),
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
      items.add(_NotificationCard(item: notif));
    }

    return items;
  }
}

class _NotificationCard extends StatelessWidget {
  final GameNotification item;

  const _NotificationCard({required this.item});

  static IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.checkin:
        return Icons.self_improvement;
      case NotificationType.questComplete:
        return Icons.task_alt;
      case NotificationType.combatVictory:
        return Icons.stars;
      case NotificationType.levelUp:
        return Icons.upgrade;
      case NotificationType.streakMilestone:
        return Icons.local_fire_department;
      case NotificationType.streakBreak:
        return Icons.warning_amber_rounded;
      case NotificationType.achievement:
        return Icons.auto_awesome;
      case NotificationType.qiDeviation:
        return Icons.warning_amber;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }

  static String _timeLabel(DateTime createdAt) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.isRead
            ? cs.surface
            : Color.alphaBlend(cs.primary.withValues(alpha: 0.06), cs.surface),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_iconFor(item.type), size: 18, color: cs.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _rethemeMessage(item.message),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _timeLabel(item.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _rethemeMessage(String msg) {
    return msg
        .replaceAll('Quest', 'Trial')
        .replaceAll('XP', 'Qi')
        .replaceAll('Level', 'Realm Level')
        .replaceAll('streak', 'dao heart');
  }
}
