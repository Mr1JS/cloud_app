import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static const String _bucket = 'userdata';

  final SupabaseClient supabase;

  StorageService(this.supabase);

  /// ─────────────────────────────────────────────────────────────
  /// CONTENT TYPE HELPERS
  /// ─────────────────────────────────────────────────────────────
  String contentTypeFromFilename(String filename) {
    final ext = filename.split('.').last.toLowerCase();

    switch (ext) {
      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'svg':
        return 'image/svg+xml';

      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';

      // Text / Code
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';

      // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';

      // Video
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';

      default:
        return 'application/octet-stream';
    }
  }

  // ─────────────────────────────────────────────────────────────
  // IMAGE PICKER (avatars, profile pictures)
  // ─────────────────────────────────────────────────────────────

  Future<PlatformFile?> pickSingleImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true, // IMPORTANT for web
    );

    if (result == null || result.files.isEmpty) return null;
    return result.files.first;
  }

  // ─────────────────────────────────────────────────────────────
  // MULTI FILE PICKER (FAB uploads)
  // ─────────────────────────────────────────────────────────────

  Future<List<PlatformFile>> pickMultipleFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );

    if (result == null) return [];
    return result.files;
  }

  /// ─────────────────────────────────────────────────────────────
  // LIST ALL USER FILE PATHS
  // ─────────────────────────────────────────────────────────────
  /// ─────────────────────────────────────────────────────────────
  // LIST ALL USER FILE PATHS WITH TIMESTAMPS
  // ─────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> listAllUserFilePaths({
    required String userId,
    String? subPath,
  }) async {
    final path = subPath == null ? userId : '$userId/$subPath';
    final objects = await supabase.storage.from('userdata').list(path: path);

    List<Map<String, dynamic>> allItems = [];

    for (final obj in objects) {
      if (obj.name == ".emptyFolderPlaceholder" ||
          obj.name == "profile" ||
          obj.name == "profile_image") {
        continue;
      }

      final isFolder = obj.id == null;
      final fullPath = subPath == null ? obj.name : '$subPath/${obj.name}';

      if (isFolder) {
        // Recursion into folder
        final subFiles = await listAllUserFilePaths(
          userId: userId,
          subPath: fullPath,
        );
        allItems.addAll(subFiles);
      } else {
        // Add file with metadata
        print("The File $fullPath and date ${obj.updatedAt}");
        allItems.add({
          'path': fullPath,
          'updatedAt': obj.updatedAt,
          'name': obj.name,
        });
      }
    }

    return allItems;
  }

  // ─────────────────────────────────────────────────────────────
  // UPLOAD IMAGE (profile, avatar)
  // ─────────────────────────────────────────────────────────────

  Future<String?> uploadProfileImage({
    required String userId,
    required String pathSuffix, // e.g. profile, logo
  }) async {
    final file = await pickSingleImage();
    if (file == null) return null;

    final Uint8List bytes = file.bytes!;
    final String mimeType = contentTypeFromFilename(file.name);
    final String path = "$userId/$pathSuffix/profile_image";

    await supabase.storage
        .from(_bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: mimeType),
        );

    return getPublicUrlRaw(path);
  }

  // ─────────────────────────────────────────────────────────────
  // UPLOAD MULTIPLE FILES (FAB)
  // ─────────────────────────────────────────────────────────────

  Future<List<String>> uploadMultipleFiles({
    required String userId,
    required String folder, // e.g. "uploads"
  }) async {
    final files = await pickMultipleFiles();
    if (files.isEmpty) return [];

    List<String> uploadedUrls = [];

    for (final file in files) {
      if (file.bytes == null) continue;

      final String mimeType = contentTypeFromFilename(file.name);
      final path = "$userId/$folder/${file.name}";

      await supabase.storage
          .from(_bucket)
          .uploadBinary(
            path,
            file.bytes!,
            fileOptions: FileOptions(upsert: true, contentType: mimeType),
          );

      uploadedUrls.add(getPublicUrlRaw(path));
    }

    return uploadedUrls;
  }

  Future<Uint8List> downloadFile(String fullpath) {
    return supabase.storage.from(_bucket).download(fullpath);
  }

  // ─────────────────────────────────────────────────────────────
  // URL HELPERS
  // ─────────────────────────────────────────────────────────────

  String getPublicUrlRaw(String fullPath) {
    final url = supabase.storage.from(_bucket).getPublicUrl(fullPath);

    return Uri.parse(url)
        .replace(
          queryParameters: {
            't': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        )
        .toString();
  }

  Future<bool?> urlExists(String url) async {
    try {
      final response = await http.head(Uri.parse(url));

      if (response.statusCode == 200) {
        return true;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> profileImageUrl(String userId) async {
    final url = getPublicUrlRaw('$userId/profile/profile_image');

    final exists = await urlExists(url);
    if (exists == true) {
      return url;
    }

    return null;
  }
}
