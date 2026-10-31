import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import 'package:capcut_clone/config/app_config.dart';
import 'package:capcut_clone/models/transition_effect.dart';
import 'package:capcut_clone/models/video_clip.dart';
import 'package:capcut_clone/services/ffmpeg_service.dart';

class EditorProvider extends ChangeNotifier {
  final List<VideoClip> _timeline = [];
  int _selectedIndex = 0;
  VideoPlayerController? _controller;
  int _loadToken = 0;
  bool _isProcessing = false;
  String _statusMessage = '';
  bool _portrait = true;

  List<VideoClip> get timeline => List.unmodifiable(_timeline);
  int get selectedIndex => _selectedIndex;
  VideoPlayerController? get controller => _controller;
  bool get isProcessing => _isProcessing;
  String get statusMessage => _statusMessage;

  VideoClip? get selectedClip =>
      (_selectedIndex >= 0 && _selectedIndex < _timeline.length)
          ? _timeline[_selectedIndex]
          : null;

  int get outputWidth => _portrait ? AppConfig.shortSide : AppConfig.longSide;
  int get outputHeight => _portrait ? AppConfig.longSide : AppConfig.shortSide;

  /// Mengosongkan proyek dan melepas video player.
  void reset() {
    _loadToken++;
    _retireController();
    _timeline.clear();
    _selectedIndex = 0;
    _portrait = true;
    notifyListeners();
  }

  /// Menambah video ke timeline. Mengembalikan pesan error, atau null jika sukses.
  Future<String?> addVideo(String path) async {
    try {
      final probe = VideoPlayerController.file(File(path));
      await probe.initialize();
      final seconds = probe.value.duration.inMilliseconds / 1000.0;
      final size = probe.value.size;
      await probe.dispose();

      if (seconds <= 0) {
        return 'Video tidak valid (durasi 0).';
      }

      if (_timeline.isEmpty) {
        _portrait = size.height >= size.width;
      }

      _timeline.add(
        VideoClip(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          filePath: path,
          sourceDuration: seconds,
          startTime: 0,
          endTime: seconds,
        ),
      );
      await selectClip(_timeline.length - 1);
      return null;
    } catch (e) {
      return 'Gagal memuat video: $e';
    }
  }

  Future<void> selectClip(int index) async {
    if (index < 0 || index >= _timeline.length) return;
    _selectedIndex = index;
    final token = ++_loadToken;
    final clip = _timeline[index];

    _retireController();
    notifyListeners();

    final next = VideoPlayerController.file(File(clip.filePath));
    try {
      await next.initialize();
    } catch (e) {
      await next.dispose();
      if (token == _loadToken) {
        _statusMessage = 'Gagal memutar video: $e';
        notifyListeners();
      }
      return;
    }

    if (token != _loadToken) {
      await next.dispose();
      return;
    }

    _controller = next;
    next.addListener(_onControllerTick);
    await next.seekTo(_ms(clip.startTime));
    notifyListeners();
  }

  void updateClipFilter(String filterName) {
    final clip = selectedClip;
    if (clip == null) return;
    _timeline[_selectedIndex] = clip.copyWith(activeFilter: filterName);
    notifyListeners();
  }

  void updateClipTransition(TransitionEffect effect) {
    final clip = selectedClip;
    if (clip == null) return;
    _timeline[_selectedIndex] = clip.copyWith(transitionOut: effect);
    notifyListeners();
  }

  void updateClipTrim(double start, double end) {
    final clip = selectedClip;
    if (clip == null) return;

    final s = start.clamp(0.0, clip.sourceDuration).toDouble();
    final e = end.clamp(0.0, clip.sourceDuration).toDouble();
    if (e - s < AppConfig.minClipLength) return;

    final startChanged = (s - clip.startTime).abs() > 0.001;
    _timeline[_selectedIndex] = clip.copyWith(startTime: s, endTime: e);
    if (startChanged) {
      _controller?.seekTo(_ms(s));
    }
    notifyListeners();
  }

  Future<void> removeSelected() async {
    if (_timeline.isEmpty) return;
    _timeline.removeAt(_selectedIndex);
    if (_timeline.isEmpty) {
      _loadToken++;
      _retireController();
      _selectedIndex = 0;
      notifyListeners();
      return;
    }
    await selectClip(_selectedIndex.clamp(0, _timeline.length - 1).toInt());
  }

  Future<void> togglePlayPause() async {
    final c = _controller;
    final clip = selectedClip;
    if (c == null || clip == null || !c.value.isInitialized) return;

    if (c.value.isPlaying) {
      await c.pause();
      return;
    }

    final position = c.value.position;
    if (position >= _ms(clip.endTime) || position < _ms(clip.startTime)) {
      await c.seekTo(_ms(clip.startTime));
    }
    await c.play();
  }

  /// Export seluruh timeline lalu simpan ke galeri. Mengembalikan pesan hasil.
  Future<String> exportToGallery() async {
    if (_timeline.isEmpty) return 'Belum ada klip di timeline.';
    if (_isProcessing) return 'Export sedang berjalan.';

    _isProcessing = true;
    _statusMessage = 'Memproses video... jangan tutup aplikasi';
    notifyListeners();

    String? outputPath;
    try {
      await _controller?.pause();

      final dir = await getTemporaryDirectory();
      outputPath =
          '${dir.path}/export_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await FFmpegService.exportProject(
        clips: List<VideoClip>.of(_timeline),
        outputPath: outputPath,
        width: outputWidth,
        height: outputHeight,
      );

      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }
      await Gal.putVideo(outputPath);

      return 'Selesai! Video tersimpan di galeri.';
    } catch (e) {
      return 'Export gagal: $e';
    } finally {
      if (outputPath != null) {
        try {
          final f = File(outputPath);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
      _isProcessing = false;
      _statusMessage = '';
      notifyListeners();
    }
  }

  // ---- internal ----

  Duration _ms(double seconds) =>
      Duration(milliseconds: (seconds * 1000).round());

  void _onControllerTick() {
    final c = _controller;
    final clip = selectedClip;
    if (c == null) return;
    if (clip != null &&
        c.value.isPlaying &&
        c.value.position >= _ms(clip.endTime)) {
      c.pause();
    }
    notifyListeners();
  }

  /// Melepas controller lama; dispose ditunda sampai frame berikutnya
  /// supaya widget VideoPlayer tidak memakai controller yang sudah di-dispose.
  void _retireController() {
    final old = _controller;
    _controller = null;
    if (old == null) return;
    old.removeListener(_onControllerTick);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      old.dispose();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerTick);
    _controller?.dispose();
    super.dispose();
  }
}
