class DriveItem {
  final String mountPoint;
  final String fsType;
  final int totalSpace;
  final int availableSpace;
  final int usedSpace;
  final bool isRemovable;

  DriveItem({
    required this.mountPoint,
    required this.fsType,
    required this.totalSpace,
    required this.availableSpace,
    required this.usedSpace,
    required this.isRemovable,
  });

  factory DriveItem.fromJson(Map<String, dynamic> json) {
    return DriveItem(
      mountPoint: json['mount_point'] ?? '',
      fsType: json['fs_type'] ?? 'unknown',
      totalSpace: json['total_space'] ?? 0,
      availableSpace: json['available_space'] ?? 0,
      usedSpace: json['used_space'] ?? 0,
      isRemovable: json['is_removable'] ?? false,
    );
  }

  String get totalSpaceFormatted => _formatBytes(totalSpace);
  String get availableSpaceFormatted => _formatBytes(availableSpace);
  String get usedSpaceFormatted => _formatBytes(usedSpace);

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
