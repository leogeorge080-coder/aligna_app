import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../providers/program_providers.dart';
import '../models/program_type.dart';

// Universe theme data for each program type
class UniverseTheme {
  final Color deepSpaceColor;
  final List<Color> nebulaColors;
  final List<Color> starColors;
  final Color rippleColor;
  final String name;

  const UniverseTheme({
    required this.deepSpaceColor,
    required this.nebulaColors,
    required this.starColors,
    required this.rippleColor,
    required this.name,
  });
}

// Universe themes mapping
final Map<ProgramType, UniverseTheme> universeThemes = {
  ProgramType.money: const UniverseTheme(
    // Abundance - Solar Flare
    deepSpaceColor: Color(0xFF0A0E21), // Deep black
    nebulaColors: [
      Color(0xFFFFD700),
      Color(0xFFFFFAF0),
      Color(0xFFFF8C00),
    ], // Gold, white-hot, orange
    starColors: [Color(0xFFFFD700), Color(0xFFFFFAF0)], // Gold and white
    rippleColor: Color(0xFFFFD700), // Gold ripples
    name: 'Solar Flare',
  ),
  ProgramType.health: const UniverseTheme(
    // Inner Peace - Andromeda Nebula
    deepSpaceColor: Color(0xFF0A0E21),
    nebulaColors: [
      Color(0xFF008080),
      Color(0xFF98FB98),
      Color(0xFF20B2AA),
    ], // Teal, mint green, light sea green
    starColors: [Color(0xFFE6F3FF), Color(0xFFB3D9FF)], // Soft blue-white stars
    rippleColor: Color(0xFF98FB98), // Mint green ripples
    name: 'Andromeda Nebula',
  ),
  ProgramType.love: const UniverseTheme(
    // Love - Rose Supernova
    deepSpaceColor: Color(0xFF1A0033), // Deep violet-black
    nebulaColors: [
      Color(0xFF8B008B),
      Color(0xFFFFB6C1),
      Color(0xFFE6E6FA),
    ], // Deep magenta, rose, lavender
    starColors: [Color(0xFFFFB6C1), Color(0xFFFFE4E1)], // Rose and misty rose
    rippleColor: Color(0xFFFFB6C1), // Rose ripples
    name: 'Rose Supernova',
  ),
  ProgramType.purpose: const UniverseTheme(
    // Healing - Deep Indigo Void
    deepSpaceColor: Color(0xFF0F0F23), // Deep indigo-black
    nebulaColors: [
      Color(0xFF191970),
      Color(0xFF4169E1),
      Color(0xFF00BFFF),
    ], // Midnight blue, royal blue, electric blue
    starColors: [Color(0xFFE6E6FA), Color(0xFFDDA0DD)], // Lavender and plum
    rippleColor: Color(0xFF4169E1), // Royal blue ripples
    name: 'Deep Indigo Void',
  ),
  ProgramType.identity: const UniverseTheme(
    // Identity - Cosmic Aurora
    deepSpaceColor: Color(0xFF0A0E21),
    nebulaColors: [
      Color(0xFFFF1493),
      Color(0xFFFF69B4),
      Color(0xFF9370DB),
    ], // Deep pink, hot pink, medium purple
    starColors: [
      Color(0xFFFFE4E1),
      Color(0xFFFFB6C1),
    ], // Misty rose, light pink
    rippleColor: Color(0xFFFF1493), // Deep pink ripples
    name: 'Cosmic Aurora',
  ),
  ProgramType.support: const UniverseTheme(
    // Support - Tranquil Cosmos
    deepSpaceColor: Color(0xFF0A0E21),
    nebulaColors: [
      Color(0xFF87CEEB),
      Color(0xFF4682B4),
      Color(0xFFB0E0E6),
    ], // Sky blue, steel blue, powder blue
    starColors: [
      Color(0xFFE6F3FF),
      Color(0xFFF0F8FF),
    ], // Light blue white, alice blue
    rippleColor: Color(0xFF87CEEB), // Sky blue ripples
    name: 'Tranquil Cosmos',
  ),
};

// Particle classes for starfield and ripples
class StarParticle {
  Offset position;
  double size;
  double twinklePhase;
  double driftSpeed;
  Color color;

  StarParticle({
    required this.position,
    required this.size,
    required this.color,
  }) : twinklePhase = Random().nextDouble() * 2 * pi,
       driftSpeed = Random().nextDouble() * 0.5 + 0.1;
}

class RippleEffect {
  Offset center;
  double radius;
  double maxRadius;
  double opacity;
  Color color;
  DateTime startTime;

  RippleEffect({
    required this.center,
    required this.maxRadius,
    required this.color,
  }) : radius = 0.0,
       opacity = 1.0,
       startTime = DateTime.now();
}

class ReactiveAuraWidget extends ConsumerStatefulWidget {
  final String lumiImageUrl;
  final String? audioUrl;
  final String? programId;
  final ProgramType? programType; // For backward compatibility
  final double restIntensity;
  final List<String>? mentorMessages;

  const ReactiveAuraWidget({
    super.key,
    required this.lumiImageUrl,
    this.audioUrl,
    this.programId,
    this.programType, // For backward compatibility
    this.restIntensity = 0.1,
    this.mentorMessages,
  }) : assert(
         programId != null || programType != null,
         'Either programId or programType must be provided',
       );

  @override
  ConsumerState<ReactiveAuraWidget> createState() => _ReactiveAuraWidgetState();
}

class _ReactiveAuraWidgetState extends ConsumerState<ReactiveAuraWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AudioPlayer _audioPlayer;
  double _currentVolume = 0.0;
  bool _isPlaying = false;

  // Mentor message state
  int _currentMessageIndex = 0;
  double _messageOpacity = 0.0;
  Timer? _messageTimer;

  // Universe theme state
  late AnimationController _nebulaController;
  late AnimationController _rippleController;
  List<StarParticle> _starParticles = [];
  final List<RippleEffect> _activeRipples = [];
  Offset _gyroscopeOffset = Offset.zero;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  // Audio frequency detection for ripples
  double _lastVolume = 0.0;
  int _volumeSpikeCount = 0;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for swirling effect
    _animationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    // Initialize nebula rotation controller
    _nebulaController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Initialize ripple controller
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Initialize starfield particles
    _initializeStarfield();

    // Initialize gyroscope for tilt interaction
    _initializeGyroscope();

    // Initialize audio player
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();

    // DO NOT auto-play audio - let parent widget control playback
    // if (widget.audioUrl != null) {
    //   _playAudio();
    // }
  }

  Future<void> _setupAudioPlayer() async {
    // Configure audio context to override silent mode and play through speaker
    final audioContext = AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        audioMode: AndroidAudioMode.normal,
        audioFocus: AndroidAudioFocus.gain,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {
          AVAudioSessionOptions.mixWithOthers,
          AVAudioSessionOptions.duckOthers,
        },
      ),
    );
    await _audioPlayer.setAudioContext(audioContext);

    // Listen to player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      final wasPlaying = _isPlaying;
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });

      // Start/stop message cycling based on play state
      if (_isPlaying && !wasPlaying) {
        _startMessageCycling();
      } else if (!_isPlaying && wasPlaying) {
        _stopMessageCycling();
      }
    });

    // Listen to volume changes for ripple detection
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _detectVolumeSpike();
    });

    // Enhanced volume reactivity for breathing effect - sync with voice
    _audioPlayer.onPositionChanged.listen((position) {
      if (_isPlaying) {
        // Create voice-reactive breathing pattern that syncs with audio pacing
        final timeMs = position.inMilliseconds;

        // Primary breathing cycle (slower, deeper breathing)
        final primaryBreath = sin(timeMs * 0.003) * 0.25 + 0.75;

        // Secondary rhythm (faster, shallower breathing - like speech patterns)
        final speechRhythm = sin(timeMs * 0.008) * 0.15;

        // Micro variations (very fast, subtle movements)
        final microVariations = sin(timeMs * 0.04) * 0.05;

        // Add some natural randomness to make it feel more alive
        final naturalVariation = sin(timeMs * 0.001) * 0.02;

        // Combine all elements for a natural, voice-reactive breathing effect
        final voiceReactiveVolume =
            (primaryBreath + speechRhythm + microVariations + naturalVariation)
                .clamp(0.15, 1.0);

        setState(() {
          _currentVolume = voiceReactiveVolume;
        });
      } else {
        // Smooth transition to rest intensity when not playing
        setState(() {
          _currentVolume = widget.restIntensity;
        });
      }
    });
  }

  Future<void> _playAudio() async {
    if (widget.audioUrl != null) {
      // Properly set source URL and await before playing
      await _audioPlayer.setSourceUrl(widget.audioUrl!);

      // Start with volume at 0 for fade-in effect
      await _audioPlayer.setVolume(0.0);

      // Add haptic feedback the exact millisecond audio starts
      HapticFeedback.mediumImpact();

      // Start playing
      await _audioPlayer.resume();

      // Soft fade-in over 2 seconds
      const fadeDuration = Duration(seconds: 2);
      const steps = 20;
      final stepDuration = fadeDuration.inMilliseconds ~/ steps;

      for (int i = 1; i <= steps; i++) {
        await Future.delayed(Duration(milliseconds: stepDuration));
        final volume = (i / steps).clamp(0.0, 1.0);
        await _audioPlayer.setVolume(volume);
      }
    }
  }

  void _startMessageCycling() {
    final messages = widget.mentorMessages ?? _getDefaultMentorMessages();
    if (messages.isEmpty) return;

    _messageTimer?.cancel();
    _currentMessageIndex = 0;
    _messageOpacity = 1.0;

    // Show first message immediately
    setState(() {});

    // Cycle through messages every 8 seconds
    _messageTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }

      setState(() {
        _messageOpacity = 0.0; // Start fade out
      });

      // After fade out, switch to next message and fade in
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _isPlaying) {
          _currentMessageIndex = (_currentMessageIndex + 1) % messages.length;
          setState(() {
            _messageOpacity = 1.0; // Fade in
          });
        }
      });
    });
  }

  void _stopMessageCycling() {
    _messageTimer?.cancel();
    setState(() {
      _messageOpacity = 0.0;
    });
  }

  List<String> _getDefaultMentorMessages() {
    // Default coaching messages based on program type
    final programType = widget.programType ?? ProgramType.support;
    switch (programType) {
      case ProgramType.money:
        return [
          "Your financial journey begins with a single mindful step.",
          "Breathe deeply and visualize abundance flowing to you.",
          "Trust in your ability to create the wealth you deserve.",
          "Each breath brings clarity to your financial goals.",
        ];
      case ProgramType.love:
        return [
          "Love starts with loving yourself first.",
          "Open your heart to receive the love that surrounds you.",
          "You are worthy of deep, meaningful connections.",
          "Let compassion guide your relationships.",
        ];
      case ProgramType.health:
        return [
          "Your body is your temple - treat it with care.",
          "Listen to what your body needs right now.",
          "Healing begins with acceptance and self-love.",
          "Nourish yourself with each conscious breath.",
        ];
      case ProgramType.purpose:
        return [
          "Your purpose is unfolding with each moment.",
          "Trust the journey you're on.",
          "You have unique gifts to share with the world.",
          "Follow what lights you up inside.",
        ];
      case ProgramType.identity:
        return [
          "You are becoming who you were always meant to be.",
          "Embrace all aspects of yourself with love.",
          "Your authentic self is your greatest strength.",
          "Growth happens in the space of self-acceptance.",
        ];
      case ProgramType.support:
      default:
        return [
          "You are not alone in this journey.",
          "Take one gentle step at a time.",
          "Your feelings are valid and important.",
          "Breathe through the challenges - you are resilient.",
        ];
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nebulaController.dispose();
    _rippleController.dispose();
    _gyroscopeSubscription?.cancel();
    _audioPlayer.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use programId if provided, otherwise try to map programType to a default
    final effectiveProgramId =
        widget.programId ?? _getDefaultProgramIdForType(widget.programType);
    final auraColorsAsync = ref.watch(
      programAuraColorsProvider(effectiveProgramId),
    );

    final programType = widget.programType ?? ProgramType.support;
    final universeTheme = universeThemes[programType]!;

    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Layer 1: Deep Space Base - Very dark radial gradient background
          Container(
            height: 500,
            width: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment.center,
                colors: [
                  universeTheme.nebulaColors[0].withOpacity(0.1),
                  universeTheme.deepSpaceColor,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),

          // Layer 2: Starfield Particles - Twinkling white dust particles
          CustomPaint(
            painter: StarfieldPainter(
              particles: _starParticles,
              gyroscopeOffset: _gyroscopeOffset,
              animationValue: _animationController.value,
            ),
            child: const SizedBox(height: 500, width: 500),
          ),

          // Layer 3: Pulsing Nebula - Rotating conic gradient that scales with audio volume
          AnimatedBuilder(
            animation: _nebulaController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _nebulaController.value * 2 * pi,
                child: CustomPaint(
                  painter: NebulaPainter(
                    colors: universeTheme.nebulaColors,
                    volume: _currentVolume,
                    animationValue: _nebulaController.value,
                  ),
                  child: const SizedBox(height: 500, width: 500),
                ),
              );
            },
          ),

          // Layer 4: Frequency Ripples - Ripple effects triggered by volume spikes
          CustomPaint(
            painter: RipplePainter(ripples: _activeRipples),
            child: const SizedBox(height: 500, width: 500),
          ),

          // Legacy Aura Painter (kept for compatibility but layered under new effects)
          auraColorsAsync.when(
            data: (colors) => CustomPaint(
              painter: AuraPainter(
                animationValue: _animationController.value,
                volume: _currentVolume,
                auraColors: colors ?? [Colors.transparent, Colors.transparent],
              ),
              child: const SizedBox(height: 500, width: 500),
            ),
            loading: () => CustomPaint(
              painter: AuraPainter(
                animationValue: _animationController.value,
                volume: _currentVolume,
                auraColors: [Colors.transparent, Colors.transparent],
              ),
              child: const SizedBox(height: 500, width: 500),
            ),
            error: (error, stack) => CustomPaint(
              painter: AuraPainter(
                animationValue: _animationController.value,
                volume: _currentVolume,
                auraColors: [Colors.transparent, Colors.transparent],
              ),
              child: const SizedBox(height: 500, width: 500),
            ),
          ),
          // Layer 2: Lumi Image (Static)
          Image.asset(
            widget.lumiImageUrl,
            height: 400,
            width: 400,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 400,
                width: 400,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                ),
                child: const Icon(Icons.person, size: 200, color: Colors.white),
              );
            },
          ),
          // Layer 6: Mentor Message Overlay with shadow for better legibility
          AnimatedOpacity(
            opacity: _messageOpacity,
            duration: const Duration(milliseconds: 500),
            child: Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  (widget.mentorMessages ??
                      _getDefaultMentorMessages())[_currentMessageIndex],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        offset: Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _initializeStarfield() {
    final random = Random();
    _starParticles = List.generate(50, (index) {
      return StarParticle(
        position: Offset(random.nextDouble() * 500, random.nextDouble() * 500),
        size: random.nextDouble() * 2 + 0.5,
        color: Colors.white.withOpacity(random.nextDouble() * 0.8 + 0.2),
      );
    });
  }

  void _initializeGyroscope() {
    try {
      _gyroscopeSubscription = gyroscopeEventStream().listen((
        GyroscopeEvent event,
      ) {
        if (mounted) {
          setState(() {
            // Convert gyroscope data to offset (scaled down for subtle effect)
            final newOffset = Offset(
              _gyroscopeOffset.dx + event.y * 2,
              _gyroscopeOffset.dy + event.x * 2,
            );
            // Clamp each coordinate separately
            _gyroscopeOffset = Offset(
              newOffset.dx.clamp(-20.0, 20.0),
              newOffset.dy.clamp(-20.0, 20.0),
            );
          });
        }
      });
    } catch (e) {
      // Gyroscope not available on this device
      debugPrint('Gyroscope not available: $e');
    }
  }

  void _detectVolumeSpike() {
    const spikeThreshold = 0.3; // 30% volume increase
    if (_currentVolume - _lastVolume > spikeThreshold) {
      _triggerRipple();
      _volumeSpikeCount++;
    }
    _lastVolume = _currentVolume;
  }

  void _triggerRipple() {
    final theme = universeThemes[widget.programType ?? ProgramType.support]!;
    setState(() {
      _activeRipples.add(
        RippleEffect(
          center: const Offset(250, 250), // Center of the aura
          maxRadius: 300,
          color: theme.rippleColor,
        ),
      );
    });

    // Start ripple animation
    _rippleController.forward(from: 0.0).then((_) {
      // Remove completed ripples
      _activeRipples.removeWhere((ripple) {
        final age = DateTime.now().difference(ripple.startTime).inMilliseconds;
        return age > 2000; // 2 second duration
      });
    });
  }

  // Temporary mapping for backward compatibility
  String _getDefaultProgramIdForType(ProgramType? programType) {
    if (programType == null) return 'default';
    switch (programType) {
      case ProgramType.money:
        return 'money';
      case ProgramType.love:
        return 'love';
      case ProgramType.health:
        return 'health';
      case ProgramType.purpose:
        return 'purpose';
      case ProgramType.identity:
        return 'identity';
      case ProgramType.support:
      default:
        return 'support';
    }
  }
}

class AuraPainter extends CustomPainter {
  final double animationValue;
  final double volume;
  final List<Color> auraColors;

  AuraPainter({
    required this.animationValue,
    required this.volume,
    required this.auraColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Create paint with blur effect
    final paint = Paint()
      ..isAntiAlias = true
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        20 + (volume * 30), // Blur radius increases with volume
      );

    // Draw 4 overlapping circles with swirling motion
    for (int i = 0; i < 4; i++) {
      final angle = (animationValue * 2 * pi) + (i * pi / 2);
      final offsetX = sin(angle + i) * 20; // Swirling motion
      final offsetY = cos(angle + i) * 20;
      final circleCenter = center + Offset(offsetX, offsetY);

      final radius =
          (maxRadius * 0.6) + (volume * maxRadius * 0.3) * (1 - i * 0.1);

      // Create radial gradient using fetched aura colors
      final colors = auraColors.length >= 2
          ? auraColors
          : [const Color(0xFFE6F3FF), const Color(0xFFB3D9FF)];
      final gradient = RadialGradient(
        colors: [
          colors[0].withOpacity(0.6 * volume),
          colors[1].withOpacity(0.3 * volume),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      paint.shader = gradient.createShader(
        Rect.fromCircle(center: circleCenter, radius: radius),
      );

      canvas.drawCircle(circleCenter, radius, paint);
    }
  }

  @override
  bool shouldRepaint(AuraPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.volume != volume ||
        oldDelegate.auraColors != auraColors;
  }
}

class StarfieldPainter extends CustomPainter {
  final List<StarParticle> particles;
  final Offset gyroscopeOffset;
  final double animationValue;

  StarfieldPainter({
    required this.particles,
    required this.gyroscopeOffset,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    for (final particle in particles) {
      // Update particle position with gyroscope tilt and subtle drift
      final driftX =
          sin(animationValue * 2 * pi + particle.twinklePhase) *
          particle.driftSpeed;
      final driftY =
          cos(animationValue * 2 * pi + particle.twinklePhase) *
          particle.driftSpeed;

      final position =
          particle.position + gyroscopeOffset + Offset(driftX, driftY);

      // Wrap around edges for infinite starfield
      final wrappedX = (position.dx % size.width + size.width) % size.width;
      final wrappedY = (position.dy % size.height + size.height) % size.height;

      // Twinkle effect
      final twinkle =
          (sin(animationValue * 4 * pi + particle.twinklePhase) + 1) / 2;
      final opacity = particle.color.opacity * (0.3 + twinkle * 0.7);

      paint.color = particle.color.withOpacity(opacity.clamp(0.0, 1.0));

      canvas.drawCircle(
        Offset(wrappedX, wrappedY),
        particle.size * (0.5 + twinkle * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StarfieldPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.gyroscopeOffset != gyroscopeOffset;
  }
}

class NebulaPainter extends CustomPainter {
  final List<Color> colors;
  final double volume;
  final double animationValue;

  NebulaPainter({
    required this.colors,
    required this.volume,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Create conic gradient that rotates and pulses
    final gradient = SweepGradient(
      center: Alignment.center,
      colors: colors,
      stops: List.generate(colors.length, (i) => i / (colors.length - 1)),
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: maxRadius),
      )
      ..isAntiAlias = true
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        30 + (volume * 50), // Blur increases with volume
      );

    // Draw multiple overlapping circles with volume-based scaling
    for (int i = 0; i < 3; i++) {
      final radius = maxRadius * (0.4 + volume * 0.6) * (1 - i * 0.2);
      final opacity = (0.3 + volume * 0.4) * (1 - i * 0.3);

      paint.color = paint.color.withOpacity(opacity.clamp(0.0, 1.0));

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(NebulaPainter oldDelegate) {
    return oldDelegate.volume != volume ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.colors != colors;
  }
}

class RipplePainter extends CustomPainter {
  final List<RippleEffect> ripples;

  RipplePainter({required this.ripples});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final ripple in ripples) {
      final age = DateTime.now().difference(ripple.startTime).inMilliseconds;
      final progress = age / 2000.0; // 2 second duration

      if (progress >= 1.0) continue;

      ripple.radius = ripple.maxRadius * progress;
      ripple.opacity = (1.0 - progress).clamp(0.0, 1.0);

      paint.color = ripple.color.withOpacity(ripple.opacity * 0.6);
      paint.strokeWidth = 3 * (1 - progress);

      canvas.drawCircle(ripple.center, ripple.radius, paint);
    }
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return true; // Always repaint for smooth animation
  }
}
