import 'package:flutter/material.dart';
import 'package:aligna_app/theme/aligna_theme.dart';
import 'package:vibration/vibration.dart';
import 'dart:math' as math;

enum CelebrationStep { ascension, coachSeal, reward }

class CelebrationScreen extends StatefulWidget {
  final String journalText;
  final int dayNumber;

  const CelebrationScreen({
    super.key,
    required this.journalText,
    required this.dayNumber,
  });

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen>
    with TickerProviderStateMixin {
  CelebrationStep _currentStep = CelebrationStep.ascension;

  // Ascension animations
  late AnimationController _ascensionController;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textFloatAnimation;
  late Animation<double> _starsFadeAnimation;

  // Coach seal animations
  late AnimationController _coachController;
  late Animation<double> _coachFadeAnimation;

  // Reward animations
  late AnimationController _rewardController;
  late Animation<double> _rewardSlideAnimation;

  // Star positions for ascension effect
  final List<StarParticle> _stars = [];

  @override
  void initState() {
    super.initState();

    // Generate random stars
    for (int i = 0; i < 20; i++) {
      _stars.add(StarParticle.random());
    }

    // Ascension animations
    _ascensionController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _textFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ascensionController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _textFloatAnimation = Tween<double>(begin: 0.0, end: -100.0).animate(
      CurvedAnimation(
        parent: _ascensionController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _starsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ascensionController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    // Coach seal animations
    _coachController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _coachFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _coachController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Reward animations
    _rewardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _rewardSlideAnimation = Tween<double>(begin: 300.0, end: 0.0).animate(
      CurvedAnimation(parent: _rewardController, curve: Curves.elasticOut),
    );

    // Start the sequence
    _startCelebrationSequence();
  }

  void _startCelebrationSequence() async {
    // Step 1: Ascension (3 seconds)
    _ascensionController.forward();

    // Add vibration/sound effect when stars appear
    await Future.delayed(const Duration(seconds: 1));
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 200);
    }

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _currentStep = CelebrationStep.coachSeal);
      _coachController.forward();
    }

    // Step 2: Coach Seal (8 seconds)
    await Future.delayed(const Duration(seconds: 8));

    if (mounted) {
      setState(() => _currentStep = CelebrationStep.reward);
      _rewardController.forward();
    }
  }

  String _getBlessingText() {
    final blessings = [
      "Your frequency is set. Day ${widget.dayNumber} is sealed.",
      "I've received your intention. The universe is already responding.",
      "Your energy is aligned. The path unfolds before you.",
      "Your words carry power. The cosmos hears you.",
      "Your intention is planted. Watch it grow.",
    ];
    return blessings[widget.dayNumber % blessings.length];
  }

  @override
  void dispose() {
    _ascensionController.dispose();
    _coachController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AlignaColors.bg,
      body: GestureDetector(
        onTap: _currentStep == CelebrationStep.reward
            ? () => Navigator.of(context).pop()
            : null,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AlignaColors.radiantGold.withOpacity(0.3),
                AlignaColors.softPurple.withOpacity(0.3),
                AlignaColors.etherealMint.withOpacity(0.3),
              ],
            ),
          ),
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case CelebrationStep.ascension:
        return _buildAscensionStep();
      case CelebrationStep.coachSeal:
        return _buildCoachSealStep();
      case CelebrationStep.reward:
        return _buildRewardStep();
    }
  }

  Widget _buildAscensionStep() {
    return AnimatedBuilder(
      animation: Listenable.merge([_ascensionController]),
      builder: (context, child) {
        return Stack(
          children: [
            // Floating journal text
            Positioned(
              left: 40,
              right: 40,
              top:
                  MediaQuery.of(context).size.height * 0.4 +
                  _textFloatAnimation.value,
              child: Opacity(
                opacity: _textFadeAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AlignaColors.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AlignaColors.radiantGold.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.journalText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AlignaColors.text,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            // Glowing stars
            ..._stars.map(
              (star) => Positioned(
                left: star.x,
                top: star.y + (_starsFadeAnimation.value * -200),
                child: Opacity(
                  opacity: _starsFadeAnimation.value * star.opacity,
                  child: Icon(
                    Icons.star,
                    color: AlignaColors.radiantGold,
                    size: star.size,
                  ),
                ),
              ),
            ),

            // Ascension hint
            Positioned(
              bottom: 100,
              left: 40,
              right: 40,
              child: Opacity(
                opacity: _starsFadeAnimation.value,
                child: Text(
                  'Releasing your intention into the universe...',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AlignaColors.subtext),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCoachSealStep() {
    return AnimatedBuilder(
      animation: _coachController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _coachFadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Coach avatar (placeholder - would be actual coach animation)
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AlignaColors.etherealMint,
                      AlignaColors.softPurple,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AlignaColors.radiantGold.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.face, color: Colors.white, size: 80),
              ),

              const SizedBox(height: 40),

              // Blessing text
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: AlignaColors.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AlignaColors.radiantGold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getBlessingText(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AlignaColors.text,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 40),

              // Sealing animation
              Container(
                width: 100,
                height: 4,
                decoration: BoxDecoration(
                  color: AlignaColors.surface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (_coachController.value - 0.3).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AlignaColors.radiantGold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRewardStep() {
    return AnimatedBuilder(
      animation: _rewardController,
      builder: (context, child) {
        return Stack(
          children: [
            // Background celebration
            const Center(
              child: Icon(
                Icons.celebration,
                color: AlignaColors.radiantGold,
                size: 120,
              ),
            ),

            // Reward card
            Positioned(
              left: 40,
              right: 40,
              bottom: 100 + _rewardSlideAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AlignaColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AlignaColors.radiantGold.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AlignaColors.radiantGold.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Streak
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${widget.dayNumber} Days Aligned',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AlignaColors.text,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 8),
                        const Text('🔥', style: TextStyle(fontSize: 24)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Energy level
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AlignaColors.radiantGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AlignaColors.radiantGold.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Current Frequency: High',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AlignaColors.radiantGold,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Return button
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AlignaColors.radiantGold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text('Return to Sanctuary'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class StarParticle {
  final double x;
  final double y;
  final double size;
  final double opacity;

  StarParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
  });

  factory StarParticle.random() {
    final random = math.Random();
    return StarParticle(
      x: random.nextDouble() * 400, // Screen width approximation
      y: random.nextDouble() * 800 + 200, // Start below center
      size: random.nextDouble() * 20 + 10,
      opacity: random.nextDouble() * 0.8 + 0.2,
    );
  }
}
