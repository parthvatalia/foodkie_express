import 'dart:async';
import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import 'package:foodkie_express/routes.dart';
import 'package:foodkie_express/screens/auth/controllers/auth_provider.dart' as ap;
import 'package:foodkie_express/widgets/animated_button.dart';

import '../../api/auth_service.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResendEnabled = false;
  String _errorMessage = "";
  int _resendTimer = 30; // Seconds
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _isResendEnabled = false;
      _resendTimer = 30;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _isResendEnabled = true;
          timer.cancel();
        }
      });
    });
  }

// In your login/verification screen
  Future<void> _verifyOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userCredential = await authService.verifyOTP(_otpController.text);

      // Verification successful
      // You can access userCredential.user here if needed
      if (mounted) {
        // Navigate to next screen
        Navigator.of(context).pushNamedAndRemoveUntil('/home',(route) => false,);
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase auth errors
      String errorMessage;

      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'The verification code is invalid. Please check and try again.';
          break;
        case 'invalid-verification-id':
          errorMessage = 'Session expired. Please request a new OTP.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later.';
          break;
        default:
          errorMessage = 'Verification failed: ${e.message}';
      }

      setState(() {
        _errorMessage = errorMessage;
      });
    } catch (e) {
      // Handle other errors
      setState(() {
        _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    if (!_isResendEnabled) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<ap.AuthProvider>(context, listen: false);
      await authProvider.sendOTP(widget.phoneNumber);

      // Restart timer
      _startResendTimer();

      // Show success message
      if (mounted) {
        AnimatedSnackBar.material(
          'OTP resent successfully',
          type: AnimatedSnackBarType.success,
          mobileSnackBarPosition: MobileSnackBarPosition.bottom,
          desktopSnackBarPosition: DesktopSnackBarPosition.bottomCenter,
          duration: Duration(seconds: 2),
        ).show(context);
      }
    } catch (e) {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: Theme.of(context).textTheme.headlineSmall,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Phone'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Instructions
              Text(
                'Enter Verification Code',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We have sent a verification code to ${widget.phoneNumber}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 40),
              // OTP Input
              Center(
                child: Pinput(
                  controller: _otpController,
                  length: 6,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  submittedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  onCompleted: (pin) => _verifyOTP(),
                ),
              ),
              const SizedBox(height: 40),
              // Verify Button
              AnimatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                isLoading: _isLoading,
                child: Text(
                  'Verify',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Resend OTP
              Center(
                child: TextButton(
                  onPressed: _isResendEnabled ? _resendOTP : null,
                  child: Text(
                    _isResendEnabled
                        ? 'Resend OTP'
                        : 'Resend OTP in $_resendTimer seconds',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _isResendEnabled
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}