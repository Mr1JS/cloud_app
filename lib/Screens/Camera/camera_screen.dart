import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller.initialize();

    if (!mounted) {
      controller.dispose();
      return;
    }

    setState(() {
      _controller = controller;
      _initializeControllerFuture = Future.value();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      if (!(_controller?.value.isInitialized ?? false)) return;

      final image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();

      if (!mounted) return;

      Navigator.of(Get.context!).pop({
        'bytes': bytes,
        'name': 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
      });
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _controller != null) {
            final controller = _controller!;
            return Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: CameraPreview(controller),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (_controller?.value.isInitialized ?? false)
            ? _takePicture
            : null,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
