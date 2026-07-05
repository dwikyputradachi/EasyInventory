import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../services/api_service.dart';
import 'package:quickalert/quickalert.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<dynamic> notifications = [];
  List<Map<String, dynamic>> groupedNotificationsList = []; 
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final data = await ApiService.getNotifications();
      if (!mounted) return;

      final Map<String, Map<String, dynamic>> grouped = {};
      for (final item in data) {
        final idItem = item['id_item']?.toString() ?? '';
        if (idItem.isEmpty) continue; 

        if (!grouped.containsKey(idItem)) {
          grouped[idItem] = {
            'id_item': item['id_item'],
            'title': item['title'],
            'types': <String>[],
            'messages': <String>[],
            'ids': <dynamic>[],
          };
        }
        grouped[idItem]!['types'].add(item['type'] ?? '');
        grouped[idItem]!['messages'].add(item['message'] ?? '');
        grouped[idItem]!['ids'].add(item['id_notification']);
      }

      setState(() {
        notifications = data;
        groupedNotificationsList = grouped.values.toList(); // Simpan hasilnya ke variabel
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

Future<void> markAsRead(Map<String, dynamic> group) async {
  QuickAlert.show(
    context: context,
    type: QuickAlertType.confirm,
    title: "Delete Notification",
    text: "Are you sure you want to delete this notification?",
    confirmBtnText: "Yes",
    cancelBtnText: "No",
    onConfirmBtnTap: () async {
      Navigator.pop(context);

      final ids = group['ids'] as List<dynamic>? ?? [];

      final List<Future<dynamic>> futures = [];

      for (final id in ids) {
        if (id != null) {
          futures.add(
            ApiService.markNotificationAsRead(id.toString()),
          );
        }
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }

      await fetchNotifications();

      if (!mounted) return;

      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: "Deleted",
        text: "Notification deleted successfully.",
      );
    },
  );
}

  Future<void> markAllAsRead() async {
  if (notifications.isEmpty) return;

  QuickAlert.show(
    context: context,
    type: QuickAlertType.confirm,
    title: "Clear Notifications",
    text: "Are you sure you want to delete all notifications?",
    confirmBtnText: "Yes",
    cancelBtnText: "No",
    onConfirmBtnTap: () async {
      Navigator.pop(context);

      final success =
          await ApiService.markAllNotificationsAsRead();

      if (success) {
        await fetchNotifications();

        if (!mounted) return;

        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: "Success",
          text: "All notifications have been deleted.",
        );
      } else {
        if (!mounted) return;

        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: "Failed",
          text: "Failed to delete notifications.",
        );
      }
    },
  );
}

  Color _color(List<String> types) {
    if (types.contains('expired')) return AppColors.danger;
    if (types.contains('low_stock') || types.contains('near_expired')) return AppColors.warning;
    return AppColors.primary;
  }

  String _label(List<String> types) {
    final labels = <String>[];
    if (types.contains('low_stock')) labels.add('Low Stock');
    if (types.contains('near_expired')) labels.add('Near Expired');
    if (types.contains('expired')) labels.add('Expired');
    return labels.join(' • ');
  }


  @override
  Widget build(BuildContext context) {
    final grouped = groupedNotificationsList; 

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
                            onPressed: () async {
                              if (isLoading) return; 
                              await markAsRead(item);
                            },
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