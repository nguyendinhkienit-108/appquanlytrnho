import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:image_picker/image_picker.dart';

import 'live_translate_screen.dart';

class _TranslatedLine {
  final Rect boundingBox;
  final String text;
  const _TranslatedLine(this.boundingBox, this.text);
}

class LearningAssistantScreen extends StatefulWidget {
  const LearningAssistantScreen({super.key});

  @override
  State<LearningAssistantScreen> createState() =>
      _LearningAssistantScreenState();
}

class _LearningAssistantScreenState extends State<LearningAssistantScreen> {
  static const blue = Color(0xFF168FE0);
  static const pageColor = Color(0xFFF2F9FF);

  final _picker = ImagePicker();
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _modelManager = OnDeviceTranslatorModelManager();

  File? _image;
  Size? _imageSize;
  List<_TranslatedLine> _translatedLines = [];
  String _status = 'Chọn ảnh hoặc chụp bằng camera để bắt đầu.';
  bool _busy = false;
  bool _englishToVietnamese = true;
  bool _showOriginal = false;

  @override
  void dispose() {
    _recognizer.close();
    super.dispose();
  }

  Future<void> _fromCamera() async {
    if (_busy) return;
    try {
      final file = await Navigator.of(context).push<XFile>(
        MaterialPageRoute(builder: (_) => const _CameraCaptureScreen()),
      );
      if (file != null && mounted) await _process(file);
    } catch (e) {
      if (mounted) setState(() => _status = 'Lỗi camera: $e');
    }
  }

  Future<void> _fromGallery() async {
    if (_busy) return;
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null && mounted) await _process(file);
    } catch (e) {
      if (mounted) setState(() => _status = 'Lỗi chọn ảnh: $e');
    }
  }

  Future<void> _process(XFile picked) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = 'Đang đọc chữ trong ảnh...';
      _image = File(picked.path);
      _imageSize = null;
      _translatedLines = [];
      _showOriginal = false;
    });

    OnDeviceTranslator? translator;
    try {
      // Decode image size for correct OCR bounding-box positioning.
      final bytes = await File(picked.path).readAsBytes();
      final ui.Image decoded = await decodeImageFromList(bytes);
      final size = Size(decoded.width.toDouble(), decoded.height.toDouble());
      decoded.dispose();

      final recognized = await _recognizer.processImage(
        InputImage.fromFilePath(picked.path),
      );
      if (!mounted) return;

      final lines = recognized.blocks
          .expand((block) => block.lines)
          .where((line) => line.text.trim().isNotEmpty)
          .toList();

      if (lines.isEmpty) {
        setState(() {
          _imageSize = size;
          _status = 'Không tìm thấy chữ rõ trong ảnh.';
        });
        return;
      }

      final source = _englishToVietnamese
          ? TranslateLanguage.english
          : TranslateLanguage.vietnamese;
      final target = _englishToVietnamese
          ? TranslateLanguage.vietnamese
          : TranslateLanguage.english;

      for (final language in [source, target]) {
        final code = language.bcpCode;
        final available = await _modelManager.isModelDownloaded(code);
        if (!available) {
          if (mounted) {
            setState(() => _status = 'Đang tải mô hình $code (lần đầu cần Internet)...');
          }
          final ok = await _modelManager.downloadModel(code);
          if (!ok) throw Exception('Không tải được mô hình $code');
        }
      }

      translator = OnDeviceTranslator(
        sourceLanguage: source,
        targetLanguage: target,
      );
      final translations = <_TranslatedLine>[];
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (mounted) {
          setState(() => _status = 'Đang dịch ${i + 1}/${lines.length} dòng...');
        }
        final translation = await translator.translateText(line.text);
        translations.add(_TranslatedLine(line.boundingBox, translation));
      }

      if (!mounted) return;
      setState(() {
        _imageSize = size;
        _translatedLines = translations;
        _status = 'Đã dịch ${translations.length} dòng trực tiếp trên ảnh.';
      });
    } catch (e) {
      if (mounted) setState(() => _status = 'Không xử lý được ảnh: $e');
    } finally {
      await translator?.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _imageWithTranslation() {
    final image = _image;
    final size = _imageSize;
    if (image == null) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('Chưa có ảnh. Hãy chụp hoặc chọn ảnh.')),
      );
    }
    if (size == null) {
      return SizedBox(
        height: 220,
        child: Center(
          child: _busy ? const CircularProgressIndicator() : Image.file(image),
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final displayWidth = constraints.maxWidth;
      final scale = displayWidth / size.width;
      final displayHeight = size.height * scale;
      return SizedBox(
        width: displayWidth,
        height: displayHeight,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(child: Image.file(image, fit: BoxFit.fill)),
            if (!_showOriginal)
              ..._translatedLines.map((line) {
                final r = line.boundingBox;
                final left = r.left * scale;
                final top = r.top * scale;
                final width = r.width * scale;
                final height = r.height * scale;
                if (width <= 0 || height <= 0) return const SizedBox.shrink();
                return Positioned(
                  left: left,
                  top: top,
                  width: width,
                  height: height,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        line.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        title: const Text('Dịch chữ trên ảnh'),
        backgroundColor: pageColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB9E5FF), Color(0xFFE5F6FF)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(children: [
              Icon(Icons.translate_rounded, color: blue, size: 42),
              SizedBox(height: 8),
              Text('Dịch ngay trên ảnh',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text('Bản dịch được đặt tại vị trí chữ gốc.',
                  textAlign: TextAlign.center),
            ]),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<bool>(
            initialValue: _englishToVietnamese,
            decoration: const InputDecoration(
              labelText: 'Hướng dịch',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: true, child: Text('Anh → Việt')),
              DropdownMenuItem(value: false, child: Text('Việt → Anh')),
            ],
            onChanged: _busy ? null : (value) {
              if (value == null) return;
              setState(() => _englishToVietnamese = value);
              // Existing translation refers to the previous language pair.
              if (_image != null) {
                setState(() {
                  _translatedLines = [];
                  _showOriginal = true;
                  _status = 'Đã đổi ngôn ngữ. Nhấn Dịch lại để cập nhật ảnh.';
                });
              }
            },
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : _fromCamera,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Chụp ảnh'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _fromGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Thư viện'),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy || _image == null ? null : () => _process(XFile(_image!.path)),
            icon: const Icon(Icons.refresh),
            label: const Text('Dịch lại ảnh hiện tại'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LiveTranslateScreen()),
            ),
            icon: const Icon(Icons.videocam_outlined),
            label: const Text('Camera dịch liên tục (màn hình riêng)'),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFDCEFFD)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _imageWithTranslation(),
            ),
          ),
          if (_translatedLines.isNotEmpty)
            SwitchListTile.adaptive(
              title: const Text('Hiển thị chữ gốc'),
              value: _showOriginal,
              onChanged: (value) => setState(() => _showOriginal = value),
            ),
          if (_busy) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(_status),
          ),
          const SizedBox(height: 14),
          const Text(
            'Bản dịch là lớp chữ phủ lên ảnh trong ứng dụng; ảnh gốc không bị thay đổi. '
                'Lần đầu dùng dịch cần tải mô hình AI qua Internet.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
class _CameraCaptureScreen extends StatefulWidget {
  const _CameraCaptureScreen();

  @override
  State<_CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<_CameraCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _takingPicture = false;
  String? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final currentGeneration = ++_generation;
    try {
      final cameras = await availableCameras();
      if (!mounted || currentGeneration != _generation) return;
      if (cameras.isEmpty) {
        setState(() => _error = 'Emulator không cung cấp camera.');
        return;
      }
      final rear = cameras.where((camera) =>
      camera.lensDirection == CameraLensDirection.back);
      final selected = rear.isNotEmpty ? rear.first : cameras.first;
      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _controller = controller;
      final init = controller.initialize();
      await init;
      if (!mounted || currentGeneration != _generation) return;
      setState(() => _error = null);
    } catch (e) {
      if (mounted && currentGeneration == _generation) {
        setState(() => _error = 'Không khởi tạo được camera: $e');
      }
    }
  }

  Future<void> _releaseCamera() async {
    ++_generation;
    final controller = _controller;
    _controller = null;
    if (controller != null) await controller.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _releaseCamera();
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _initializeCamera();
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (_takingPicture || controller == null || !controller.value.isInitialized) {
      return;
    }
    setState(() => _takingPicture = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(file);
    } catch (e) {
      if (mounted) setState(() => _error = 'Không chụp được ảnh: $e');
    } finally {
      if (mounted) setState(() => _takingPicture = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _releaseCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Camera tài liệu'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _error != null
                  ? Padding(
                padding: const EdgeInsets.all(20),
                child: Text(_error!, style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center),
              )
                  : controller != null && controller.value.isInitialized
                  ? CameraPreview(controller)
                  : const CircularProgressIndicator(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: FilledButton.icon(
              onPressed: _takingPicture || controller == null ||
                  !controller.value.isInitialized ? null : _capture,
              icon: const Icon(Icons.camera_alt),
              label: Text(_takingPicture ? 'Đang chụp...' : 'Chụp và dịch'),
            ),
          ),
        ],
      ),
    );
  }
}
