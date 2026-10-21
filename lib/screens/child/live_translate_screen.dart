import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// Live translation overlay for Android back camera.
/// The overlay tracks the largest recognized text line.
class LiveTranslateScreen extends StatefulWidget {
  const LiveTranslateScreen({super.key});

  @override
  State<LiveTranslateScreen> createState() => _LiveTranslateScreenState();
}

class _LiveTranslateScreenState extends State<LiveTranslateScreen> {
  static const _background = Color(0xFFF2F9FF);

  CameraController? _camera;
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _modelManager = OnDeviceTranslatorModelManager();
  OnDeviceTranslator? _translator;

  bool _closed = false;
  bool _ready = false;
  bool _processing = false;
  bool _englishToVietnamese = true;
  DateTime? _lastScan;
  String _status = 'Đang mở camera...';
  String _recognized = '';
  String _translated = '';
  Rect? _textRect;
  Size? _orientedImageSize;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _statusMessage(String value) {
    if (mounted && !_closed) setState(() => _status = value);
  }

  Future<void> _start() async {
    try {
      if (!Platform.isAndroid) {
        throw Exception('Tính năng này hỗ trợ Android.');
      }
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('Không tìm thấy camera.');
      final back = cameras.where(
            (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      final selected = back.isNotEmpty ? back.first : cameras.first;
      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      _camera = controller;
      await controller.initialize();
      if (!mounted || _closed) return;
      _statusMessage('Đang chuẩn bị mô hình dịch...');
      await _prepareTranslator();
      if (!mounted || _closed) return;
      setState(() {
        _ready = true;
        _status = 'Đưa dòng chữ vào khung hình';
      });
      await controller.startImageStream(_onFrame);
    } catch (error) {
      _statusMessage('Không khởi tạo được: $error');
    }
  }

  Future<void> _prepareTranslator() async {
    final source = _englishToVietnamese
        ? TranslateLanguage.english
        : TranslateLanguage.vietnamese;
    final target = _englishToVietnamese
        ? TranslateLanguage.vietnamese
        : TranslateLanguage.english;
    for (final language in [source, target]) {
      if (_closed) return;
      final code = language.bcpCode;
      if (!await _modelManager.isModelDownloaded(code)) {
        _statusMessage('Đang tải mô hình $code (cần Internet lần đầu)...');
        final ok = await _modelManager.downloadModel(code);
        if (!ok) throw Exception('Không tải được mô hình $code.');
      }
    }
    if (_closed) return;
    _translator = OnDeviceTranslator(
      sourceLanguage: source,
      targetLanguage: target,
    );
  }

  InputImage? _inputImage(CameraImage frame) {
    final camera = _camera;
    if (camera == null || frame.planes.length != 1) return null;
    final format = InputImageFormatValue.fromRawValue(frame.format.raw);
    if (format != InputImageFormat.nv21) return null;

    final rotation = InputImageRotationValue.fromRawValue(
      camera.description.sensorOrientation,
    );
    if (rotation == null) return null;
    final plane = frame.planes.first;
    final Uint8List bytes = plane.bytes;
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(frame.width.toDouble(), frame.height.toDouble()),
        rotation: rotation,
        format: format!,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _onFrame(CameraImage frame) async {
    if (!_ready || _closed || _processing) return;
    final now = DateTime.now();
    if (_lastScan != null &&
        now.difference(_lastScan!).inMilliseconds < 900) {
      return;
    }
    _lastScan = now;

    final input = _inputImage(frame);
    if (input == null) {
      _statusMessage('Camera cần khung hình NV21 để nhận diện.');
      return;
    }
    _processing = true;
    try {
      final recognized = await _recognizer.processImage(input);
      if (_closed || !mounted) return;

      // For a legible demo, translate the largest visible text line.
      final lines = recognized.blocks.expand((block) => block.lines)
          .where((line) => line.text.trim().isNotEmpty).toList();
      if (lines.isEmpty) {
        _statusMessage('Đang tìm văn bản trong camera...');
        return;
      }
      lines.sort((a, b) =>
          (b.boundingBox.width * b.boundingBox.height).compareTo(
            a.boundingBox.width * a.boundingBox.height,
          ));
      final line = lines.first;
      final text = line.text.trim();
      final rotation = _camera!.description.sensorOrientation;
      final isSideways = rotation == 90 || rotation == 270;
      final sourceSize = Size(
        (isSideways ? frame.height : frame.width).toDouble(),
        (isSideways ? frame.width : frame.height).toDouble(),
      );

      if (text == _recognized && _translated.isNotEmpty) {
        setState(() {
          _textRect = line.boundingBox;
          _orientedImageSize = sourceSize;
          _status = 'Đang dịch trực tiếp trên camera';
        });
        return;
      }

      final translator = _translator;
      if (translator == null) return;
      final translation = await translator.translateText(text);
      if (_closed || !mounted) return;
      setState(() {
        _recognized = text;
        _translated = translation;
        _textRect = line.boundingBox;
        _orientedImageSize = sourceSize;
        _status = 'Đã phủ bản dịch lên camera';
      });
    } catch (error) {
      _statusMessage('Lỗi đọc hoặc dịch: $error');
    } finally {
      _processing = false;
    }
  }

  Future<void> _changeLanguage(bool next) async {
    if (next == _englishToVietnamese || !_ready || _closed) return;
    setState(() {
      _ready = false;
      _englishToVietnamese = next;
      _recognized = '';
      _translated = '';
      _textRect = null;
      _status = 'Đang đổi ngôn ngữ...';
    });
    while (_processing && !_closed) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    if (_closed) return;
    try {
      await _translator?.close();
      _translator = null;
      await _prepareTranslator();
      if (!mounted || _closed) return;
      setState(() {
        _ready = true;
        _status = 'Đưa dòng chữ vào khung hình';
      });
    } catch (error) {
      _statusMessage('Không thể đổi ngôn ngữ: $error');
    }
  }

  @override
  void dispose() {
    _closed = true;
    final camera = _camera;
    () async {
      try {
        if (camera != null) {
          if (camera.value.isStreamingImages) {
            await camera.stopImageStream();
          }
          await camera.dispose();
        }
      } catch (_) {}
    }();
    () async {
      while (_processing) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    await _translator?.close();
    await _recognizer.close();
    }();
    super.dispose();
  }

  Widget _cameraWithOverlay(CameraController controller) {
    // CameraPreview is laid out with its portrait aspect ratio.
    final portraitRatio = 1 / controller.value.aspectRatio;
    return AspectRatio(
      aspectRatio: portraitRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final bounds = _textRect;
          final original = _orientedImageSize;
          Rect? scaled;
          if (bounds != null && original != null &&
              original.width > 0 && original.height > 0) {
            // Overlay in the same portrait viewport as CameraPreview.
            final sx = width / original.width;
            final sy = height / original.height;
            scaled = Rect.fromLTRB(
              bounds.left * sx,
              bounds.top * sy,
              bounds.right * sx,
              bounds.bottom * sy,
            );
            scaled = Rect.fromLTRB(
              scaled.left.clamp(0.0, width).toDouble(),
              scaled.top.clamp(0.0, height).toDouble(),
              scaled.right.clamp(0.0, width).toDouble(),
              scaled.bottom.clamp(0.0, height).toDouble(),
            );
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller),
              if (scaled != null && _translated.isNotEmpty &&
                  scaled.width > 4 && scaled.height > 4)
                Positioned(
                  left: scaled.left,
                  top: scaled.top,
                  width: scaled.width,
                  height: scaled.height < 30 ? 30 : scaled.height,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3, vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xF5FFFFFF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _translated,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _camera;
    final cameraInitialized =
        controller != null && controller.value.isInitialized;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: const Text('Dịch trực tiếp trên camera',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: cameraInitialized
                ? _cameraWithOverlay(controller)
                : const SizedBox(
              height: 260,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(_status),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<bool>(
            initialValue: _englishToVietnamese,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Ngôn ngữ',
              filled: true,
              fillColor: Colors.white,
            ),
            items: const [
              DropdownMenuItem(value: true,
                  child: Text('Tiếng Anh → Tiếng Việt')),
              DropdownMenuItem(value: false,
                  child: Text('Tiếng Việt → Tiếng Anh')),
            ],
            onChanged: _ready ? (value) {
              if (value != null) _changeLanguage(value);
            } : null,
          ),
          const SizedBox(height: 16),
          const Text('Chữ gốc:', style: TextStyle(fontWeight: FontWeight.bold)),
          SelectableText(_recognized.isEmpty ? 'Đang nhận diện...' : _recognized),
          const SizedBox(height: 8),
          const Text('Bản dịch:', style: TextStyle(fontWeight: FontWeight.bold)),
          SelectableText(_translated.isEmpty ? 'Đang dịch...' : _translated),
          const SizedBox(height: 14),
          const Text(
            'Đưa một dòng chữ rõ nét vào khung hình. Bản dịch sẽ '
                'được phủ trực tiếp lên dòng chữ đó. '
                'Tọa độ lớp phủ có thể lệch trên một số máy ảo.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
