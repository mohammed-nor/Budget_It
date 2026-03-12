import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    _navigateToHome();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Myhome()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Colors.grey[900]!],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Decorative circle background for icon
                      Container(
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.green[700]!, Colors.green[900]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'images/ICON.png',
                            width: 110,
                            height: 110,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // App Name
                      Text(
                        'Budget It',
                        style: GoogleFonts.lato(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Decorative line
                      Container(
                        width: 50,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.green[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Slogan
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          'سبيلك للتوازن المالي',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.elMessiri(
                            fontSize: 16,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom Bar with Developer and Copyright
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                border: Border(
                  top: BorderSide(
                    color: Colors.green[700]!.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'مطور من طرف محمد نور',
                    style: GoogleFonts.elMessiri(
                      fontSize: 13,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© 2026 جميع الحقوق محفوظة',
                    style: GoogleFonts.elMessiri(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
