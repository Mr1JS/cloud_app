import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:get/get.dart';

class DragAndDropWidget extends StatefulWidget {
  final bool multiple;
  final VoidCallback? ontap;
  final void Function(List<int> bytes, String filename)? onFileConfirmed;
  final void Function(List<({List<int> bytes, String filename})> files)?
  onFilesConfirmed;

  const DragAndDropWidget({
    super.key,
    this.multiple = false,
    this.ontap,
    this.onFileConfirmed,
    this.onFilesConfirmed,
  });

  @override
  State<DragAndDropWidget> createState() => _DragAndDropWidgetState();
}

class _DragAndDropWidgetState extends State<DragAndDropWidget> {
  late DropzoneViewController _controller;
  bool _hovering = false;

  // single
  dynamic _pending;
  String? _pendingName;

  // multiple
  final List<({dynamic file, String name})> _pendingList = [];

  Future<void> _onDrop(dynamic file) async {
    final name = await _controller.getFilename(file);
    setState(() {
      if (widget.multiple) {
        _pendingList.add((file: file, name: name));
      } else {
        _pending = file;
        _pendingName = name;
      }
    });
  }

  Future<void> _confirmSingle() async {
    if (_pending == null) return;
    if (widget.onFileConfirmed != null) {
      final bytes = await _controller.getFileData(_pending);
      widget.onFileConfirmed!(bytes, _pendingName ?? 'file');
    }
    Get.back();
  }

  Future<void> _confirmMultiple() async {
    if (_pendingList.isEmpty) return;
    if (widget.onFilesConfirmed != null) {
      final result = <({List<int> bytes, String filename})>[];
      for (final f in _pendingList) {
        final bytes = await _controller.getFileData(f.file);
        result.add((bytes: bytes, filename: f.name));
      }
      widget.onFilesConfirmed!(result);
    }
    Get.back();
  }

  void _cancelSingle() => setState(() {
    _pending = null;
    _pendingName = null;
  });
  void _removeAt(int i) => setState(() => _pendingList.removeAt(i));

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DottedBorder(
          options: RoundedRectDottedBorderOptions(
            radius: const Radius.circular(11),
            color: Colors.blue,
            strokeWidth: 2,
            dashPattern: const [6, 3],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: _hovering
                  ? Colors.blue.shade900.withAlpha(50)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                DropzoneView(
                  onCreated: (c) => _controller = c,
                  onDropFile: _onDrop,
                  onHover: () => setState(() => _hovering = true),
                  onLeave: () => setState(() => _hovering = false),
                ),
                Center(
                  child: widget.multiple
                      ? _dropViewMultiple()
                      : (_pending != null
                            ? _confirmViewSingle()
                            : _dropViewSingle()),
                ),
              ],
            ),
          ),
        ),

        // multiple: pending list + confirm below the box
        if (widget.multiple && _pendingList.isNotEmpty) ...[
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _pendingList
                    .asMap()
                    .entries
                    .map(
                      (e) => Row(
                        children: [
                          const Icon(
                            Icons.insert_drive_file_outlined,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              e.value.name,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => _removeAt(e.key),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _confirmMultiple,
                child: Text(
                  'Upload ${_pendingList.length} file${_pendingList.length > 1 ? 's' : ''}',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _dropViewSingle() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.blue),
      const SizedBox(height: 8),
      const Text('Drop an image here or', textAlign: TextAlign.center),
      const SizedBox(height: 8),
      ElevatedButton(
        onPressed:
            widget.ontap ??
            () async {
              final files = await _controller.pickFiles(
                multiple: false,
                mime: const [
                  'image/jpeg',
                  'image/png',
                  'image/gif',
                  'image/webp',
                ],
              );
              if (files.isNotEmpty) _onDrop(files.first);
            },
        child: const Text('Select Image'),
      ),
    ],
  );

  Widget _dropViewMultiple() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.blue),
      const SizedBox(height: 8),
      const Text('Drop files here or', textAlign: TextAlign.center),
      const SizedBox(height: 8),
      ElevatedButton(
        onPressed: () async {
          final files = await _controller.pickFiles(multiple: true);
          for (final f in files) {
            _onDrop(f);
          }
        },
        child: const Text('Select Files'),
      ),
    ],
  );

  Widget _confirmViewSingle() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(
        Icons.insert_drive_file_outlined,
        size: 36,
        color: Colors.blue,
      ),
      const SizedBox(height: 8),
      Text(
        _pendingName ?? '',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      const Text('Use this image?'),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton(onPressed: _cancelSingle, child: const Text('Cancel')),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _confirmSingle,
            child: const Text('Confirm'),
          ),
        ],
      ),
    ],
  );
}
