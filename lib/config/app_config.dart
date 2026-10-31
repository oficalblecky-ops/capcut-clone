class AppConfig {
  static const int exportFps = 30;

  /// Resolusi export: portrait (9:16) atau landscape (16:9), mengikuti klip pertama.
  static const int longSide = 1920;
  static const int shortSide = 1080;

  static const double minClipLength = 0.5;
  static const double minTransition = 0.05;
  static const double defaultTransition = 1.0;

  /// Filter FFmpeg per nama. String kosong = tanpa filter.
  static const Map<String, String> availableFilters = {
    'Normal': '',
    'Bright': 'eq=brightness=0.1:contrast=1.2',
    'Dark': 'eq=brightness=-0.1:contrast=1.2',
    'Grayscale': 'hue=s=0',
    'Sepia':
        'colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131',
  };
}
