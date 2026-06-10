import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../services/storage_service.dart';

class AttachmentPreviewTile extends StatelessWidget {
  final String photoUrl;
  final String photoPath;
  final String buttonLabel;
  final String previewTitle;
  final String emptyLabel;

  static final StorageService _storage = StorageService();

  const AttachmentPreviewTile({
    super.key,
    required this.photoUrl,
    required this.photoPath,
    this.buttonLabel = 'Lihat Foto',
    this.previewTitle = 'Preview',
    this.emptyLabel = 'Foto/lampiran belum bisa dimuat.',
  });

  bool get _hasSource =>
      photoUrl.trim().isNotEmpty || photoPath.trim().isNotEmpty;

  Future<String> _resolveUrl() async {
    final url = photoUrl.trim();
    if (url.isNotEmpty) return url;
    return _storage.downloadUrl(photoPath.trim());
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasSource) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Text(
          emptyLabel,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return FutureBuilder<String>(
      future: _resolveUrl(),
      builder: (context, snapshot) {
        final resolvedUrl = snapshot.data ?? '';
        if (resolvedUrl.isNotEmpty) {
          return InkWell(
            onTap: () => showAttachmentPreviewSheet(
              context: context,
              photoUrl: resolvedUrl,
              title: previewTitle,
              emptyLabel: emptyLabel,
            ),
            borderRadius: BorderRadius.circular(18),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(
                  resolvedUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppColors.bg,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(
                          color: AppColors.primary),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.bg,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_outlined,
                        color: AppColors.muted, size: 36),
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => showAttachmentPreviewSheet(
              context: context,
              photoUrl: photoUrl,
              photoPath: photoPath,
              title: previewTitle,
              emptyLabel: emptyLabel,
            ),
            icon: const Icon(Icons.open_in_full_rounded),
            label: Text(buttonLabel),
          ),
        );
      },
    );
  }
}

Future<void> showAttachmentPreviewSheet({
  required BuildContext context,
  String title = 'Preview',
  String photoUrl = '',
  String photoPath = '',
  String emptyLabel = 'Foto/lampiran belum bisa dimuat.',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AttachmentPreviewSheet(
      title: title,
      photoUrl: photoUrl,
      photoPath: photoPath,
      emptyLabel: emptyLabel,
    ),
  );
}

class _AttachmentPreviewSheet extends StatelessWidget {
  final String title;
  final String photoUrl;
  final String photoPath;
  final String emptyLabel;

  static final StorageService _storage = StorageService();

  const _AttachmentPreviewSheet({
    required this.title,
    required this.photoUrl,
    required this.photoPath,
    required this.emptyLabel,
  });

  Future<String> _resolveUrl() async {
    final url = photoUrl.trim();
    if (url.isNotEmpty) return url;
    return _storage.downloadUrl(photoPath.trim());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: .92,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: FutureBuilder<String>(
                    future: _resolveUrl(),
                    builder: (context, snapshot) {
                      final resolvedUrl = snapshot.data ?? '';
                      if (resolvedUrl.isNotEmpty) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            color: AppColors.bg,
                            child: InteractiveViewer(
                              minScale: .8,
                              maxScale: 4,
                              child: SizedBox.expand(
                                child: Image.network(
                                  resolvedUrl,
                                  fit: BoxFit.contain,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                          color: AppColors.primary),
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      emptyLabel,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        );
                      }

                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            emptyLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
