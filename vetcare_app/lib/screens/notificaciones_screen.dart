import 'package:flutter/material.dart';
import 'package:vetcare_app/services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      final data = await NotificationService.getLocalNotifications();
      setState(() => _notifications = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar notificaciones'),
        content: const Text('¿Deseas eliminar todas las notificaciones?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await NotificationService.clearNotifications();
      _loadNotifications();
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final notif in _notifications) {
      final dateStr = notif['date'] as String?;
      if (dateStr == null) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;

      final key = DateFormat('dd/MM/yyyy').format(date);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(notif);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate();
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          IconButton(onPressed: _loadNotifications, icon: const Icon(Icons.refresh)),
          if (_notifications.isNotEmpty)
            IconButton(onPressed: _clearAll, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No hay notificaciones', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: dates.length,
                  itemBuilder: (context, i) {
                    final date = dates[i];
                    final notifs = grouped[date]!;
                    return _DateGroup(date: date, notifications: notifs);
                  },
                ),
    );
  }
}

class _DateGroup extends StatelessWidget {
  final String date;
  final List<Map<String, dynamic>> notifications;

  const _DateGroup({required this.date, required this.notifications});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(
            date,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        ...notifications.map((notif) => _NotificationCard(notification: notif)),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = notification['title'] as String? ?? 'Sin título';
    final body = notification['body'] as String? ?? '';
    final dateStr = notification['date'] as String?;
    DateTime? date;
    if (dateStr != null) date = DateTime.tryParse(dateStr);
    final timeStr = date != null ? DateFormat.Hm().format(date) : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.notifications, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (body.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            if (timeStr.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(timeStr, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
            ],
          ],
        ),
        isThreeLine: body.isNotEmpty,
      ),
    );
  }
}

