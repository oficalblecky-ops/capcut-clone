enum TransitionType {
  none,
  fade,
  wipeLeft,
  wipeRight,
  circleOpen,
}

class TransitionEffect {
  final TransitionType type;
  final double duration;

  const TransitionEffect({
    required this.type,
    this.duration = 1.0,
  });

  TransitionEffect copyWith({TransitionType? type, double? duration}) {
    return TransitionEffect(
      type: type ?? this.type,
      duration: duration ?? this.duration,
    );
  }

  /// Nama transisi untuk filter xfade FFmpeg.
  String get xfadeName {
    switch (type) {
      case TransitionType.fade:
        return 'fade';
      case TransitionType.wipeLeft:
        return 'wipeleft';
      case TransitionType.wipeRight:
        return 'wiperight';
      case TransitionType.circleOpen:
        return 'circleopen';
      case TransitionType.none:
        return 'fade';
    }
  }

  static String labelOf(TransitionType type) {
    switch (type) {
      case TransitionType.none:
        return 'None';
      case TransitionType.fade:
        return 'Fade';
      case TransitionType.wipeLeft:
        return 'Wipe Left';
      case TransitionType.wipeRight:
        return 'Wipe Right';
      case TransitionType.circleOpen:
        return 'Circle';
    }
  }
}
