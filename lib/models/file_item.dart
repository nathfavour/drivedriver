enum FileType { file, directory }

class FileItem {
  final String name;
  final String path;
  final FileType type;
  final int size;
  final DateTime modified;
  final Map<String, dynamic>? metadata;

  FileItem({
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    required this.modified,
    this.metadata,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      type: json['is_dir'] == true ? FileType.directory : FileType.file,
      size: json['size'] ?? 0,
      modified: json['modified'] != null
          ? DateTime.parse(json['modified'])
          : DateTime.now(),
      metadata: json['metadata'],
    );
  }

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(2)} KB';
    if (size < 1024 * 1024 * 1024)
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
