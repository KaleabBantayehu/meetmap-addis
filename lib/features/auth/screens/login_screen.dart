import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meetmap_addis/core/constants/colors.dart';

import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_textfield.dart';
import '../../../shared/widgets/or_divider.dart';
import '../widgets/auth_footer_link.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_method_selector.dart';
import '../widgets/google_signin_button.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  AuthMethod _authMethod = AuthMethod.email;
  bool _isObscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showAuthError(authProvider.errorMessage ?? 'Authentication failed');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showAuthError('An unexpected error occurred.');
    }
  }

  // ignore: unused_element
  void _showAuthError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AuthHeader(),

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

                  if (_authMethod == AuthMethod.email) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Email Address',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
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
                        if (!value.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                  ] else ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Phone Number',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
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

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Password',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: forgot password screen
                        },
                        child: Text(
                          'Forgot Password?',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Enter your password',
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
                        return 'Please enter password';
                      }
                      if (value.length < 6) {
                        return 'Minimum 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  CustomButton(
                    text: 'Sign In',
                    isLoading: _isLoading,
                    onPressed: _login,
                  ),

                  const SizedBox(height: 24),

                  const OrDivider(),

                  const SizedBox(height: 24),

                  GoogleSignInButton(
                    onPressed: () {
                      // TODO: Google Sign In
                      // TODO: replace with real authentication logic (temporary dev routing)
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'DEV MODE: UI Navigation Only',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),

                  const SizedBox(height: 8),

                  AuthFooterLink(
                    text: "Don't have an account?",
                    linkText: 'Sign Up',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
