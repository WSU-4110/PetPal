import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../models/notification.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final DBService _dbService = DBService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final all = await _dbService.getAllNotifications();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    if (!mounted) return;

    setState(() {
      _notifications = all.where((n) {
        final scheduled = n.scheduledAt;
        return scheduled != null &&
            scheduled.isBefore(todayEnd);
      }).toList();
      _isLoading = false;
    });
  }


  Future<void> _deleteNotification(int id) async {
    // Capture messenger before async operations
    final messenger = ScaffoldMessenger.of(context);
    
    await _dbService.deleteNotification(id);
    await _loadNotifications();
    
    if (!mounted) return;
    
    messenger.showSnackBar(
      const SnackBar(content: Text('Notification deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? const Center(
        child: Text(
          'No notifications yet',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final n = _notifications[index];
          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(n.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (n.body != null) Text(n.body!),
                  if (n.scheduledAt != null)
                    Text(
                      'Scheduled: ${n.scheduledAt}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  if (n.deliveredAt != null)
                    Text(
                      'Delivered: ${n.deliveredAt}',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteNotification(n.id!),
              ),
            ),
          );
        },
      ),
    );
  }
}