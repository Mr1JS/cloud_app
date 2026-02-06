import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class SimplePreviewDialog extends StatelessWidget {
  final String fileName;
  final String filePath;
  final String userId;

  const SimplePreviewDialog({
    super.key,
    required this.fileName,
    required this.filePath,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final fullPath = '$userId/$filePath';
    final extension = fileName.split('.').last.toLowerCase();

    return AlertDialog(
      title: Row(
        children: [
          Icon(_getIcon(extension)),
          SizedBox(width: 10),
          Expanded(child: Text(fileName)),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 500,
        child: _buildContent(fullPath, extension),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }

  Widget _buildContent(String path, String extension) {
    // Image preview
    if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
      return Image.network(
        Supabase.instance.client.storage.from('userdata').getPublicUrl(path),
        fit: BoxFit.contain,
      );
    }

    // Text preview
    if ([
      'txt',
      'dart',
      'js',
      'json',
      'html',
      'css',
      'md',
      'c',
      'cpp',
      'java',
      'py',
      'sh',
      'ts',
    ].contains(extension)) {
      return FutureBuilder<String>(
        future: _loadTextFile(path),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text('Error loading'));
          return Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: SelectableText(
                snapshot.data ?? 'Empty file',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
          );
        },
      );
    }

    // PDF preview - Using signed URL
    if (extension == 'pdf') {
      return FutureBuilder(
        future: _GetPDFUrl(path),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading'));
          }

          return SfPdfViewer.network(snapshot.data!, enableTextSelection: true);
        },
      );
    }

    // Default view for other files
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.insert_drive_file, size: 64, color: Colors.blue),
        SizedBox(height: 20),
        Text('Preview not available'),
        SizedBox(height: 10),
        Text('.$extension file'),
      ],
    );
  }

  Future<String> _loadTextFile(String path) async {
    try {
      final response = await Supabase.instance.client.storage
          .from('userdata')
          .download(path);
      return String.fromCharCodes(response);
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> _GetPDFUrl(String path) async {
    final response = Supabase.instance.client.storage
        .from('userdata')
        .getPublicUrl(path);

    return response;
  }

  IconData _getIcon(String extension) {
    if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) return Icons.image;
    if (['txt', 'dart', 'js', 'json'].contains(extension)) {
      return Icons.text_snippet;
    }
    if (['pdf'].contains(extension)) return Icons.picture_as_pdf;
    return Icons.insert_drive_file;
  }
}
