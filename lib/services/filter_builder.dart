import 'dart:math';

import 'package:capcut_clone/config/app_config.dart';
import 'package:capcut_clone/models/transition_effect.dart';
import 'package:capcut_clone/models/video_clip.dart';

/// Menyusun filter_complex FFmpeg:
/// 1. Tiap klip di-trim, diseragamkan (resolusi, fps, format) dan diberi filter warna.
/// 2. Klip digabung berantai dengan xfade (video) dan acrossfade (audio).
/// Hasil akhir selalu berlabel [vout] dan (jika withAudio) [aout].
class FilterBuilder {
  static String build({
    required List<VideoClip> clips,
    required int width,
    required int height,
    required bool withAudio,
  }) {
    final parts = <String>[];

    for (var i = 0; i < clips.length; i++) {
      final c = clips[i];
      final filter = AppConfig.availableFilters[c.activeFilter] ?? '';

      final v = StringBuffer()
        ..write('[$i:v]trim=start=${_s(c.startTime)}:end=${_s(c.endTime)},')
        ..write('setpts=PTS-STARTPTS,')
        ..write('scale=$width:$height:force_original_aspect_ratio=decrease,')
        ..write('pad=$width:$height:(ow-iw)/2:(oh-ih)/2:color=black,')
        ..write('setsar=1,fps=${AppConfig.exportFps},format=yuv420p');
      if (filter.isNotEmpty) {
        v.write(',$filter,format=yuv420p');
      }
      v.write('[v$i]');
      parts.add(v.toString());

      if (withAudio) {
        parts.add(
          '[$i:a]atrim=start=${_s(c.startTime)}:end=${_s(c.endTime)},'
          'asetpts=PTS-STARTPTS,aresample=44100,'
          'aformat=sample_fmts=fltp:channel_layouts=stereo[a$i]',
        );
      }
    }

    var videoLabel = '[v0]';
    var audioLabel = '[a0]';
    var accumulated = clips[0].duration;

    for (var i = 1; i < clips.length; i++) {
      final prev = clips[i - 1];
      final cur = clips[i];
      final t = _transitionDuration(prev.transitionOut, prev.duration, cur.duration);
      final offset = max(0.0, accumulated - t);
      final xfadeName = prev.transitionOut?.xfadeName ?? 'fade';

      parts.add(
        '$videoLabel[v$i]xfade=transition=$xfadeName:'
        'duration=${_s(t)}:offset=${_s(offset)}[vx$i]',
      );
      videoLabel = '[vx$i]';

      if (withAudio) {
        parts.add('$audioLabel[a$i]acrossfade=d=${_s(t)}:c1=tri:c2=tri[ax$i]');
        audioLabel = '[ax$i]';
      }

      accumulated = accumulated + cur.duration - t;
    }

    parts.add('${videoLabel}null[vout]');
    if (withAudio) {
      parts.add('${audioLabel}anull[aout]');
    }

    return parts.join(';');
  }

  /// "None" dibuat sebagai fade yang sangat singkat (praktis potongan langsung).
  static double _transitionDuration(
    TransitionEffect? t,
    double prevDuration,
    double curDuration,
  ) {
    if (t == null || t.type == TransitionType.none) {
      return AppConfig.minTransition;
    }
    final maxAllowed = max(AppConfig.minTransition, min(prevDuration, curDuration) / 2);
    return t.duration.clamp(AppConfig.minTransition, maxAllowed).toDouble();
  }

  static String _s(double value) => value.toStringAsFixed(3);
}
