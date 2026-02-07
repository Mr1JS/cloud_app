import 'package:cloud_app/Screens/Camera/camera_screen.dart';
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

  // UPLOAD HANDLER
  // upload multiple files or take a photo with the camera
  Future<void> _handleUpload() async {
    final userId = homeController.auth.currentUser?.id;
    if (userId == null) return;

    final isCamera =
        await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Upload'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Get.back(result: true),
                ),
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Files'),
                  onTap: () => Get.back(result: false),
                ),
              ],
            ),
          ),
        ) ??
        false;

    final folderController = TextEditingController();
    final upload = await Get.dialog<bool>(
      AlertDialog(
        title: Text(isCamera ? 'Upload Photo' : 'Upload Files'),
        content: Row(
          children: [
            Text(
              "${homeController.currentUsername} / ",
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
            child: Text(isCamera ? 'Take Photo' : 'Upload'),
          ),
        ],
      ),
    );

    if (upload != true) return;

    final folder = folderController.text.trim();
    final path = folder.isEmpty ? 'uploads' : folder;

    if (isCamera) {
      String? url;

      // NEU: Camera Screen für Web + Mobile
      final result = await Navigator.of(Get.context!)
          .push<Map<String, dynamic>>(
            MaterialPageRoute(builder: (_) => const CameraScreen()),
          );

      if (result != null) {
        url = await homeController.storage.uploadImageFromCamera(
          userId: userId,
          folder: path,
          bytes: result['bytes'],
          filename: result['name'],
        );
      }

      if (url != null) {
        homeController.refreshFiles();
        Get.showSnackbar(
          const GetSnackBar(
            message: 'Photo uploaded!',
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      final urls = await homeController.storage.uploadMultipleFiles(
        userId: userId,
        folder: path,
      );
      if (urls.isNotEmpty) {
        homeController.refreshFiles();
        Get.showSnackbar(
          GetSnackBar(
            message: '${urls.length} file(s) uploaded!',
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
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
        onPressed: _handleUpload,
        child: const Icon(Icons.add),
      ),
    );
  }
}
