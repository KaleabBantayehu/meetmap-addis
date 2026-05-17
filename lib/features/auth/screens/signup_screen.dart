import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../../../shared/widgets/or_divider.dart';
import '../widgets/auth_footer_link.dart';
import '../widgets/auth_method_selector.dart';
import '../widgets/google_signin_button.dart';
import '../widgets/signup_header.dart';
import '../widgets/terms_checkbox.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  AuthMethod _authMethod = AuthMethod.email;
  bool _isObscure = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signup() {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the Terms of Service and Privacy Policy.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // TODO: connect signup API/Firebase
    // TODO: connect phone verification / OTP flow

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      
      // Successfully signed up, but do not navigate to home automatically
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SignupHeader(),

                        const SizedBox(height: 32),

                        AuthMethodSelector(
                          selectedMethod: _authMethod,
                          onChanged: (method) {
                            setState(() {
                              _authMethod = method;
                            });
                          },
                        ),

                        const SizedBox(height: 24),

                        Text(
                          'Full Name',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _nameController,
                          hintText: 'John Doe',
                          prefixIcon: const Icon(Icons.person_outline),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your full name';
                            }
                            if (value.trim().length < 2) {
                              return 'Minimum 2 characters required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        if (_authMethod == AuthMethod.email) ...[
                          Text(
                            'Email Address',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: _emailController,
                            hintText: 'name@example.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                              if (!emailRegex.hasMatch(value)) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                        ] else ...[
                          Text(
                            'Phone Number',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: _phoneController,
                            hintText: '+251 9XX XXX XXX',
                            prefixIcon: const Icon(Icons.phone_outlined),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your phone number';
                              }
                              final phoneRegex = RegExp(r'^(?:\+2519|09)\d{8}$');
                              if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
                                return 'Enter a valid Ethiopian phone number';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 16),

                        Text(
                          'Password',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _passwordController,
                          hintText: 'Create a password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          obscureText: _isObscure,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _isObscure = !_isObscure;
                              });
                            },
                            icon: Icon(
                              _isObscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 8) {
                              return 'Minimum 8 characters required';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        TermsCheckbox(
                          value: _agreedToTerms,
                          onChanged: (val) {
                            setState(() {
                              _agreedToTerms = val ?? false;
                            });
                          },
                        ),

                        const SizedBox(height: 32),

                        CustomButton(
                          text: 'Create Account',
                          isLoading: _isLoading,
                          onPressed: _signup,
                        ),

                        const SizedBox(height: 24),

                        const OrDivider(),

                        const SizedBox(height: 24),

                        GoogleSignInButton(
                          onPressed: () {
                            // TODO: Google Sign Up
                          },
                        ),

                        const SizedBox(height: 24),

                        AuthFooterLink(
                          text: 'Already have an account?',
                          linkText: 'Sign In',
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}