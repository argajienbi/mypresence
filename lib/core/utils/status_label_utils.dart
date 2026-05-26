class StatusLabelUtils {
  const StatusLabelUtils._();

  static String label(String value) {
    final status = value.toLowerCase();
    if (status.contains('approved') || status.contains('success') || status.contains('valid') || status == 'hadir') return 'Disetujui';
    if (status.contains('pending') || status.contains('menunggu')) return 'Menunggu';
    if (status.contains('rejected') || status.contains('ditolak')) return 'Ditolak';
    if (status.contains('late') || status.contains('terlambat') || status.contains('telat')) return 'Terlambat';
    if (status.contains('early') || status.contains('pulang cepat')) return 'Pulang Cepat';
    if (status.contains('on_time') || status.contains('tepat')) return 'Tepat Waktu';
    if (status.contains('outside') || status.contains('out_of_radius') || status.contains('luar_radius')) return 'Luar Radius';
    if (status.isEmpty || status == 'unknown') return 'Belum Diketahui';
    return status.replaceAll('_', ' ').split(' ').map((part) {
      if (part.isEmpty) return part;
      return part[0].toUpperCase() + part.substring(1);
    }).join(' ');
  }
}
