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
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera([int index = 0]) async {
    final old = _controller;
    setState(() {
      _controller = null;
      _error = null;
    });
    await old?.dispose();

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'No cameras found.');
        return;
      }

      final controller = CameraController(
        _cameras[index],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _cameraIndex = index;
      });
    } on CameraException catch (e) {
      setState(
        () => _error = e.code == 'CameraAccessDenied'
            ? 'Permission denied. Enable camera in Settings.'
            : 'Camera error: ${e.description}',
      );
    }
  }

  Future<void> _takePicture() async {
    if (!(_controller?.value.isInitialized ?? false)) return;
    final image = await _controller!.takePicture();
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    Navigator.of(Get.context!).pop({
      'bytes': bytes,
      'name': 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Take a photo'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(child: _error != null ? _buildError() : _buildCamera()),
    );
  }

  Widget _buildCamera() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final ratio = c.value.aspectRatio;
    // Camera reports landscape ratio always — invert in portrait
    final aspectRatio = isPortrait ? 1.0 / ratio : ratio;

    // Use aspectRatio from controller — works correctly in both orientations
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Center(
          child: AspectRatio(aspectRatio: aspectRatio, child: CameraPreview(c)),
        ),

        Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_cameras.length > 1)
                IconButton(
                  icon: const Icon(Icons.flip_camera_android, size: 32),
                  color: Colors.blue,
                  onPressed: () =>
                      _initCamera((_cameraIndex + 1) % _cameras.length),
                )
              else
                const SizedBox(width: 48),

              GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue, width: 4),
                    color: Colors.blue,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),

              const SizedBox(width: 48),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography, color: Colors.white54, size: 60),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              onPressed: () => _initCamera(_cameraIndex),
            ),
          ],
        ),
      ),
    );
  }
}
