import 'dart:typed_data'; // For Uint8List

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  // Bucket name + init Supabase client
  static const String _bucket = 'userdata';
  final SupabaseClient supabase;
  StorageService(this.supabase);

  // CONTENT TYPE

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

      // Text
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

  // Pcik any image format
  Future<PlatformFile?> pickSingleImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true, // IMPORTANT for web
    );

    return result?.files.firstOrNull;
  }

  // Pick multiple files
  Future<List<PlatformFile>> pickMultipleFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );

    return result?.files ?? [];
  }
  //

  // List all files for a user with timestamps
  Future<List<Map<String, dynamic>>> listAllUserFilePaths({
    required String userId,
    String? subPath,
  }) async {
    final path = subPath == null ? userId : '$userId/$subPath';
    final objects = await supabase.storage.from(_bucket).list(path: path);

    final List<Map<String, dynamic>> results = [];

    for (final obj in objects) {
      if (_isIgnored(obj.name)) continue;

      final isFolder = obj.id == null;
      final fullPath = subPath == null ? obj.name : '$subPath/${obj.name}';

      if (isFolder) {
        results.addAll(
          await listAllUserFilePaths(userId: userId, subPath: fullPath),
        );
      } else {
        results.add({
          'path': fullPath,
          'name': obj.name,
          'updatedAt': obj.updatedAt,
        });
      }
    }

    return results;
  }

  // paths we do not want to show in the UI (Internal stuff)
  bool _isIgnored(String name) {
    return name == '.emptyFolderPlaceholder' ||
        name == 'profile' ||
        name == 'profile_image';
  }

  // Upload profile image
  Future<String?> uploadProfileImage({
    required String userId,
    required String pathSuffix, // --> profile/
  }) async {
    final file = await pickSingleImage();
    if (file?.bytes == null) return null;

    //            USER-ID / profile / profile_image (save here)
    final path = '$userId/$pathSuffix/profile_image';

    await supabase.storage
        .from(_bucket)
        .uploadBinary(
          path,
          file!.bytes!,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentTypeFromFilename(file.name),
          ),
        );

    return getPublicUrl(path);
  }

  // Upload multiple files to a folder
  Future<List<String>> uploadMultipleFiles({
    required String userId,
    required String folder,
  }) async {
    final files = await pickMultipleFiles();
    final urls = <String>[];

    for (final file in files) {
      if (file.bytes == null) continue;

      final path = '$userId/$folder/${file.name}';

      await supabase.storage
          .from(_bucket)
          .uploadBinary(
            path,
            file.bytes!,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentTypeFromFilename(file.name),
            ),
          );

      urls.add(getPublicUrl(path));
    }

    return urls;
  }

  // Download file as bytes
  Future<Uint8List> downloadFile(String path) {
    return supabase.storage.from(_bucket).download(path);
  }

  //
  // URL Helper functions
  String getPublicUrl(String path) {
    final url = supabase.storage.from(_bucket).getPublicUrl(path);

    return Uri.parse(url)
        .replace(
          queryParameters: {
            't': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        )
        .toString();
  }

  // Check if URL exists
  Future<bool> urlExists(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Check if profile image exists
  Future<String?> profileImageUrl(String userId) async {
    final url = getPublicUrl('$userId/profile/profile_image');
    return await urlExists(url) ? url : null;
  }

  //
}
