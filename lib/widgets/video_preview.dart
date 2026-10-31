import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'package:capcut_clone/providers/editor_provider.dart';

/// Preview video. Filter warna ditampilkan sebagai pendekatan visual saja;
/// hasil export memakai filter FFmpeg yang sebenarnya.
class VideoPreview extends StatelessWidget {
  const VideoPreview({super.key});

  static const Map<String, List<double>> _previewMatrices = {
    'Grayscale': [
      0.2126, 0.7152, 0.0722, 0, 0, //
      0.2126, 0.7152, 0.0722, 0, 0, //
      0.2126, 0.7152, 0.0722, 0, 0, //
      0, 0, 0, 1, 0,
    ],
    'Sepia': [
      0.393, 0.769, 0.189, 0, 0, //
      0.349, 0.686, 0.168, 0, 0, //
      0.272, 0.534, 0.131, 0, 0, //
      0, 0, 0, 1, 0,
    ],
    'Bright': [
      1.2, 0, 0, 0, 25, //
      0, 1.2, 0, 0, 25, //
      0, 0, 1.2, 0, 25, //
      0, 0, 0, 1, 0,
    ],
    'Dark': [
      1.2, 0, 0, 0, -25, //
      0, 1.2, 0, 0, -25, //
      0, 0, 1.2, 0, -25, //
      0, 0, 0, 1, 0,
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (context, provider, child) {
        final VideoPlayerController? controller = provider.controller;

        if (provider.timeline.isEmpty) {
          return const Center(
            child: Text('Belum ada video', style: TextStyle(color: Colors.grey)),
          );
        }

        if (controller == null || !controller.value.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        Widget video = AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        );

        final matrix = _previewMatrices[provider.selectedClip?.activeFilter];
        if (matrix != null) {
          video = ColorFiltered(
            colorFilter: ColorFilter.matrix(matrix),
            child: video,
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: provider.togglePlayPause,
          child: Container(
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(child: video),
                if (!controller.value.isPlaying)
                  const Icon(
                    Icons.play_circle_fill,
                    size: 64,
                    color: Colors.white70,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
