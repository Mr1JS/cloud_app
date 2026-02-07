import 'package:cloud_app/Screens/Home/Widgets/file_item.dart';
import 'package:cloud_app/Screens/Home/Widgets/file_system_manager.dart';
import 'package:cloud_app/Screens/Home/Widgets/profile_dialog.dart';
import 'package:cloud_app/Screens/Home/Widgets/preview_dialog.dart';
import 'package:cloud_app/Services/storage_service.dart';
import 'package:cloud_app/Screens/Auth/login_page.dart';
import 'package:cloud_app/Services/auth_service.dart';
import 'package:download/download.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:primer_progress_bar/primer_progress_bar.dart';
import 'package:share_plus/share_plus.dart';

class HomeController extends GetxController {
  final AuthService _auth = AuthService();
  late final StorageService _storage;

  final Rx<FileSystemManager?> _fileSystem = Rx<FileSystemManager?>(null);
  final RxString _imageUrl = RxString('');
  final RxString _username = RxString('');
  final RxMap<String, bool> _expandedFolders = <String, bool>{}.obs;

  // Getters for UI access
  StorageService get storage => _storage;
  AuthService get auth => _auth;
  FileSystemManager? get fileSystem => _fileSystem.value;
  String? get currentImageUrl => _imageUrl.value;
  String? get currentUsername => _username.value;

  @override
  void onInit() {
    super.onInit();
    _storage = StorageService(_auth.supabaseClient);
    _loadUserData();
    loadFiles();
  }

  // USER DATA

  Future<void> _loadUserData() async {
    final userId = _auth.currentUser?.id;
    final email = _auth.userEmail;

    if (userId != null) {
      final url = await _storage.profileImageUrl(userId);
      _imageUrl.value = url ?? '';
      _username.value = (email ?? '').split('@').first;
    }
  }

  // FILE MANAGEMENT

  Future<void> loadFiles() async {
    final userId = _auth.currentUser?.id;
    if (userId == null) return;

    try {
      final allItems = await _storage.listAllUserFilePaths(userId: userId);
      _fileSystem.value = FileSystemManager(allItems);
    } catch (e) {
      debugPrint('Error loading files: $e');
    }
  }

  // Call this after any file operation to refresh the UI
  void refreshFiles() => loadFiles();

  // Get file items for UI display
  List<FileItem> getFileItems({String searchQuery = ''}) {
    return _fileSystem.value?.getItems(searchQuery: searchQuery) ?? [];
  }

  // FOLDER EXPANSION

  void toggleFolder(String path) {
    final fs = _fileSystem.value;
    if (fs == null) return;

    fs.toggleFolder(path);
    _expandedFolders[path] = !(_expandedFolders[path] ?? false);
    _fileSystem.refresh();
  }

  // Check if a folder is expanded
  bool isFolderExpanded(String path) {
    return _fileSystem.value?.isExpanded(path) ?? false;
  }

  // DIALOGS
  // for profile editing
  void showProfileDialog() {
    String? dialogImageUrl = _imageUrl.value;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return ProfileDialog(
            username: _username.value,
            email: _auth.userEmail ?? '',
            imageUrl: dialogImageUrl,
            onEditImage: () async {
              final userId = _auth.currentUser?.id;
              if (userId == null) return;

              final url = await _storage.uploadProfileImage(
                userId: userId,
                pathSuffix: 'profile',
              );

              if (url != null) {
                setDialogState(() => dialogImageUrl = url);
                _imageUrl.value = url;
              }
            },
          );
        },
      ),
    );
  }

  // show file content
  void showPreview(FileItem item) {
    final userId = _auth.currentUser?.id;
    if (userId == null) return;

    Get.dialog(
      SimplePreviewDialog(
        fileName: item.name,
        filePath: item.fullPath,
        userId: userId,
      ),
    );
  }

  // show delete confirmation
  void confirmDelete(FileItem item) {
    Get.dialog(
      AlertDialog(
        title: Text('Delete ${item.isFolder ? 'Folder' : 'File'}?'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              deleteItem(item);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // FILE OPERATIONS
  // Delete file
  Future<void> deleteItem(FileItem item) async {
    try {
      final userId = _auth.currentUser?.id;
      if (userId == null) return;

      final storageClient = _storage.supabase.storage.from('userdata');
      final fullPath = '$userId/${item.fullPath}';

      if (item.isFolder) {
        await _deleteFolderRecursively(storageClient, fullPath);
      } else {
        await storageClient.remove([fullPath]);
      }

      refreshFiles();
      _showSuccessSnackbar('Deleted ${item.name}');
    } catch (e) {
      debugPrint('Delete error: $e');
      _showErrorSnackbar('Failed to delete');
    }
  }

  // delete folder recursively
  Future<void> _deleteFolderRecursively(
    dynamic storageClient,
    String path,
  ) async {
    final items = await storageClient.list(path: path);

    for (var item in items) {
      final itemPath = '$path/${item.name}';

      if (item.id == null) {
        await _deleteFolderRecursively(storageClient, itemPath);
      } else {
        await storageClient.remove([itemPath]);
      }
    }
  }

  // Share file link
  Future<void> shareLink(String path) async {
    final userId = _auth.currentUser?.id;
    if (userId == null) return;

    final fullPath = "$userId/$path";
    final shareLink = _storage.getPublicUrl(fullPath);

    await SharePlus.instance.share(ShareParams(text: shareLink));
  }

  // download file locally
  Future<void> downloadFile(String path, String filename) async {
    debugPrint('Downloading: $path as $filename');
    final userId = _auth.currentUser?.id;
    if (userId == null) return;

    final fullPath = "$userId/$path";
    final fileData = await _storage.downloadFile(fullPath);

    await downloadData(fileData, filename);
  }

  // UTILITIES

  // date formatter
  String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Sign out
  void signOut() async {
    await _auth.signOut();
    Get.offAll(() => LogInPage());
    Get.deleteAll(force: true);
  }

  // Display Success !
  void _showSuccessSnackbar(String message) {
    Get.showSnackbar(
      GetSnackBar(message: message, duration: const Duration(seconds: 2)),
    );
  }

  // Display Error !
  void _showErrorSnackbar(String message) {
    Get.showSnackbar(
      GetSnackBar(
        message: message,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ANALYTICS & STORAGE OVERVIEW
  // Get recent uploads sorted by date
  List<FileItem> getRecentUploads({int limit = 5}) {
    final fs = _fileSystem.value;
    if (fs == null) return [];

    final files = fs.getAllFilesFlat()
      ..removeWhere((f) => f.updatedAt == null)
      ..sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));

    return files.take(limit).toList();
  }

  // collect storage usage overview by file type
  Map<String, int> getStorageOverview() {
    final fs = _fileSystem.value;
    if (fs == null) return {};

    final files = fs.getAllFilesFlat();
    final result = {'images': 0, 'documents': 0, 'videos': 0, 'other': 0};

    for (final file in files) {
      if (file.isImageFile()) {
        result['images'] = result['images']! + 1;
      } else if (file.isDocumentFile()) {
        result['documents'] = result['documents']! + 1;
      } else if (file.isVideoFile()) {
        result['videos'] = result['videos']! + 1;
      } else {
        result['other'] = result['other']! + 1;
      }
    }

    return result;
  }

  // build storage overview bar
  List<Segment> buildStorageSegments() {
    final data = getStorageOverview();
    final total = data.values.fold<int>(0, (a, b) => a + b);

    if (total == 0) return [];

    return [
      _buildSegment('images', data, total, Colors.red, 'Images'),
      _buildSegment('documents', data, total, Colors.blue, 'Docs'),
      _buildSegment('videos', data, total, Colors.green, 'Videos'),
      _buildSegment('other', data, total, Colors.grey, 'Other'),
    ];
  }

  Segment _buildSegment(
    String key,
    Map<String, int> data,
    int total,
    Color color,
    String label,
  ) {
    final value = ((data[key]! / total) * 100).round();
    return Segment(color: color, value: value, label: Text(label));
  }
}
