import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../models/coach_reply.dart';
import '../providers/app_providers.dart' as app;
import '../theme/aligna_theme.dart';
import '../utils/haptics.dart';
import '../widgets/calm_cue.dart';
import '../widgets/coach_bubble.dart';
import '../widgets/staggered_coach_bubbles.dart';

class ChatArea extends StatelessWidget {
  const ChatArea({
    super.key,
    required this.t,
    required this.controller,
    required this.replyState,
    required this.onSend,
  });

  final dynamic t;
  final TextEditingController controller;
  final AsyncValue<CoachReply?> replyState;
  final void Function(String text) onSend;

  @override
  Widget build(BuildContext context) {
    final hasReply = replyState.maybeWhen(
      data: (r) => r != null,
      orElse: () => false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CoachBubble(text: "What would you like to focus on today?"),
        const SizedBox(height: 12),
        if (!hasReply)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Your intention",
                    style: TextStyle(
                      fontSize: 13,
                      color: AlignaColors.subtext,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Keep it simple. One sentence is enough.",
                      hintStyle: const TextStyle(color: AlignaColors.subtext),
                      filled: true,
                      fillColor: const Color(0xFF0F1530),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AlignaColors.border,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      final text = controller.text.trim();
                      if (text.isEmpty) return;
                      AppHaptics.light();
                      onSend(text);
                    },
                    child: const Text("Continue"),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class MicroActionCard extends StatelessWidget {
  const MicroActionCard({
    super.key,
    required this.text,
    required this.onStart,
    required this.onSkip,
  });

  final String text;
  final VoidCallback onStart;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "One aligned step",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(text),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onStart,
              child: const Text("Let’s do it"),
            ),
            TextButton(onPressed: onSkip, child: const Text("Not today")),
          ],
        ),
      ),
    );
  }
}

class StartedActionBlock extends StatelessWidget {
  const StartedActionBlock({super.key, required this.onEnd});

  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),
        const Text(
          "Good. Just do the first 60 seconds. That counts.",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          "You can stop anytime.",
          style: TextStyle(color: AlignaColors.subtext),
        ),
        const SizedBox(height: 12),
        const CalmCue(visible: true, size: 120, isVeryTired: false),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: onEnd, child: const Text("End session")),
      ],
    );
  }
}

class ExpiredActionBlock extends StatelessWidget {
  const ExpiredActionBlock({super.key, required this.onEnd});

  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        const CoachBubble(text: "That’s enough for today."),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: onEnd, child: const Text("End session")),
      ],
    );
  }
}

class HeartMoodSelector extends StatelessWidget {
  const HeartMoodSelector({super.key, required this.onSelected});

  final void Function(app.HeartMood) onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "How is your heart today?",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => onSelected(app.HeartMood.low),
              child: const Text("Low"),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => onSelected(app.HeartMood.high),
              child: const Text("High"),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({super.key, required this.day});

  final int day;

  @override
  State<VideoPlayerWidget> createState() => VideoPlayerWidgetState();
}

class VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.asset('assets/videos/day${widget.day}.mp4')
          ..initialize().then((_) {
            setState(() {});
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                VideoPlayer(_controller),
                if (!_controller.value.isPlaying)
                  FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        _controller.play();
                      });
                    },
                    child: const Icon(Icons.play_arrow),
                  ),
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
