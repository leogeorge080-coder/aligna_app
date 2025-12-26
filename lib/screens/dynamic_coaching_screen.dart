import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/program_type.dart';
import '../models/daily_content.dart';
import '../providers/daily_content_provider.dart';
import '../providers/vibration_level_provider.dart';
import '../providers/program_providers.dart';
import '../services/journal_service.dart';
import '../widgets/reactive_aura_widget.dart';
import '../widgets/glass_card.dart';
import '../theme/aligna_theme.dart';

class DynamicCoachingScreen extends ConsumerStatefulWidget {
  final String programId;
  final ProgramType programType;

  const DynamicCoachingScreen({
    super.key,
    required this.programId,
    required this.programType,
  });

  @override
  ConsumerState<DynamicCoachingScreen> createState() =>
      _DynamicCoachingScreenState();
}

class _DynamicCoachingScreenState extends ConsumerState<DynamicCoachingScreen>
    with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _showJournalMode = false;
  bool _hasStartedPlaying = false;
  final TextEditingController _journalController = TextEditingController();
  late AnimationController _transitionController;
  late Animation<double> _lumiScaleAnimation;
  late Animation<double> _journalSlideAnimation;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioPlayer();

    // Setup transition animations
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _lumiScaleAnimation = Tween<double>(begin: 1.0, end: 0.6).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeInOut),
    );

    _journalSlideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeInOut),
    );
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

    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      // Only transition to journal mode if we actually played some audio
      // and we're not already in journal mode
      if (!_showJournalMode && _hasStartedPlaying) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_showJournalMode) {
            _transitionToJournalMode();
          }
        });
      }
    });
  }

  void _transitionToJournalMode() {
    setState(() {
      _showJournalMode = true;
    });
    _transitionController.forward();
  }

  Future<void> _saveJournalEntry() async {
    final content = _journalController.text.trim();
    if (content.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await JournalService.saveJournalEntry(
        userId: user.id,
        programId: widget.programId,
        dayNumber: 1, // TODO: Get actual day from progress
        journalEntryText: content,
      );

      // Update vibration level/progress
      await ref.read(vibrationLevelProvider.notifier).completeSession();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Journal saved'),
            backgroundColor: widget.programType.uiAccent,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save journal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _journalController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dailyContentAsync = ref.watch(dailyContentProvider(widget.programId));
    final vibrationLevel = ref.watch(vibrationLevelProvider);

    return Scaffold(
      backgroundColor: AlignaColors.bg,
      body: Stack(
        children: [
          // Main content
          dailyContentAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text('Error loading content: $error')),
            data: (dailyContent) => _buildMainContent(dailyContent),
          ),

          // Journal overlay
          if (_showJournalMode)
            AnimatedBuilder(
              animation: _transitionController,
              builder: (context, child) {
                return Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.7),
                    child: Column(
                      children: [
                        // Minimized Lumi
                        SizedBox(
                          height: 200,
                          child: Center(
                            child: Transform.scale(
                              scale: _lumiScaleAnimation.value,
                              child: ReactiveAuraWidget(
                                lumiImageUrl: 'assets/coach/aligna_coach.png',
                                programId: widget.programId,
                                restIntensity: 0.3,
                              ),
                            ),
                          ),
                        ),

                        // Journal prompt
                        Expanded(
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 1),
                              end: Offset.zero,
                            ).animate(_journalSlideAnimation),
                            child: GlassCard(
                              margin: const EdgeInsets.all(16),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dailyContentAsync.value?.journalPrompt ??
                                          'What insights did you receive today?',
                                      style: GoogleFonts.dancingScript(
                                        fontSize: 24,
                                        color: AlignaColors.text,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Expanded(
                                      child: TextField(
                                        controller: _journalController,
                                        maxLines: null,
                                        expands: true,
                                        decoration: InputDecoration(
                                          hintText: 'Write your thoughts...',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: widget.programType.uiAccent
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color:
                                                  widget.programType.uiAccent,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: AlignaColors.text,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                color:
                                                    widget.programType.uiAccent,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                            ),
                                            child: Text(
                                              'Skip',
                                              style: TextStyle(
                                                color:
                                                    widget.programType.uiAccent,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: _saveJournalEntry,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  widget.programType.uiAccent,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                            ),
                                            child: const Text(
                                              'Save Reflection',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Back button overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: SafeArea(
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(DailyContent? dailyContent) {
    final vibrationLevel = ref.watch(vibrationLevelProvider);
    final auraColorsAsync = ref.watch(
      programAuraColorsProvider(widget.programId),
    );

    return Column(
      children: [
        // Hero area with Lumi and aura
        Expanded(
          flex: 3,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: auraColorsAsync.maybeWhen(
                  data: (colors) => [
                    (colors?.isNotEmpty ?? false)
                        ? colors![0].withOpacity(0.1)
                        : const Color(0xFFE6F3FF).withOpacity(0.1),
                    (colors?.length ?? 0) > 1
                        ? colors![1].withOpacity(0.05)
                        : const Color(0xFFB3D9FF).withOpacity(0.05),
                  ],
                  orElse: () => [
                    const Color(0xFFE6F3FF).withOpacity(0.1),
                    const Color(0xFFB3D9FF).withOpacity(0.05),
                  ],
                ),
              ),
            ),
            child: Center(
              child: ReactiveAuraWidget(
                lumiImageUrl: 'assets/coach/aligna_coach.png',
                programId: widget.programId,
                restIntensity: 0.2,
              ),
            ),
          ),
        ),

        // Mentor message
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            dailyContent?.focus ?? "Ready to begin your journey?",
            style: const TextStyle(
              fontSize: 18,
              color: AlignaColors.text,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Action buttons
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Resume Day button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final audioUrl = dailyContent?.audioUrl;

                      if (audioUrl == null || audioUrl.isEmpty) {
                        // Show "Coming Soon" popup for professional UX
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Coming Soon'),
                              content: const Text(
                                'This session content is being prepared and will be available soon. '
                                'Check back later for the latest coaching sessions.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                        return;
                      }

                      // Validate audio URL format
                      if (!audioUrl.startsWith('http') ||
                          !audioUrl.contains('.mp3')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Invalid audio format. Please contact support.',
                            ),
                            duration: Duration(seconds: 3),
                          ),
                        );
                        return;
                      }

                      if (_isPlaying) {
                        await _audioPlayer.pause();
                        setState(() => _isPlaying = false);
                      } else {
                        try {
                          await _audioPlayer.setSourceUrl(audioUrl);
                          await _audioPlayer.resume();
                          setState(() {
                            _isPlaying = true;
                            _hasStartedPlaying = true;
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to play audio: $e'),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.programType.uiAccent,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child:
                        (dailyContent?.audioUrl == null ||
                            dailyContent!.audioUrl!.isEmpty)
                        ? const Text(
                            'Coming Soon',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isPlaying ? 'Pause Session' : 'Resume Day 1',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Lumi's Vault button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Navigate to vault
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: widget.programType.uiAccent),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Lumi's Vault",
                      style: TextStyle(
                        color: widget.programType.uiAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Progress indicator (Vibration Level)
                Column(
                  children: [
                    Text(
                      'Vibration Level',
                      style: TextStyle(
                        color: AlignaColors.subtext,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: vibrationLevel.level,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.programType.uiAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(vibrationLevel.level * 100).round()}% Aligned',
                      style: TextStyle(
                        color: widget.programType.uiAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
