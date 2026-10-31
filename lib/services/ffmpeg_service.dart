import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import 'package:capcut_clone/models/video_clip.dart';
import 'package:capcut_clone/services/filter_builder.dart';

class _RunResult {
  final bool ok;
  final String logs;
  const _RunResult(this.ok, this.logs);
}

class FFmpegService {
  /// Menggabungkan semua klip (trim + filter + transisi) menjadi satu file MP4.
  /// Jika export dengan audio gagal (misalnya ada video tanpa suara),
  /// otomatis dicoba ulang tanpa audio.
  static Future<String> exportProject({
    required List<VideoClip> clips,
    required String outputPath,
    required int width,
    required int height,
  }) async {
    if (clips.isEmpty) {
      throw Exception('Tidak ada klip untuk diekspor');
    }

    final withAudio = await _run(clips, outputPath, width, height, true);
    if (withAudio.ok) return outputPath;

    final videoOnly = await _run(clips, outputPath, width, height, false);
    if (videoOnly.ok) return outputPath;

    throw Exception('FFmpeg gagal:\n${_tail(withAudio.logs)}');
  }

  static Future<_RunResult> _run(
    List<VideoClip> clips,
    String outputPath,
    int width,
    int height,
    bool withAudio,
  ) async {
    final args = <String>['-y'];
    for (final clip in clips) {
      args.add('-i');
      args.add(clip.filePath);
    }

    args.addAll([
      '-filter_complex',
      FilterBuilder.build(
        clips: clips,
        width: width,
        height: height,
        withAudio: withAudio,
      ),
      '-map',
      '[vout]',
    ]);

    if (withAudio) {
      args.addAll(['-map', '[aout]', '-c:a', 'aac', '-b:a', '192k']);
    }

    args.addAll([
      '-c:v',
      'libx264',
      '-preset',
      'veryfast',
      '-crf',
      '23',
      '-pix_fmt',
      'yuv420p',
      '-movflags',
      '+faststart',
      outputPath,
    ]);

    final session = await FFmpegKit.executeWithArguments(args);
    final code = await session.getReturnCode();
    if (ReturnCode.isSuccess(code)) {
      return const _RunResult(true, '');
    }
    final logs = await session.getLogsAsString();
    return _RunResult(false, logs ?? '');
  }

  static String _tail(String logs) {
    const maxLength = 900;
    if (logs.length <= maxLength) return logs;
    return logs.substring(logs.length - maxLength);
  }
}
