import 'package:cloud_app/Screens/Home/mobile_body.dart';
import 'package:cloud_app/Screens/Home/web_body.dart';
import 'package:cloud_app/Screens/Home/Controller/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyHomePage extends StatelessWidget {
  MyHomePage({super.key});

  late final HomeController homeController = Get.put(
    HomeController(),
    permanent: false,
  );

  // Display dialog to upload files
  Future<void> _openUploadDialog() async {
    final userId = homeController.auth.currentUser?.id;
    if (userId == null) return;

    final folderController = TextEditingController();

    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Upload Files'),
        content: Row(
          children: [
            Text(
              "\$ ${homeController.currentUsername} / ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: folderController,
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

    if (result != true) return;

    final folder = folderController.text.trim();

    final uploadedUrls = await homeController.storage.uploadMultipleFiles(
      userId: userId,
      folder: folder.isEmpty ? 'uploads' : folder,
    );

    if (uploadedUrls.isEmpty) return;

    homeController.refreshFiles();

    Get.showSnackbar(
      GetSnackBar(
        message: '${uploadedUrls.length} file(s) uploaded!',
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
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
