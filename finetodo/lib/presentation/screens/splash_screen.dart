import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashStateScreen();
}

class _SplashStateScreen extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final asset = 'assets/Fine Planner Icon.png';
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late Animation<double> _translateAnim;
  late Animation<double> _textTranslateAnim;
  final GlobalKey _containerKey = GlobalKey();

  bool _showText = false; // NEW: controls text visibility

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3100),
    );

    // scale down animation
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1.6), weight: 800),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.6,
          end: 0.8,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1500,
      ),
    ]).animate(_controller);

    // translate left animation
    _translateAnim = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.85, 1.0, curve: Curves.easeOut),
      ),
    );

    // Text animation hidden until image finishes, then slides right
    _textTranslateAnim = Tween<double>(begin: 0.0, end: 70.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.9, 1.0, curve: Curves.easeOut),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;

      double? containerLeftGlobal;
      double containerWidth = 0;
      final ctx = _containerKey.currentContext;
      if (ctx != null) {
        final box = ctx.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          final topLeft = box.localToGlobal(Offset.zero);
          containerLeftGlobal = topLeft.dx;
          containerWidth = box.size.width;
        }
      }

      const imageWidth = 400.0;
      const padding = 10.0;
      final containerW = containerWidth == 0
          ? (imageWidth + padding * 2)
          : containerWidth;
      final containerLeft =
          containerLeftGlobal ?? ((size.width - containerW) / 2);

      final currentCenterX = size.width / 2;
      final targetCenterX = containerLeft + padding + (imageWidth / 2);
      final dx = targetCenterX - currentCenterX;

      _translateAnim = Tween<double>(begin: 0.0, end: dx).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.85, 1.0, curve: Curves.easeOut),
        ),
      );

      setState(() {});
    });

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Show text after image animation completes
        setState(() {
          _showText = true;
        });

        // Navigate after short delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF5D5CDE),
      body: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final dx = _translateAnim.value;
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      key: _containerKey,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(width: 1, color: Colors.transparent),
                      ),
                      child: Image.asset(
                        asset,
                        width: 400,
                        height: 300,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Text appears only after image animation completes
          if (_showText)
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_textTranslateAnim.value, 0),
                    child: const Text(
                      'Fine\nPlanner',
                      style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Roboto',
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
