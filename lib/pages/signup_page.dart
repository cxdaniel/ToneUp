import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:toneup_app/main.dart';
import 'package:toneup_app/routes.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final supabase = Supabase.instance.client;
  final formKey = GlobalKey<FormState>();
  late final FocusNode emailFocusNode;
  late final FocusNode passwordFocusNode;
  late final FocusNode confirmPasswordFocusNode;

  bool isRequesting = false;

  late ThemeData theme;
  @override
  void initState() {
    super.initState();
    emailFocusNode = FocusNode()
      ..addListener(() {
        if (!emailFocusNode.hasFocus) {
          formKey.currentState?.validate();
        }
      });
    passwordFocusNode = FocusNode()
      ..addListener(() {
        if (!passwordFocusNode.hasFocus) {
          formKey.currentState?.validate();
        }
      });
    confirmPasswordFocusNode = FocusNode()
      ..addListener(() {
        if (!confirmPasswordFocusNode.hasFocus) {
          formKey.currentState?.validate();
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    isRequesting = false;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final email = emailController.text;
    final password = passwordController.text;

    if (password != confirmPasswordController.text) {
      showGlobalSnackBar('Passwords do not match', isError: true);
      return;
    }

    try {
      final signUpResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (signUpResponse.user != null) {
        if (signUpResponse.user != null && mounted) {
          context.go(AppRoutes.HOME);
        }
      }
    } catch (e) {
      if (mounted) {
        showGlobalSnackBar('Sign up failed: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          isRequesting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 24,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 54),
                height: 120,
                alignment: Alignment.center,
                child: Text(
                  'Sign Up',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontFamily: 'Righteous',
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

              /// Sign up Form
              Form(
                key: formKey,
                child: Column(
                  spacing: 16,
                  children: [
                    /// Email
                    TextFormField(
                      controller: emailController,
                      focusNode: emailFocusNode,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainer,
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: theme.colorScheme.errorContainer,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please entry your email';
                        }
                        final emailRegExp = RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                        );
                        if (!emailRegExp.hasMatch(value.trim())) {
                          return 'Enter a valid email (e.g., user@example.com)';
                        }
                        return null; // 校验通过，返回 null
                      },
                      onFieldSubmitted: (value) {
                        formKey.currentState?.validate();
                        FocusScope.of(context).requestFocus(FocusNode());
                      },
                    ),

                    /// Password
                    TextFormField(
                      controller: passwordController,
                      focusNode: passwordFocusNode,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                      onFieldSubmitted: (value) {
                        formKey.currentState?.validate();
                        FocusScope.of(
                          context,
                        ).requestFocus(confirmPasswordFocusNode);
                      },
                    ),

                    /// Confirm Password
                    TextFormField(
                      controller: confirmPasswordController,
                      focusNode: confirmPasswordFocusNode,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value != passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      onFieldSubmitted: (value) {
                        formKey.currentState?.validate();
                        FocusScope.of(context).requestFocus(FocusNode());
                      },
                    ),

                    /// empty space
                    SizedBox(height: 16),

                    /// Login Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          disabledBackgroundColor: theme.colorScheme.surfaceDim,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: isRequesting
                            ? null
                            : () {
                                setState(() {
                                  isRequesting = true;
                                });
                                if (formKey.currentState?.validate() ?? false) {
                                  _signUp();
                                } else {
                                  setState(() {
                                    isRequesting = false;
                                  });
                                }
                              },
                        child: isRequesting
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 16,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Signing up...',
                                    style: theme.textTheme.titleMedium!
                                        .copyWith(
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                  ),
                                ],
                              )
                            : Text(
                                'Sign Up',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              /// Divider
              Divider(
                color: theme.colorScheme.surfaceContainerHigh,
                thickness: 1,
              ),

              /// Sign Up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 14,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      context.replace(AppRoutes.LOGIN);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.all(2),
                      minimumSize: Size.square(40),
                    ),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 14,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
