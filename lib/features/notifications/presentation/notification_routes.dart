import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../domain/app_notification.dart';

/// Where a notification takes the member; the screen there loads fresh
/// data. Null when there is nothing to open, as for gym news: the inbox
/// shows it in full.
String? notificationRoute(String type, Map<String, String> data) => switch (topicOf(type)) {
  NotificationTopic.membership => AppRoutes.membership,
  NotificationTopic.payments => switch (data['invoice_id']) {
    final invoiceId? => AppRoutes.invoice(invoiceId),
    null => AppRoutes.payments,
  },
  NotificationTopic.visits => AppRoutes.visits,
  NotificationTopic.announcements || null => null,
};

IconData topicIcon(NotificationTopic? topic) => switch (topic) {
  NotificationTopic.membership => Icons.bolt_rounded,
  NotificationTopic.payments => Icons.receipt_long_rounded,
  NotificationTopic.visits => Icons.qr_code_scanner_rounded,
  NotificationTopic.announcements => Icons.campaign_rounded,
  null => Icons.notifications_rounded,
};
