/// Represents a file or folder
class FileItem {
  final String name;
  final bool isFolder;
  final String fullPath;
  final int depth;
  final String parentPath;
  final DateTime? updatedAt;

  const FileItem({
    required this.name,
    required this.isFolder,
    required this.fullPath,
    required this.depth,
    required this.parentPath,
    this.updatedAt,
  });

  /// Get file extension
  String get extension => name.split('.').last.toLowerCase();

  /// Check if this is a specific file type
  bool isImageFile() {
    const imageExts = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return imageExts.contains(extension);
  }

  bool isDocumentFile() {
    const docExts = ['pdf', 'doc', 'docx', 'txt'];
    return docExts.contains(extension);
  }

  bool isVideoFile() {
    const videoExts = ['mp4', 'mov', 'avi', 'mkv'];
    return videoExts.contains(extension);
  }

  bool isAudioFile() {
    const audioExts = ['mp3', 'wav', 'aac', 'ogg'];
    return audioExts.contains(extension);
  }

  bool isArchiveFile() {
    const archiveExts = ['zip', 'rar', '7z'];
    return archiveExts.contains(extension);
  }

  @override
  String toString() =>
      'FileItem(name: $name, isFolder: $isFolder, path: $fullPath)';
}
