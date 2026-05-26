class FirestorePaths {
  const FirestorePaths._();

  static String company(String companyId) => 'companies/$companyId';

  static String announcements(String companyId) =>
      'companies/$companyId/announcements';

  static String announcement(String companyId, String announcementId) =>
      'companies/$companyId/announcements/$announcementId';

  static String notificationInbox(String companyId, String uid) =>
      'companies/$companyId/users/$uid/notification_inbox';

  static String notificationItem(
    String companyId,
    String uid,
    String notificationId,
  ) =>
      'companies/$companyId/users/$uid/notification_inbox/$notificationId';

  static String fcmTokens(String companyId, String uid) =>
      'companies/$companyId/users/$uid/fcm_tokens';

  static String fcmToken(String companyId, String uid, String tokenId) =>
      'companies/$companyId/users/$uid/fcm_tokens/$tokenId';

  static String notificationSettings(String companyId) =>
      'companies/$companyId/notification_settings/main';
}
