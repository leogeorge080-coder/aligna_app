import 'package:flutter/material.dart';
import 'package:aligna_app/theme/aligna_theme.dart';
import 'package:aligna_app/utils/haptics.dart';

class WelcomeCelebrationScreen extends StatefulWidget {
  final String userName;

  const WelcomeCelebrationScreen({super.key, required this.userName});

  @override
  State<WelcomeCelebrationScreen> createState() =>
      _WelcomeCelebrationScreenState();
}

class _WelcomeCelebrationScreenState extends State<WelcomeCelebrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    // Start animations
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.7),
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AlignaColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AlignaColors.radiantGold.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Celebration icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AlignaColors.radiantGold,
                              AlignaColors.radiantGold.withOpacity(0.7),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.celebration,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Welcome message
                      Text(
                        'Welcome, ${widget.userName}!',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AlignaColors.text,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Subtitle
                      Text(
                        'Your manifestation journey begins now.\nLet\'s create the life you deserve.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AlignaColors.subtext,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Tap to continue
                      Text(
                        'Tap anywhere to continue',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AlignaColors.subtext.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
