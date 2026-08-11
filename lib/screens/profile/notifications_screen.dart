import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: uid == null
          ? const SizedBox.shrink()
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: NotificationService().streamNotifications(uid),
              builder: (context, snapshot) {
                final notifications = snapshot.data ?? [];
                if (notifications.isEmpty) {
                  return Center(child: Text('No notifications yet', style: AppTextStyles.supporting));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.notifications_outlined, color: AppColors.primary),
                      title: Text(n['title'] ?? '', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                      subtitle: Text(n['body'] ?? '', style: AppTextStyles.supporting),
                    );
                  },
                );
              },
            ),
    );
  }
}