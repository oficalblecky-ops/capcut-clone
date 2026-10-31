import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:capcut_clone/models/transition_effect.dart';
import 'package:capcut_clone/providers/editor_provider.dart';

/// Timeline horizontal: kartu klip + penanda transisi di antaranya.
/// Ketuk kartu untuk memilih klip yang akan diedit.
class TimelineWidget extends StatelessWidget {
  const TimelineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (context, provider, child) {
        final clips = provider.timeline;

        if (clips.isEmpty) {
          return Container(
            height: 110,
            color: const Color(0xFF1A1A1A),
            alignment: Alignment.center,
            child: const Text(
              'Timeline kosong',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final items = <Widget>[];
        for (var i = 0; i < clips.length; i++) {
          final clip = clips[i];
          final selected = i == provider.selectedIndex;

          items.add(
            GestureDetector(
              onTap: () => provider.selectClip(i),
              child: Container(
                width: 130,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? Colors.blueAccent : Colors.grey.shade700,
                    width: selected ? 3 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Klip ${i + 1}\n'
                    '${clip.duration.toStringAsFixed(1)} s\n'
                    '${clip.activeFilter}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );

          if (i < clips.length - 1) {
            final type = clip.transitionOut?.type ?? TransitionType.none;
            items.add(
              SizedBox(
                width: 56,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.swap_horiz, color: Colors.white54, size: 20),
                    Text(
                      TransitionEffect.labelOf(type),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54, fontSize: 9),
                    ),
                  ],
                ),
              ),
            );
          }
        }

        return Container(
          height: 110,
          color: const Color(0xFF1A1A1A),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: items,
          ),
        );
      },
    );
  }
}
