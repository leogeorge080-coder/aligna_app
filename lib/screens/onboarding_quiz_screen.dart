import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aligna_app/theme/aligna_theme.dart';
import 'package:aligna_app/utils/haptics.dart';
import 'package:aligna_app/persistence/prefs.dart';
import 'package:aligna_app/providers/app_providers.dart' as app;
import 'package:aligna_app/services/program_service.dart';
import 'package:aligna_app/models/program_type.dart';
import 'package:aligna_app/widgets/aura_orb.dart';
import 'package:aligna_app/widgets/lumi_glow_orb.dart';
import 'package:aligna_app/screens/app_shell.dart';

class OnboardingQuizScreen extends ConsumerStatefulWidget {
  const OnboardingQuizScreen({super.key});

  @override
  ConsumerState<OnboardingQuizScreen> createState() =>
      _OnboardingQuizScreenState();
}

class _OnboardingQuizScreenState extends ConsumerState<OnboardingQuizScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  final Map<String, String> _answers = {};
  String? _selectedOption;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What are you calling in?',
      'options': [
        {'text': 'Abundance', 'programType': ProgramType.money},
        {'text': 'Inner Peace', 'programType': ProgramType.health},
        {'text': 'Career Growth', 'programType': ProgramType.purpose},
        {'text': 'Love', 'programType': ProgramType.love},
      ],
    },
    {
      'question': 'How does your mind feel today?',
      'options': [
        {
          'text': 'Overwhelmed/Busy',
          'glowType': 'fast_jagged',
          'color': const Color(0xFF87CEEB), // Soft blue
          'startingState': 'overwhelmed',
        },
        {
          'text': 'Stuck/Stagnant',
          'glowType': 'slow_dimming',
          'color': const Color(0xFF808080), // Grey-ish
          'startingState': 'stuck',
        },
        {
          'text': 'Ready for Change',
          'glowType': 'bright_expansive',
          'color': const Color(0xFFFFD700), // Gold
          'startingState': 'ready',
        },
      ],
    },
    {
      'question': 'How much time do you have for yourself?',
      'options': [
        {
          'text': '5 mins (Quick Reset)',
          'glowType': 'light_fast_pulsing',
          'color': const Color(0xFF98FB98), // Mint
          'timePreference': '5min',
        },
        {
          'text': '15 mins (Deep Work)',
          'glowType': 'slow_deep_breathing',
          'color': const Color(0xFF4B0082), // Deep Indigo
          'timePreference': '15min',
        },
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _progressAnimationController.value = (_currentStep + 1) / _questions.length;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _selectOption(String question, String answer) {
    // Special "heartbeat" haptic for intention selection (first question)
    if (question == 'What are you calling in?') {
      // Create a heartbeat-like haptic pattern
      AppHaptics.light();
      Future.delayed(const Duration(milliseconds: 150), () {
        AppHaptics.light();
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        AppHaptics.success();
      });
    } else if (answer == 'Ready for Change') {
      AppHaptics.success();
    } else {
      AppHaptics.light();
    }

    setState(() {
      _answers[question] = answer;
      _selectedOption = answer;
      if (_currentStep < _questions.length - 1) {
        _currentStep++;
        _selectedOption = null; // Reset for next question
        // Animate progress bar
        final newProgress = (_currentStep + 1) / _questions.length;
        _progressAnimation =
            Tween<double>(
              begin: _progressAnimation.value,
              end: newProgress,
            ).animate(
              CurvedAnimation(
                parent: _progressAnimationController,
                curve: Curves.easeInOut,
              ),
            );
        _progressAnimationController.forward(from: 0.0);
      } else {
        // Special transition for "Ready for Change" - deep breath effect
        if (answer == 'Ready for Change') {
          _performDeepBreathTransition();
        } else {
          _completeOnboarding();
        }
      }
    });
  }

  void _performDeepBreathTransition() async {
    // Fade out with deep breath timing
    await _fadeController.forward();

    // Small pause for the "breath"
    await Future.delayed(const Duration(milliseconds: 200));

    // Complete onboarding
    _completeOnboarding();
  }

  void _completeOnboarding() async {
    final programSlug = _determineProgramId();
    final focus = _answers[_questions[0]['question']];

    // Save program type based on selection
    ProgramType? programType;
    if (focus == 'Abundance') {
      programType = ProgramType.money;
    } else if (focus == 'Inner Peace') {
      programType = ProgramType.health;
    } else if (focus == 'Career Growth') {
      programType = ProgramType.purpose;
    } else if (focus == 'Love') {
      programType = ProgramType.love;
    }

    // Save starting state based on mindset selection
    final mindset = _answers[_questions[1]['question']];
    String? startingState;
    if (mindset == 'Overwhelmed/Busy') {
      startingState = 'overwhelmed';
    } else if (mindset == 'Stuck/Stagnant') {
      startingState = 'stuck';
    } else if (mindset == 'Ready for Change') {
      startingState = 'ready';
    }

    if (startingState != null) {
      ref.read(app.startingStateProvider.notifier).state = startingState;
    }

    // Fetch the UUID from the programs table
    final programId = await ProgramService.getProgramIdBySlug(programSlug);

    String? resolvedProgramId = programId;
    if (resolvedProgramId == null) {
      final programs = await ProgramService.getAllPrograms();
      if (programs.isNotEmpty) {
        resolvedProgramId = programs.first.id;
      }
    }

    if (resolvedProgramId == null) {
      debugPrint(
        'Warning: Could not resolve program UUID for slug $programSlug, leaving active program unset',
      );
      await Prefs.clearActiveProgramId();
      ref.read(app.activeProgramIdProvider.notifier).state = null;
    } else {
      final nextId = resolvedProgramId;
      await Prefs.saveActiveProgramId(nextId);
      ref.read(app.activeProgramIdProvider.notifier).state = nextId;
    }
        // Update providers
    ref.read(app.onboardingCompletedProvider.notifier).state = true;

    // Save time preference
    final timePreference = _answers[_questions[2]['question']];
    if (timePreference != null) {
      await Prefs.saveTimePreference(
        timePreference == '5 mins (Quick Reset)' ? 5 : 15,
      );
      ref.read(app.timePreferenceProvider.notifier).state =
          timePreference == '5 mins (Quick Reset)' ? 5 : 15;
    }

    // Navigate to home with circular reveal
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AppShell(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final center = Offset(
              MediaQuery.of(context).size.width / 2,
              MediaQuery.of(context).size.height / 2,
            );
            final radius = MediaQuery.of(context).size.longestSide * 1.5;

            return ClipPath(
              clipper: CircularRevealClipper(
                fraction: animation.value,
                center: center,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  String _determineProgramId() {
    final focus = _answers[_questions[0]['question']];
    final state = _answers[_questions[1]['question']];
    final time = _answers[_questions[2]['question']];

    // Logic to determine program based on answers
    if (focus == 'Abundance') {
      return time == '5 mins (Quick Reset)'
          ? 'money_safety_7d'
          : 'wealth_identity_30d';
    } else if (focus == 'Inner Peace') {
      return state == 'Overwhelmed/Busy'
          ? 'nervous_system_14d'
          : 'outcome_soothing_7d';
    } else if (focus == 'Career Growth') {
      return 'purpose_reset_14d';
    } else if (focus == 'Love') {
      return 'love_readiness_21d';
    }

    // Default fallback
    return 'nervous_system_14d';
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentStep];

    return Scaffold(
      backgroundColor: AlignaColors.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Progress indicator
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: AlignaColors.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AlignaColors.radiantGold,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Question
                Text(
                  currentQuestion['question'],
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AlignaColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Options
                Expanded(
                  child: ListView.builder(
                    itemCount: currentQuestion['options'].length,
                    itemBuilder: (context, index) {
                      final option = currentQuestion['options'][index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: EnergyCard(
                          text: option['text'],
                          programType: option['programType'],
                          glowType: option['glowType'],
                          color: option['color'],
                          isSelected: _selectedOption == option['text'],
                          onTap: () => _selectOption(
                            currentQuestion['question'],
                            option['text'],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Step indicator
                Text(
                  '${_currentStep + 1} of ${_questions.length}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AlignaColors.subtext),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EnergyCard extends StatefulWidget {
  final String text;
  final ProgramType? programType;
  final String? glowType;
  final Color? color;
  final VoidCallback onTap;
  final bool isSelected;

  const EnergyCard({
    super.key,
    required this.text,
    this.programType,
    this.glowType,
    this.color,
    required this.onTap,
    this.isSelected = false,
  }) : assert(
         programType != null || (glowType != null && color != null),
         'Either programType or both glowType and color must be provided',
       );

  @override
  State<EnergyCard> createState() => _EnergyCardState();
}

class _EnergyCardState extends State<EnergyCard> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        widget.programType?.auraColors ?? [widget.color!, widget.color!];
    final primaryColor = widget.programType != null ? colors[0] : widget.color!;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                border: Border.all(
                  color: widget.isSelected
                      ? primaryColor.withValues(alpha: 0.8)
                      : primaryColor.withValues(alpha: 0.3),
                  width: widget.isSelected ? 3 : 2,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(
                      alpha: widget.isSelected ? 0.4 : 0.2,
                    ),
                    blurRadius: widget.isSelected ? 16 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  widget.programType != null
                      ? AuraOrb(colors: colors, size: 32)
                      : LumiGlowOrb(
                          glowType: widget.glowType!,
                          color: widget.color!,
                          size: 32,
                        ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.text,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AlignaColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Offset center;

  CircularRevealClipper({required this.fraction, required this.center});

  @override
  Path getClip(Size size) {
    final path = Path();
    final radius = fraction * size.longestSide * 1.5;
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    return path;
  }

  @override
  bool shouldReclip(CircularRevealClipper oldClipper) {
    return oldClipper.fraction != fraction;
  }
}


