import 'package:cloud_app/HomePage/components/fileSystem.dart';
import 'package:cloud_app/HomePage/components/profileDialog.dart';
import 'package:cloud_app/HomePage/components/simplePreviewDialog.dart';
import 'package:cloud_app/HomePage/storageService.dart';
import 'package:cloud_app/LoginSignupPage/LoginSignupCom/LoginPage.dart';
import 'package:cloud_app/auth_service.dart';
import 'package:download/download.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:primer_progress_bar/primer_progress_bar.dart';
import 'package:share_plus/share_plus.dart';

class HomeController extends GetxController {
  final AuthService _auth = AuthService();
  late final StorageService _storage;

  final Rx<FileSystemManager?> _fileSystem = Rx<FileSystemManager?>(null);
  final RxString imageUrl = RxString('');
  final RxString username = RxString('');
  final RxMap<String, bool> _expandedFolders = <String, bool>{}.obs;

  StorageService get storage => _storage;
  AuthService get auth => _auth;
  FileSystemManager? get fileSystem => _fileSystem.value;
  String? get currentImageUrl => imageUrl.value;
  String? get currentUsername => username.value;

  @override
  void onInit() {
    super.onInit();
    _storage = StorageService(_auth.supabase);
    _loadUserData();
    loadFiles();
  }

  Future<void> _loadUserData() async {
    final userId = _auth.getCurrentUser()?.id;
    final email = _auth.getUserEmail();

    if (userId != null) {
      final url = await _storage.profileImageUrl(userId);
      imageUrl.value = url ?? '';
      username.value = (email ?? '').split('@').first;
    }
  }

  Future<void> loadFiles() async {
    final userId = _auth.getCurrentUser()?.id;
    if (userId == null) return;

    try {
      final allItems = await _storage.listAllUserFilePaths(userId: userId);
      _fileSystem.value = FileSystemManager(allItems);
    } catch (e) {
      debugPrint('Error loading files: $e');
    }
  }

  void refreshFiles() => loadFiles();

  void showProfileDialog() {
    String? dialogImageUrl = imageUrl.value;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return ProfileDialog(
            username: username.value,
            email: _auth.getUserEmail() ?? '',
            imageUrl: dialogImageUrl,
            onEditImage: () async {
              final userId = _auth.getCurrentUser()!.id;
              final url = await _storage.uploadProfileImage(
                userId: userId,
                pathSuffix: 'profile',
              );

              if (url != null) {
                setDialogState(() => dialogImageUrl = url);
                imageUrl.value = url;
              }
            },
          );
        },
      ),
    );
  }

  void signOut() async {
    await _auth.signOut();
    Get.offAll(() => LogInPage());
    Get.deleteAll(force: true);
  }

  // NEW: Date formatting utility function
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

  // NEW: Delete item function
  Future<void> deleteItem(FileItem item) async {
    try {
      final userId = _auth.getCurrentUser()!.id;
      final storageClient = _storage.supabase.storage.from('userdata');
      final fullPath = '$userId/${item.fullPath}';

      if (item.isFolder) {
        await _deleteFolderRecursively(storageClient, fullPath);
      } else {
        await storageClient.remove([fullPath]);
      }

      refreshFiles();

      Get.showSnackbar(
        GetSnackBar(
          message: 'Deleted ${item.name}',
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Delete error: $e');
      Get.showSnackbar(
        GetSnackBar(
          message: 'Failed to delete',
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Recursively deletes all files in a folder
  Future<void> _deleteFolderRecursively(
    dynamic storageClient,
    String path,
  ) async {
    final items = await storageClient.list(path: path);

    for (var item in items) {
      final itemPath = '$path/${item.name}';

      if (item.id == null) {
        // It's a folder - recurse
        await _deleteFolderRecursively(storageClient, itemPath);
      } else {
        // It's a file - delete it
        await storageClient.remove([itemPath]);
      }
    }
  }

  // NEW: Confirm delete dialog
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

  // NEW: Show preview dialog
  void showPreview(FileItem item) {
    final userId = _auth.getCurrentUser()!.id;

    Get.dialog(
      SimplePreviewDialog(
        fileName: item.name,
        filePath: item.fullPath,
        userId: userId,
      ),
    );
  }

  // NEW: Toggle folder expansion state
  void toggleFolder(String path) {
    if (_fileSystem.value != null) {
      _fileSystem.value!.toggleFolder(path);
      // Update reactive state
      _expandedFolders[path] = !(_expandedFolders[path] ?? false);
      // Trigger update for fileSystem
      _fileSystem.refresh();
    }
  }

  // NEW: Check if folder is expanded
  bool isFolderExpanded(String path) {
    return _fileSystem.value?.isExpanded(path) ?? false;
  }

  // NEW: Get file items with search query
  List<FileItem> getFileItems({String searchQuery = ''}) {
    return _fileSystem.value?.getItems(searchQuery: searchQuery) ?? [];
  }

  // NEW: Share Public Url
  Future<void> shareLink(String path) async {
    final userId = _auth.getCurrentUser()?.id;
    String fullPath = "$userId/$path";

    String shareLink = storage.getPublicUrlRaw(fullPath);

    await SharePlus.instance.share(ShareParams(text: shareLink));
  }

  // NEW : Download file
  Future<void> downloadFile(String path, String filename) async {
    print("the path is $path, and the name : $filename");
    final userId = _auth.getCurrentUser()?.id;
    String fullPath = "$userId/$path";

    final url = _storage.downloadFile(fullPath);

    await downloadData(await url, filename);
  }

  // NEW : Recent uploads
  List<FileItem> getRecentUploads({int limit = 5}) {
    final fs = _fileSystem.value;
    if (fs == null) return [];

    final files = fs.getAllFilesFlat()..removeWhere((f) => f.updatedAt == null);

    files.sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));

    return files.take(limit).toList();
  }

  // NEW : Storage Overview
  Map<String, int> getStorageOverview() {
    final fs = _fileSystem.value;
    if (fs == null) return {};

    final files = fs.getAllFilesFlat();

    int images = 0;
    int documents = 0;
    int videos = 0;
    int other = 0;

    for (final file in files) {
      final ext = file.name.toLowerCase().split('.').last;

      if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
        images++;
      } else if (['pdf', 'doc', 'docx', 'txt'].contains(ext)) {
        documents++;
      } else if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) {
        videos++;
      } else {
        other++;
      }
    }

    return {
      'images': images,
      'documents': documents,
      'videos': videos,
      'other': other,
    };
  }

  // NEW : Storage overview
  List<Segment> buildStorageSegments() {
    final data = getStorageOverview();
    final totalFiles = data.values.fold<int>(0, (a, b) => a + b);
    if (totalFiles == 0) return [];

    int images = ((data['images']! / totalFiles) * 100).round();
    int docs = ((data['documents']! / totalFiles) * 100).round();
    int videos = ((data['videos']! / totalFiles) * 100).round();

    int used = images + docs + videos;
    int other = 100 - used; // force total to 100

    return [
      Segment(
        color: Colors.red,
        value: images,
        label: const Text('Images'),
        valueLabel: Text('$images%'),
      ),
      Segment(
        color: Colors.blue,
        value: docs,
        label: const Text('Docs'),
        valueLabel: Text('$docs%'),
      ),
      Segment(
        color: Colors.green,
        value: videos,
        label: const Text('Videos'),
        valueLabel: Text('$videos%'),
      ),
      Segment(
        color: Colors.grey,
        value: other,
        label: const Text('Other'),
        valueLabel: Text('$other%'),
      ),
    ];
  }
}
