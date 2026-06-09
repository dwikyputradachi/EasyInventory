import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../services/api_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    final data = await ApiService.getNotifications();

    if (!mounted) return;

    setState(() {
      notifications = data;
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> get groupedNotifications {
    final Map<String, Map<String, dynamic>> grouped = {};

    for (final item in notifications) {
      final idItem = item['id_item'].toString();

      if (!grouped.containsKey(idItem)) {
        grouped[idItem] = {
          'id_item': item['id_item'],
          'title': item['title'],
          'types': <String>[],
          'messages': <String>[],
          'ids': <dynamic>[],
        };
      }

      grouped[idItem]!['types'].add(item['type']);
      grouped[idItem]!['messages'].add(item['message']);
      grouped[idItem]!['ids'].add(item['id_notification']);
    }

    return grouped.values.toList();
  }

  Future<void> markAsRead(Map<String, dynamic> group) async {
    final ids = group['ids'] as List<dynamic>;

    for (final id in ids) {
      if (id != null) {
        await ApiService.markNotificationAsRead(id.toString());
      }
    }

    await fetchNotifications();
  }

  Future<void> markAllAsRead() async {
    if (notifications.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text(
          'All notifications will be removed from this list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ApiService.markAllNotificationsAsRead();

    if (success) {
      await fetchNotifications();
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to clear notifications')),
      );
    }
  }

  Color _color(List<String> types) {
    if (types.contains('expired')) {
      return AppColors.danger;
    }

    if (types.contains('low_stock') || types.contains('near_expired')) {
      return AppColors.warning;
    }

    return AppColors.primary;
  }

  String _label(List<String> types) {
    final labels = <String>[];

    if (types.contains('low_stock')) {
      labels.add('Low Stock');
    }

    if (types.contains('near_expired')) {
      labels.add('Near Expired');
    }

    if (types.contains('expired')) {
      labels.add('Expired');
    }

    return labels.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupedNotifications;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Clear all',
            icon: const Icon(
              Icons.delete_sweep_outlined,
              color: AppColors.danger,
            ),
            onPressed: markAllAsRead,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchNotifications,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: grouped.isEmpty ? 1 : grouped.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Need Attention',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Reminders to keep your household organized',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (grouped.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 50),
                            child: Center(
                              child: Text(
                                'No notifications',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }

                  final item = grouped[index - 1];
                  final types = List<String>.from(item['types']);
                  final messages = List<String>.from(item['messages']);
                  final color = _color(types);

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _label(types),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ...messages.map(
                                  (message) => Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Text(
                                      message,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => markAsRead(item),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}