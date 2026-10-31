import 'package:capcut_clone/models/transition_effect.dart';

class VideoClip {
  final String id;
  final String filePath;

  /// Durasi asli file video (detik).
  final double sourceDuration;

  /// Titik trim (detik) di dalam file sumber.
  final double startTime;
  final double endTime;

  final String activeFilter;

  /// Transisi antara klip ini dan klip berikutnya.
  final TransitionEffect? transitionOut;

  const VideoClip({
    required this.id,
    required this.filePath,
    required this.sourceDuration,
    required this.startTime,
    required this.endTime,
    this.activeFilter = 'Normal',
    this.transitionOut,
  });

  double get duration => endTime - startTime;

  VideoClip copyWith({
    double? startTime,
    double? endTime,
    String? activeFilter,
    TransitionEffect? transitionOut,
  }) {
    return VideoClip(
      id: id,
      filePath: filePath,
      sourceDuration: sourceDuration,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      activeFilter: activeFilter ?? this.activeFilter,
      transitionOut: transitionOut ?? this.transitionOut,
    );
  }
}
