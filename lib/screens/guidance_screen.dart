import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/tarot_service.dart';
import '../theme/aligna_theme.dart';

class GuidanceScreen extends ConsumerStatefulWidget {
  const GuidanceScreen({super.key});

  @override
  ConsumerState<GuidanceScreen> createState() => _GuidanceScreenState();
}

class _GuidanceScreenState extends ConsumerState<GuidanceScreen> {
  late Future<TarotCard?> _cardFuture;

  @override
  void initState() {
    super.initState();
    _cardFuture = TarotService.getDailyCard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlignaColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Daily Guidance',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: AlignaColors.text,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tap to reveal today’s card',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AlignaColors.subtext,
                ),
              ),
              const SizedBox(height: 24),
              FutureBuilder<TarotCard?>(
                future: _cardFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: CircularProgressIndicator(),
                    );
                  }

                  final card = snapshot.data;
                  if (card == null || card.imageUrl.isEmpty) {
                    return _EmptyGuidanceCard(
                      title: 'No guidance yet',
                      body:
                          'We could not fetch your card right now. Please check that tarot_cards is populated and try again soon.',
                    );
                  }

                  return Column(
                    children: [
                      _FlipCard(
                        front: _TarotFront(imageUrl: card.imageUrl),
                        back: const _TarotBack(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        card.cardName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          color: AlignaColors.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        card.aiInsight.isNotEmpty
                            ? card.aiInsight
                            : 'Your insight will arrive soon.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          color: AlignaColors.subtext,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyGuidanceCard extends StatelessWidget {
  const _EmptyGuidanceCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AlignaColors.surface),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome, size: 36, color: AlignaColors.accent),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: AlignaColors.text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AlignaColors.subtext,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TarotBack extends StatelessWidget {
  const _TarotBack();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 5,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AlignaColors.accent.withOpacity(0.5)),
        ),
        child: Center(
          child: Text(
            'Guidance',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _TarotFront extends StatelessWidget {
  const _TarotFront({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              color: AlignaColors.surface,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image, size: 40),
            );
          },
        ),
      ),
    );
  }
}

class _FlipCard extends StatefulWidget {
  const _FlipCard({required this.front, required this.back});

  final Widget front;
  final Widget back;

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _showFront = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_controller.isAnimating) return;
    if (_showFront) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    _showFront = !_showFront;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * pi;
          final isFront = angle > pi / 2;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: isFront
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: widget.front,
                  )
                : widget.back,
          );
        },
      ),
    );
  }
}
