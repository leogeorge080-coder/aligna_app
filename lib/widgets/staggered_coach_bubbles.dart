import 'package:flutter/material.dart';

import 'coach_bubble.dart';

/// A widget that displays a list of coach bubbles with staggered reveal animation.
/// Each bubble appears with a 250ms delay to create a mysterious opening effect.
class StaggeredCoachBubbles extends StatefulWidget {
  const StaggeredCoachBubbles({super.key, required this.messages});

  final List<String> messages;

  @override
  State<StaggeredCoachBubbles> createState() => _StaggeredCoachBubblesState();
}

class _StaggeredCoachBubblesState extends State<StaggeredCoachBubbles>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.messages.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    }).toList();

    // Stagger the animations
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 250), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(widget.messages.length, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Opacity(
              opacity: _animations[index].value,
              child: Transform.translate(
                offset: Offset(0, (1 - _animations[index].value) * 20),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CoachBubble(text: widget.messages[index]),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
