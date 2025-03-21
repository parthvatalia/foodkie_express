import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodkie_express/routes.dart';
import 'package:foodkie_express/screens/auth/controllers/auth_provider.dart';
import 'package:foodkie_express/utils/validators.dart';
import 'package:foodkie_express/widgets/animated_button.dart';
import 'package:lottie/lottie.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _selectedCountryCode = '+91'; // Default to India
  bool _isLoading = false;

  final List<String> _countryCodes = ['+91', '+1', '+44', '+61', '+65']; // Add more as needed

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final phoneNumber = '$_selectedCountryCode${_phoneController.text.trim()}';
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      await authProvider.sendOTP(phoneNumber);

      // Navigate to OTP verification screen
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.otp,
        arguments: {'phoneNumber': phoneNumber},
      );
    } catch (e) {
      String errorMessage = e.toString();

      // Handle specific Firebase errors
      if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Too many login attempts. Please try again later or use a different phone number.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );

    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                 SizedBox(height: MediaQuery.sizeOf(context).height * 0.1),
                // Logo or Animation
                Center(
                  child: Lottie.asset(
                    height: MediaQuery.sizeOf(context).height * 0.3,
                    width: MediaQuery.sizeOf(context).width * 0.9,
                    'assets/animations/food_login.json',
                    repeat: true,
                  ),
                ),
                const SizedBox(height: 40),
                // Welcome Text
                Text(
                  'Welcome to Foodkie Express',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter your phone number to continue',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Phone Input
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Country Code Dropdown
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: ButtonTheme(
                          alignedDropdown: true,
                          child: DropdownButton<String>(
                            value: _selectedCountryCode,
                            items: _countryCodes.map((code) {
                              return DropdownMenuItem<String>(
                                value: code,
                                child: Text(code),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedCountryCode = value;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Phone TextField
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '9876543210',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: Validators.validatePhone,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _sendOTP(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Continue Button
                AnimatedButton(
                  onPressed: _isLoading ? null : _sendOTP,
                  isLoading: _isLoading,
                  child: Text(
                    'Continue',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Terms & Privacy Policy
                Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}