enum RequestStatusKind {
  leave,
  qrTarget,
  qrHelper,
  correction,
}

class RequestStatusItem {
  final String id;
  final RequestStatusKind kind;
  final String kindLabel;
  final String typeKey;
  final String contextLabel;
  final String status;
  final String rawStatus;
  final int createdAtMillis;
  final String createdAtLabel;
  final int processedAtMillis;
  final String processedAtLabel;
  final String targetDateLabel;
  final String note;
  final String adminNote;
  final String evidenceLabel;
  final String evidenceUrl;
  final String evidencePath;
  final String targetUid;
  final String targetName;
  final String helperUid;
  final String helperName;
  final String actionType;
  final Map<String, dynamic> raw;

  const RequestStatusItem({
    required this.id,
    required this.kind,
    required this.kindLabel,
    required this.typeKey,
    required this.contextLabel,
    required this.status,
    required this.rawStatus,
    required this.createdAtMillis,
    required this.createdAtLabel,
    required this.processedAtMillis,
    required this.processedAtLabel,
    required this.targetDateLabel,
    required this.note,
    required this.adminNote,
    required this.evidenceLabel,
    required this.evidenceUrl,
    required this.evidencePath,
    required this.targetUid,
    required this.targetName,
    required this.helperUid,
    required this.helperName,
    required this.actionType,
    required this.raw,
  });

  bool get hasNote => note.trim().isNotEmpty;
  bool get hasAdminNote => adminNote.trim().isNotEmpty;
  bool get hasEvidence =>
      evidenceUrl.trim().isNotEmpty || evidencePath.trim().isNotEmpty;
  bool get hasProcessedAt => processedAtMillis > 0;
  bool get isQr =>
      kind == RequestStatusKind.qrTarget || kind == RequestStatusKind.qrHelper;
  bool get isLeave => kind == RequestStatusKind.leave;
  bool get isCorrection => kind == RequestStatusKind.correction;

  String get statusLabel {
    switch (status) {
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Pending';
    }
  }

  static String normalizeStatus(String rawStatus) {
    final value = rawStatus.trim().toLowerCase();
    switch (value) {
      case 'pending':
      case 'pending_admin':
      case 'processing':
      case 'menunggu':
      case 'waiting':
      case 'in_review':
        return 'pending';
      case 'approved':
      case 'validated':
      case 'disetujui':
      case 'done':
        return 'approved';
      case 'rejected':
      case 'ditolak':
      case 'declined':
      case 'cancelled':
        return 'rejected';
      default:
        return value.isEmpty ? 'pending' : value;
    }
  }

  static bool isPendingStatus(String rawStatus) =>
      normalizeStatus(rawStatus) == 'pending';

  static bool isApprovedStatus(String rawStatus) =>
      normalizeStatus(rawStatus) == 'approved';

  static bool isRejectedStatus(String rawStatus) =>
      normalizeStatus(rawStatus) == 'rejected';
}
