import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:foodkie_express/routes.dart';
import 'package:foodkie_express/screens/auth/controllers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAuthAndNavigate();
      }
    });

    _controller.forward();
  }

  Future<void> _checkAuthAndNavigate() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = await authProvider.checkIfLoggedIn();

    if (isLoggedIn) {
      AppRoutes.navigateToHome();
    } else {
      AppRoutes.navigateToLogin();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo or Animation
            Lottie.asset(
              height: MediaQuery.sizeOf(context).height * 0.5,
              width: MediaQuery.sizeOf(context).height * 0.9,
              'assets/animations/food_delivery.json',
              controller: _controller,
              onLoaded: (composition) {
                _controller.duration = composition.duration;
                _controller.forward();
              },
            ),
            const SizedBox(height: 30),
            // App Name
            Text(
              'Foodkie Express',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            // Tagline
            Text(
              'Fast food management, faster service',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 50),
            // Loading indicator
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}