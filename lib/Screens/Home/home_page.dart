import 'dart:io';

import 'package:cloud_app/Screens/Camera/camera_screen.dart';
import 'package:cloud_app/Screens/Home/Widgets/drag_and_drop_widget.dart';
import 'package:cloud_app/Screens/Home/mobile_body.dart';
import 'package:cloud_app/Screens/Home/web_body.dart';
import 'package:cloud_app/Screens/Home/Controller/home_controller.dart';
import 'package:flutter/foundation.dart';
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

    final folderController = TextEditingController();
    final scrollController = ScrollController();
    final pending = <({String name, Uint8List bytes})>[].obs;

    await Get.dialog(
      Obx(
        () => Center(
          child: AlertDialog(
            title: const Text('Upload Files'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Destination
                    const Text(
                      'Destination',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${homeController.currentUsername} / ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: TextField(
                            controller: folderController,
                            decoration: const InputDecoration(
                              hintText: 'folder (default: uploads)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Add Files
                    const Text(
                      'Add Files',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Web: drag & drop picker
                          if (kIsWeb)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.upload_file, size: 16),
                              label: const Text('Select Files'),
                              onPressed: () {
                                Get.dialog(
                                  AlertDialog(
                                    title: const Text('Drop or Select Files'),
                                    content: SingleChildScrollView(
                                      child: DragAndDropWidget(
                                        multiple: true,
                                        onFilesConfirmed: (files) {
                                          for (final f in files) {
                                            pending.add((
                                              name: f.filename,
                                              bytes: Uint8List.fromList(
                                                f.bytes,
                                              ),
                                            ));
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                          // Mobile: native picker
                          if (!kIsWeb)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.upload_file, size: 16),
                              label: const Text('Select Files'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                textStyle: const TextStyle(fontSize: 13),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () async {
                                final files = await homeController.storage
                                    .pickMultipleFiles();
                                for (final f in files) {
                                  if (f.bytes != null) {
                                    pending.add((
                                      name: f.name,
                                      bytes: f.bytes!,
                                    ));
                                  }
                                }
                              },
                            ),

                          const SizedBox(width: 8),

                          // Camera (web + mobile)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt), // size: 16),
                            label: const Text('Take a photo'),
                            style: !kIsWeb && Platform.isAndroid
                                ? ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    textStyle: const TextStyle(fontSize: 13),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  )
                                : null,
                            onPressed: () async {
                              final result = await Navigator.of(Get.context!)
                                  .push<Map<String, dynamic>>(
                                    MaterialPageRoute(
                                      builder: (_) => const CameraScreen(),
                                    ),
                                  );
                              if (result != null) {
                                pending.add((
                                  name: result['name'] as String,
                                  bytes: result['bytes'] as Uint8List,
                                ));
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    // File list
                    if (pending.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Files to upload',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 160),
                        child: Scrollbar(
                          thumbVisibility: true,
                          controller: scrollController,
                          child: ListView.builder(
                            controller: scrollController,
                            shrinkWrap: true,
                            itemCount: pending.length,
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.insert_drive_file_outlined,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      pending[i].name,
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => pending.removeAt(i),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: pending.isEmpty
                    ? null
                    : () async {
                        Get.back();
                        final folder = folderController.text.trim();
                        final path = folder.isEmpty
                            ? 'uploads'
                            : folder == "profile"
                            ? "profile1"
                            : folder;
                        int count = 0;
                        for (final f in pending) {
                          final resolvedName = await homeController.storage
                              .resolveUniqueFilename(
                                userId: userId,
                                folder: path,
                                filename: f.name,
                              );

                          final url = await homeController.storage
                              .uploadImageFromCamera(
                                userId: userId,
                                folder: path,
                                bytes: f.bytes,
                                filename: resolvedName,
                              );
                          if (url != null) count++;
                        }
                        if (count > 0) {
                          homeController.refreshFiles();
                          Get.showSnackbar(
                            GetSnackBar(
                              message: '$count file(s) uploaded!',
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                child: Text(
                  pending.isEmpty
                      ? 'Upload'
                      : 'Upload ${pending.length} file${pending.length > 1 ? 's' : ''}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return SafeArea(
      child: Scaffold(
        body: isMobile ? const MobileWidgetBody() : const WebWidgetBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: _handleUpload,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
