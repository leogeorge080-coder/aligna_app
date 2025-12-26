import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/aligna_theme.dart';
import '../widgets/reactive_aura_widget.dart';
import '../models/program_type.dart';
import '../models/daily_content.dart';
import '../providers/daily_content_provider.dart';
import '../services/journal_service.dart';
import '../widgets/glass_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/program_providers.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final ProgramType programType;
  final String? programId;
  final int? dayNumber;

  const VideoPlayerScreen({
    super.key,
    this.programType = ProgramType.support,
    this.programId,
    this.dayNumber,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen>
    with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _showJournalMode = false;
  bool _hasStartedPlaying = false;
  final bool _isLoading = false;
  final bool _showTextCoachBackup = false;
  Timer? _audioLoadTimer;
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

  Future<void> _fadeInAudio() async {
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
        programId: widget.programId ?? 'support',
        dayNumber: 1, // Always day 1 for now
        journalEntryText: content,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journal saved successfully!'),
            backgroundColor: Colors.green,
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
    final dailyContentAsync = ref.watch(
      dailyContentProvider(widget.programId ?? 'support'),
    );
    final themeColorAsync = ref.watch(
      programThemeColorProvider(widget.programId ?? 'support'),
    );

    return Scaffold(
      backgroundColor: AlignaColors.bg,
      body: Stack(
        children: [
          // Main content
          dailyContentAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text('Error loading content: $error')),
            data: (dailyContent) =>
                _buildMainContent(dailyContent, themeColorAsync),
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
                                audioUrl: dailyContentAsync.value?.audioUrl,
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

  Widget _buildMainContent(
    DailyContent? dailyContent,
    AsyncValue<Color?> themeColorAsync,
  ) {
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
                colors: [
                  widget.programType.uiAccent.withOpacity(0.1),
                  widget.programType.uiAccent.withOpacity(0.05),
                ],
              ),
            ),
            child: Center(
              child: ReactiveAuraWidget(
                lumiImageUrl: 'assets/coach/aligna_coach.png',
                audioUrl: dailyContent?.audioUrl,
                programId: widget.programId,
                programType: widget.programType,
                restIntensity: 0.2,
              ),
            ),
          ),
        ),

        // Mentor message
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            dailyContent?.mentorMessage ?? "Ready to begin your journey?",
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              color: AlignaColors.text,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Play button
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final audioUrl = dailyContent?.audioUrl;

                      // Debug logging
                      print('🎵 Start Session pressed');
                      print(
                        '🎵 Daily content: ${dailyContent != null ? 'Found' : 'Null'}',
                      );
                      print('🎵 Audio URL: $audioUrl');
                      print('🎵 Is playing: $_isPlaying');

                      if (audioUrl == null) {
                        // Show error message when no audio is available
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Audio content is not available. Please check your connection and try again.',
                            ),
                            duration: Duration(seconds: 3),
                          ),
                        );
                        return;
                      }

                      if (_isPlaying) {
                        await _audioPlayer.pause();
                        setState(() => _isPlaying = false);
                        print('🎵 Audio paused');
                      } else {
                        try {
                          print('🎵 Attempting to play audio...');
                          // Properly set source URL and await before resuming
                          await _audioPlayer.setSourceUrl(audioUrl);

                          // Start with volume at 0 for fade-in effect
                          await _audioPlayer.setVolume(0.0);

                          // Add haptic feedback the exact millisecond audio starts
                          HapticFeedback.mediumImpact();

                          // Start playing
                          await _audioPlayer.resume();
                          setState(() => _hasStartedPlaying = true);

                          // Soft fade-in over 2 seconds
                          _fadeInAudio();

                          setState(() => _isPlaying = true);
                          print('🎵 Audio started playing successfully');
                        } catch (e) {
                          print('🎵 Audio play error: $e');
                          // Try with a different URL as fallback
                          try {
                            print('🎵 Trying alternative audio URL...');
                            const altUrl =
                                'https://www.learningcontainer.com/wp-content/uploads/2020/02/Kalimba.mp3';
                            await _audioPlayer.setSourceUrl(altUrl);

                            // Start with volume at 0 for fade-in effect
                            await _audioPlayer.setVolume(0.0);

                            // Add haptic feedback
                            HapticFeedback.mediumImpact();

                            // Start playing
                            await _audioPlayer.resume();

                            // Soft fade-in over 2 seconds
                            _fadeInAudio();

                            setState(() => _isPlaying = true);
                            print('🎵 Alternative audio started playing');
                          } catch (e2) {
                            print('🎵 Alternative audio also failed: $e2');
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColorAsync.maybeWhen(
                        data: (color) => color ?? widget.programType.uiAccent,
                        orElse: () => widget.programType.uiAccent,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isPlaying ? 'Pause Session' : 'Start Session',
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

                const SizedBox(height: 24),

                // Session info
                if (dailyContent != null) ...[
                  Text(
                    'Day ${dailyContent.dayNumber}: ${dailyContent.title}',
                    style: TextStyle(
                      color: AlignaColors.subtext,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dailyContent.question,
                    style: const TextStyle(
                      color: AlignaColors.text,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
