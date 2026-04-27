import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class CachedMapSnapshot extends StatefulWidget {
  const CachedMapSnapshot({
    super.key,
    required this.cacheKey,
    required this.child,
    this.captureDelay = const Duration(seconds: 2),
  });

  final String cacheKey;
  final Widget child;
  final Duration captureDelay;

  @override
  State<CachedMapSnapshot> createState() => _CachedMapSnapshotState();
}

class _CachedMapSnapshotState extends State<CachedMapSnapshot> {
  final _boundaryKey = GlobalKey();
  File? _snapshotFile;
  bool _cacheUnavailable = false;
  bool _captureScheduled = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSnapshot());
  }

  @override
  void didUpdateWidget(covariant CachedMapSnapshot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cacheKey != widget.cacheKey) {
      _snapshotFile = null;
      _cacheUnavailable = false;
      _captureScheduled = false;
      unawaited(_loadSnapshot());
    }
  }

  Future<void> _loadSnapshot() async {
    final file = await _resolveSnapshotFile();
    if (!mounted || file == null) return;

    if (await file.exists()) {
      setState(() {
        _snapshotFile = file;
      });
      return;
    }

    _scheduleCapture(file);
  }

  Future<File?> _resolveSnapshotFile() async {
    if (_cacheUnavailable) return null;
    try {
      final directory = await getApplicationSupportDirectory();
      final snapshotDirectory = Directory(
        '${directory.path}${Platform.pathSeparator}map_snapshots',
      );
      await snapshotDirectory.create(recursive: true);
      return File(
        '${snapshotDirectory.path}${Platform.pathSeparator}'
        '${_safeFileName(widget.cacheKey)}.png',
      );
    } on MissingPluginException {
      _cacheUnavailable = true;
      return null;
    } on FileSystemException {
      _cacheUnavailable = true;
      return null;
    }
  }

  String _safeFileName(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  void _scheduleCapture(File file) {
    if (_captureScheduled) return;
    _captureScheduled = true;
    Future<void>.delayed(widget.captureDelay, () async {
      if (!mounted || _snapshotFile != null) return;
      await _capture(file);
    });
  }

  Future<void> _capture(File file) async {
    try {
      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null || boundary.debugNeedsPaint) return;

      final image = await boundary.toImage(pixelRatio: 1.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final bytes = byteData?.buffer.asUint8List();
      if (bytes == null) return;

      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      setState(() {
        _snapshotFile = file;
      });
    } on Object {
      // Snapshot caching is an optimization. The live map remains the fallback.
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshotFile = _snapshotFile;
    return RepaintBoundary(
      key: _boundaryKey,
      child: snapshotFile == null
          ? widget.child
          : Image.file(
              snapshotFile,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
    );
  }
}
