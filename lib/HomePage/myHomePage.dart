import 'package:cloud_app/HomePage/components/mobileWidgetBody.dart';
import 'package:cloud_app/HomePage/components/webWidgbetBody.dart';
import 'package:cloud_app/HomePage/controller/homeController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyHomePage extends StatelessWidget {
  MyHomePage({super.key});

  final HomeController homeController = Get.put(
    HomeController(),
    permanent: false,
  );

  Future<void> _openUploadDialog() async {
    final userId = homeController.auth.getCurrentUser()?.id;
    if (userId == null) return;

    final folderCtrl = TextEditingController();

    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Upload Files'),
        content: Row(
          children: [
            Text(
              "\$ ${homeController.currentUsername ?? ''} / ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: folderCtrl,
                decoration: const InputDecoration(
                  hintText: 'Folder name (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Upload'),
          ),
        ],
      ),
    );

    if (result == true) {
      final folder = folderCtrl.text.trim();

      // Upload files
      final uploadedUrls = await homeController.storage.uploadMultipleFiles(
        userId: userId,
        folder: folder.isEmpty ? 'uploads' : folder,
      );

      if (uploadedUrls.isNotEmpty) {
        // Refresh ONLY the file list
        homeController.refreshFiles(); // Also refresh controller

        Get.showSnackbar(
          GetSnackBar(
            message: '${uploadedUrls.length} file(s) uploaded!',
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      body: isMobile ? const MobileWidgetBody() : const WebWidgetBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openUploadDialog,
        child: const Icon(Icons.upload),
      ),
    );
  }
}
