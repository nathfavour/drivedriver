class ScanStatus {
  final bool isScanning;
  final int filesScanned;
  final int totalFiles;
  final DateTime? lastScan;

  ScanStatus({
    required this.isScanning,
    required this.filesScanned,
    required this.totalFiles,
    this.lastScan,
  });

  factory ScanStatus.fromJson(Map<String, dynamic> json) {
    return ScanStatus(
      isScanning: json['is_scanning'] ?? false,
      filesScanned: json['files_scanned'] ?? 0,
      totalFiles: json['total_files'] ?? 0,
      lastScan:
          json['last_scan'] != null ? DateTime.parse(json['last_scan']) : null,
    );
  }

  double get progress {
    if (totalFiles == 0) return 0.0;
    return filesScanned / totalFiles;
  }
}
