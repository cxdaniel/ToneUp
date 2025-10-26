// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api
// import 'package:google_fonts/google_fonts.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:toneup_app/routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final supabase = Supabase.instance.client;
  late ThemeData theme;

  bool isRequesting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    isRequesting = false;
  }

  Future<void> _signIn() async {
    isRequesting = true;
    final email = emailController.text;
    final password = passwordController.text;
    if (!mounted) {
      isRequesting = false;
      return;
    }
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null && mounted) {
        // 登录成功后检查并profile
        final existProfile = await supabase
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .maybeSingle();
        if (!mounted) return;
        if (existProfile == null) {
          final faker = Faker();
          await supabase.from('profiles').insert([
            {'id': response.user!.id, 'nickname': faker.internet.userName()},
          ]);
          if (!mounted) return;
        }
        context.go(AppRoutes.HOME);
      }
    } catch (e) {
      debugPrint("登录失败：$e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            spacing: 24,
            children: [
              /// Welcome Title
              Container(
                margin: const EdgeInsets.only(top: 54),
                height: 120,
                alignment: Alignment.center,
                child: Text(
                  'Login to ToneUp',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontFamily: 'Righteous',
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

              /// Email
              TextField(
                controller: emailController,
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
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
              ),

              /// Password
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                obscureText: true,
              ),

              /// Forgot Password
              Text(
                'Forgot Password',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),

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
                          final emailRegExp = RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                          );
                          if (!emailRegExp.hasMatch(
                            emailController.text.trim(),
                          )) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Enter a valid email (e.g., user@example.com)',
                                ),
                              ),
                            );
                          } else if (passwordController.text.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'The password is exceeding 6 characters.',
                                ),
                              ),
                            );
                          } else {
                            setState(() {
                              isRequesting = true;
                            });
                            _signIn();
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
                              'Signing...',
                              style: theme.textTheme.titleMedium!.copyWith(
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Sign in',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              /// Or continue with
              Divider(
                color: theme.colorScheme.surfaceContainerHigh,
                thickness: 1,
              ),

              /// with Google
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: SvgPicture.asset(
                    'assets/images/login_icon_google.svg',
                    width: 24,
                    height: 24,
                  ),
                  label: Text(
                    'Continue with Google',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.surfaceContainerLowest,
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  onPressed: () {
                    // TODO: Add Continue with Google logic here
                  },
                ),
              ),

              /// with apple
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: SvgPicture.asset(
                    'assets/images/login_icon_apple.svg',
                    width: 24,
                    height: 24,
                  ),
                  label: Text(
                    'Continue with Apple',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.surfaceContainerLowest,
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  onPressed: () {
                    // TODO: Add Continue with Apple logic here
                  },
                ),
              ),

              /// divider
              Divider(
                color: theme.colorScheme.surfaceContainerHigh,
                thickness: 1,
              ),

              /// Sign Up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Don’t have an account?',
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
                      context.replace(AppRoutes.SIGN_UP);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.all(2),
                      minimumSize: Size.square(40),
                    ),
                    child: Text(
                      'SignUp',
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
