import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:capcut_clone/config/app_config.dart';
import 'package:capcut_clone/models/transition_effect.dart';
import 'package:capcut_clone/providers/editor_provider.dart';
import 'package:capcut_clone/widgets/timeline_widget.dart';
import 'package:capcut_clone/widgets/video_preview.dart';

class EditorScreen extends StatefulWidget {
  final String initialVideoPath;

  const EditorScreen({super.key, required this.initialVideoPath});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final EditorProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<EditorProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _provider.reset();
      final error = await _provider.addVideo(widget.initialVideoPath);
      if (error != null) _showMessage(error);
    });
  }

  @override
  void dispose() {
    final provider = _provider;
    Future.microtask(provider.reset);
    super.dispose();
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 6)),
    );
  }

  Future<void> _exportVideo() async {
    final message = await _provider.exportToGallery();
    _showMessage(message);
  }

  Future<void> _addClip() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    final error = await _provider.addVideo(picked.path);
    if (error != null) _showMessage(error);
  }

  void _showSheet(Widget Function(BuildContext context, EditorProvider p) body) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (sheetContext) {
        return Consumer<EditorProvider>(
          builder: (context, p, child) => body(context, p),
        );
      },
    );
  }

  void _showTrimSheet() {
    if (_provider.selectedClip == null) return;
    _showSheet((context, p) {
      final clip = p.selectedClip;
      if (clip == null) return const SizedBox(height: 120);
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Trim klip ${p.selectedIndex + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            RangeSlider(
              min: 0,
              max: clip.sourceDuration,
              values: RangeValues(clip.startTime, clip.endTime),
              onChanged: (v) => p.updateClipTrim(v.start, v.end),
            ),
            Text(
              'Mulai ${clip.startTime.toStringAsFixed(1)} s   '
              'Selesai ${clip.endTime.toStringAsFixed(1)} s   '
              'Durasi ${clip.duration.toStringAsFixed(1)} s',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    });
  }

  void _showFilterSheet() {
    if (_provider.selectedClip == null) return;
    _showSheet((context, p) {
      return SizedBox(
        height: 140,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          children: AppConfig.availableFilters.keys.map((name) {
            final active = p.selectedClip?.activeFilter == name;
            return GestureDetector(
              onTap: () => p.updateClipFilter(name),
              child: Container(
                width: 100,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: active ? Colors.blueAccent : Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  void _showTransitionSheet() {
    if (_provider.selectedClip == null) return;
    _showSheet((context, p) {
      final isLast = p.selectedIndex >= p.timeline.length - 1;
      if (isLast) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Transisi dipasang di antara klip ini dan klip berikutnya.\n'
            'Tambahkan klip lagi (tombol + Klip), lalu pilih klip yang bukan terakhir.',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      final current = p.selectedClip?.transitionOut ??
          const TransitionEffect(
            type: TransitionType.none,
            duration: AppConfig.defaultTransition,
          );

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: TransitionType.values.map((type) {
                  final active = current.type == type;
                  return GestureDetector(
                    onTap: () => p.updateClipTransition(current.copyWith(type: type)),
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: active ? Colors.blueAccent : Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          TransitionEffect.labelOf(type),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Row(
              children: [
                const Text('Durasi', style: TextStyle(color: Colors.white70)),
                Expanded(
                  child: Slider(
                    min: 0.3,
                    max: 2.0,
                    value: current.duration.clamp(0.3, 2.0).toDouble(),
                    onChanged: current.type == TransitionType.none
                        ? null
                        : (v) => p.updateClipTransition(current.copyWith(duration: v)),
                  ),
                ),
                Text(
                  '${current.duration.toStringAsFixed(1)} s',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Editor', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<EditorProvider>(
            builder: (context, p, child) {
              if (p.isProcessing) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              return IconButton(
                tooltip: 'Export ke galeri',
                icon: const Icon(Icons.file_download, color: Colors.white),
                onPressed: p.timeline.isEmpty ? null : _exportVideo,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(child: VideoPreview()),
            Consumer<EditorProvider>(
              builder: (context, p, child) {
                if (!p.isProcessing) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  color: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Text(
                    p.statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
            const TimelineWidget(),
            Container(
              height: 72,
              color: const Color(0xFF111111),
              child: Row(
                children: [
                  _BottomTool(icon: Icons.add_circle_outline, label: '+ Klip', onTap: _addClip),
                  _BottomTool(icon: Icons.content_cut, label: 'Trim', onTap: _showTrimSheet),
                  _BottomTool(icon: Icons.filter, label: 'Filter', onTap: _showFilterSheet),
                  _BottomTool(icon: Icons.swap_horiz, label: 'Transisi', onTap: _showTransitionSheet),
                  _BottomTool(
                    icon: Icons.delete_outline,
                    label: 'Hapus',
                    onTap: () => _provider.removeSelected(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomTool extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomTool({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
