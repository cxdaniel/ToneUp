import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    try {
      final signUpResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (signUpResponse.user != null) {
        // 注册成功后创建profile
        final existProfile = await supabase
            .from('profiles')
            .select()
            .eq('id', signUpResponse.user!.id)
            .maybeSingle();
        if (existProfile == null) {
          final faker = Faker();
          await supabase.from('profiles').insert([
            {
              'id': signUpResponse.user!.id,
              'nickname': faker.internet.userName(),
            },
          ]);
        }
        // 注册成功后立即登录
        final loginResponse = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (loginResponse.user != null && mounted) {
          context.go(AppRoutes.HOME);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sign up failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 24,
            children: [
              /// Welcome Title
              Container(
                margin: const EdgeInsets.only(top: 54),
                height: 120,
                alignment: Alignment.center,
                child: Text(
                  'Sign Up',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.merge(
                    // GoogleFonts.righteous(
                    //   color: theme.colorScheme.primary,
                    // ),
                    TextStyle(fontFamily: 'Righteous'),
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
                        fillColor: theme.colorScheme.surfaceContainerLow,
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHigh,
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
                        ).colorScheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHigh,
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
                        ).colorScheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHigh,
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
                        //ElevatedButton, TextButton
                        style: TextButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          if (formKey.currentState?.validate() ?? false) {
                            _signUp();
                          }
                        },
                        child: Text(
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
              GestureDetector(
                onTap: () => {context.replace(AppRoutes.LOGIN)},
                child: SizedBox(
                  width: 354,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 14,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w400,
                            height: 1.43,
                            letterSpacing: 0.25,
                          ),
                        ),
                        TextSpan(
                          text: 'Login',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 14,
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w700,
                            height: 1.43,
                            letterSpacing: 0.25,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
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
