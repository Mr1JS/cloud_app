/// Simple file/folder manager for Supabase storage
class FileSystemManager {
  final List<Map<String, dynamic>> _allItems; // Change from List<String>
  final Set<String> _expandedFolders;
  final Set<String> _autoExpandedFolders;

  FileSystemManager(
    this._allItems, {
    Set<String>? expandedFolders,
    Set<String>? autoExpandedFolders,
  }) : _expandedFolders = expandedFolders ?? {},
       _autoExpandedFolders = autoExpandedFolders ?? {};

  /// ✅ Expose expanded folders (read-only copy)
  Set<String> get expandedFolders => Set.unmodifiable(_expandedFolders);

  /// ✅ Expose auto-expanded folders (read-only copy)
  Set<String> get autoExpandedFolders => Set.unmodifiable(_autoExpandedFolders);

  /// Get all items as flat list with hierarchy
  List<FileItem> getItems({String? searchQuery}) {
    // Auto-expand folders when searching, collapse auto-expanded when cleared
    if (searchQuery != null && searchQuery.isNotEmpty) {
      _autoExpandedFolders.clear();
      for (final item in _allItems) {
        final path = item['path'];
        if (path.toLowerCase().contains(searchQuery.toLowerCase())) {
          final parts = path.split('/');
          String folderPath = '';
          for (int i = 0; i < parts.length - 1; i++) {
            folderPath = folderPath.isEmpty
                ? parts[i]
                : '$folderPath/${parts[i]}';
            _expandedFolders.add(folderPath);
            _autoExpandedFolders.add(folderPath);
          }
        }
      }
    } else {
      _expandedFolders.removeAll(_autoExpandedFolders);
      _autoExpandedFolders.clear();
    }

    // Build tree structure
    final Map<String, List<FileItem>> childrenMap = {};
    final Set<String> allFolders = {};

    for (final item in _allItems) {
      final path = item['path'];
      final updatedAtStr = item['updatedAt'] as String?;
      DateTime? updatedAt;

      if (updatedAtStr != null) {
        updatedAt = DateTime.tryParse(updatedAtStr);
      }

      // Apply search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final fileName = item['name'] as String;
        if (!fileName.toLowerCase().contains(searchQuery.toLowerCase()) &&
            !path.toLowerCase().contains(searchQuery.toLowerCase())) {
          continue;
        }
      }

      final parts = path.split('/');
      String currentPath = '';

      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];
        final parentPath = currentPath;
        currentPath = currentPath.isEmpty ? part : '$currentPath/$part';

        final isFile = i == parts.length - 1;
        if (!isFile) {
          allFolders.add(currentPath);
        }

        // Use updatedAt only for files, not folders
        final itemUpdatedAt = isFile ? updatedAt : null;

        final fileItem = FileItem(
          name: part,
          isFolder: !isFile,
          fullPath: currentPath,
          depth: i,
          parentPath: parentPath,
          updatedAt: itemUpdatedAt,
        );

        childrenMap.putIfAbsent(parentPath, () => []);

        // Only add if not already exists
        if (!childrenMap[parentPath]!.any((e) => e.fullPath == currentPath)) {
          childrenMap[parentPath]!.add(fileItem);
        }
      }
    }

    // Sort children
    for (final children in childrenMap.values) {
      children.sort((a, b) {
        if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;

        // Sort by updatedAt for files, then by name
        if (!a.isFolder &&
            !b.isFolder &&
            a.updatedAt != null &&
            b.updatedAt != null) {
          return b.updatedAt!.compareTo(a.updatedAt!); // Newest first
        }

        return a.name.compareTo(b.name);
      });
    }

    // Build flat list recursively
    final result = <FileItem>[];

    void addChildren(String parentPath) {
      final children = childrenMap[parentPath] ?? [];
      for (final child in children) {
        result.add(child);
        if (child.isFolder && _expandedFolders.contains(child.fullPath)) {
          addChildren(child.fullPath);
        }
      }
    }

    addChildren('');
    return result;
  }

  /// Toggle folder expansion
  void toggleFolder(String folderPath) {
    if (_expandedFolders.contains(folderPath)) {
      _expandedFolders.remove(folderPath);
    } else {
      _expandedFolders.add(folderPath);
    }
  }

  /// Check if folder is expanded
  bool isExpanded(String folderPath) => _expandedFolders.contains(folderPath);

  /// New
  /// /// 🔎 Returns ALL files across ALL folders (ignores UI state)
  List<FileItem> getAllFilesFlat() {
    final List<FileItem> files = [];

    for (final item in _allItems) {
      final path = item['path'] as String;
      final name = item['name'] as String;
      final updatedAtStr = item['updatedAt'] as String?;

      // skip folders (folders have children but no direct file entry)
      if (!name.contains('.')) continue;

      DateTime? updatedAt;
      if (updatedAtStr != null) {
        updatedAt = DateTime.tryParse(updatedAtStr);
      }

      files.add(
        FileItem(
          name: name,
          isFolder: false,
          fullPath: path,
          depth: path.split('/').length - 1,
          parentPath: path.contains('/')
              ? path.substring(0, path.lastIndexOf('/'))
              : '',
          updatedAt: updatedAt,
        ),
      );
    }

    return files;
  }
}

/// Represents a file or folder
class FileItem {
  final String name;
  final bool isFolder;
  final String fullPath;
  final int depth;
  final String parentPath;
  final DateTime? updatedAt; // Add this

  FileItem({
    required this.name,
    required this.isFolder,
    required this.fullPath,
    required this.depth,
    required this.parentPath,
    this.updatedAt, // Add this
  });
}
