import 'package:cloud_app/Screens/Home/Widgets/file_item.dart';

// Simple file/folder manager for Supabase storage
class FileSystemManager {
  final List<Map<String, dynamic>> _allItems;
  final Set<String> _expandedFolders;
  final Set<String> _autoExpandedFolders;

  FileSystemManager(
    this._allItems, {
    Set<String>? expandedFolders,
    Set<String>? autoExpandedFolders,
  }) : _expandedFolders = expandedFolders ?? {},
       _autoExpandedFolders = autoExpandedFolders ?? {};

  // Expose expanded folders (read-only)
  Set<String> get expandedFolders => Set.unmodifiable(_expandedFolders);

  // Expose auto-expanded folders (read-only)
  Set<String> get autoExpandedFolders => Set.unmodifiable(_autoExpandedFolders);

  // Get all items as flat list with hierarchy
  List<FileItem> getItems({String? searchQuery}) {
    _handleSearchExpansion(searchQuery);

    final childrenMap = _buildFileTree(searchQuery);
    _sortChildren(childrenMap);

    return _buildFlatList(childrenMap);
  }

  // Handle folder expansion/collapse during search
  void _handleSearchExpansion(String? searchQuery) {
    final isSearching = searchQuery != null && searchQuery.isNotEmpty;

    if (isSearching) {
      _autoExpandedFolders.clear();
      _expandMatchingFolders(searchQuery);
    } else {
      _collapseAutoExpandedFolders();
    }
  }

  // Expand folders that contain search matches
  void _expandMatchingFolders(String searchQuery) {
    final lowerQuery = searchQuery.toLowerCase();

    for (final item in _allItems) {
      final path = item['path'] as String;

      if (path.toLowerCase().contains(lowerQuery)) {
        _expandParentFolders(path);
      }
    }
  }

  // Expand all parent folders of a given path
  void _expandParentFolders(String path) {
    final parts = path.split('/');
    String folderPath = '';

    for (int i = 0; i < parts.length - 1; i++) {
      folderPath = folderPath.isEmpty ? parts[i] : '$folderPath/${parts[i]}';
      _expandedFolders.add(folderPath);
      _autoExpandedFolders.add(folderPath);
    }
  }

  // Collapse folders that were auto-expanded during search
  void _collapseAutoExpandedFolders() {
    _expandedFolders.removeAll(_autoExpandedFolders);
    _autoExpandedFolders.clear();
  }

  // Build tree structure from flat file list
  Map<String, List<FileItem>> _buildFileTree(String? searchQuery) {
    final childrenMap = <String, List<FileItem>>{};

    for (final item in _allItems) {
      if (!_shouldIncludeItem(item, searchQuery)) continue;

      _addItemToTree(item, childrenMap);
    }

    return childrenMap;
  }

  // Check if item should be included based on search query
  bool _shouldIncludeItem(Map<String, dynamic> item, String? searchQuery) {
    if (searchQuery == null || searchQuery.isEmpty) return true;

    final lowerQuery = searchQuery.toLowerCase();
    final fileName = item['name'] as String;
    final path = item['path'] as String;

    return fileName.toLowerCase().contains(lowerQuery) ||
        path.toLowerCase().contains(lowerQuery);
  }

  // Add item and all parent folders to tree
  void _addItemToTree(
    Map<String, dynamic> item,
    Map<String, List<FileItem>> childrenMap,
  ) {
    final path = item['path'] as String;
    final updatedAt = _parseDateTime(item['updatedAt']);
    final parts = path.split('/');

    String currentPath = '';

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      final parentPath = currentPath;
      currentPath = currentPath.isEmpty ? part : '$currentPath/$part';

      final isFile = i == parts.length - 1;
      final fileItem = FileItem(
        name: part,
        isFolder: !isFile,
        fullPath: currentPath,
        depth: i,
        parentPath: parentPath,
        updatedAt: isFile ? updatedAt : null, // Only files have dates
      );

      _addToChildrenMap(childrenMap, parentPath, fileItem, currentPath);
    }
  }

  // Parse DateTime from string
  DateTime? _parseDateTime(dynamic dateStr) {
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr as String);
  }

  // Add file item to children map (avoiding duplicates)
  void _addToChildrenMap(
    Map<String, List<FileItem>> childrenMap,
    String parentPath,
    FileItem fileItem,
    String currentPath,
  ) {
    childrenMap.putIfAbsent(parentPath, () => []);

    final exists = childrenMap[parentPath]!.any(
      (e) => e.fullPath == currentPath,
    );
    if (!exists) {
      childrenMap[parentPath]!.add(fileItem);
    }
  }

  // Sort children: folders first, then by date/name
  void _sortChildren(Map<String, List<FileItem>> childrenMap) {
    for (final children in childrenMap.values) {
      children.sort(_compareFileItems);
    }
  }

  // Compare two file items for sorting
  int _compareFileItems(FileItem a, FileItem b) {
    // Folders always come first
    if (a.isFolder != b.isFolder) {
      return a.isFolder ? -1 : 1;
    }

    // Sort files by date (newest first)
    if (!a.isFolder &&
        !b.isFolder &&
        a.updatedAt != null &&
        b.updatedAt != null) {
      return b.updatedAt!.compareTo(a.updatedAt!);
    }

    // Sort by name
    return a.name.compareTo(b.name);
  }

  // Build flat list from tree structure
  List<FileItem> _buildFlatList(Map<String, List<FileItem>> childrenMap) {
    final result = <FileItem>[];

    void addChildren(String parentPath) {
      final children = childrenMap[parentPath] ?? [];

      for (final child in children) {
        result.add(child);

        if (child.isFolder && isExpanded(child.fullPath)) {
          addChildren(child.fullPath);
        }
      }
    }

    addChildren('');
    return result;
  }

  // Toggle folder expansion
  void toggleFolder(String folderPath) {
    if (_expandedFolders.contains(folderPath)) {
      _expandedFolders.remove(folderPath);
    } else {
      _expandedFolders.add(folderPath);
    }
  }

  // Check if folder is expanded
  bool isExpanded(String folderPath) => _expandedFolders.contains(folderPath);

  // Returns ALL files across ALL folders (ignores UI state)
  List<FileItem> getAllFilesFlat() {
    return _allItems
        .where(_isFile)
        .map(_createFileItem)
        .cast<FileItem>()
        .toList();
  }

  // Check if item is a file (not a folder)
  bool _isFile(Map<String, dynamic> item) {
    final name = item['name'] as String;
    return name.contains('.');
  }

  // Create a FileItem from a file map
  FileItem _createFileItem(Map<String, dynamic> item) {
    final path = item['path'] as String;
    final name = item['name'] as String;
    final updatedAt = _parseDateTime(item['updatedAt']);

    return FileItem(
      name: name,
      isFolder: false,
      fullPath: path,
      depth: path.split('/').length - 1,
      parentPath: path.contains('/')
          ? path.substring(0, path.lastIndexOf('/'))
          : '',
      updatedAt: updatedAt,
    );
  }
}
