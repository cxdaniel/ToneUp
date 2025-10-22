// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api
// import 'package:google_fonts/google_fonts.dart';
import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
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

  Future<void> _signIn() async {
    final email = emailController.text;
    final password = passwordController.text;
    if (!mounted) return;
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
                  style: Theme.of(context).textTheme.headlineLarge?.merge(
                    // GoogleFonts.righteous(
                    //   color: Theme.of(context).colorScheme.primary,
                    // ),
                    TextStyle(fontFamily: 'Righteous'),
                  ),
                ),
              ),

              /// Email
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
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
                  fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    ),
                  ),
                ),
                obscureText: true,
              ),

              /// Forgot Password
              Text(
                'Forgot Password',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              /// Login Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  //ElevatedButton, TextButton
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _signIn,
                  child: Text(
                    'Login',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),

              /// Or continue with
              Divider(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                thickness: 1,
              ),

              /// with Google
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  icon: SvgPicture.asset(
                    'assets/images/login_icon_google.svg',
                    width: 24,
                    height: 24,
                  ),
                  label: Text(
                    'Continue with Google',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        width: 2,
                        color: Theme.of(context).colorScheme.secondaryContainer,
                      ),
                    ),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerLowest,
                  ),
                  onPressed: () {
                    // TODO: Add Continue with Google logic here
                  },
                ),
              ),

              /// with apple
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  icon: SvgPicture.asset(
                    'assets/images/login_icon_apple.svg',
                    width: 24,
                    height: 24,
                  ),
                  label: Text(
                    'Continue with Apple',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        width: 2,
                        color: Theme.of(context).colorScheme.secondaryContainer,
                      ),
                    ),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerLowest,
                  ),
                  onPressed: () {
                    // TODO: Add Continue with Apple logic here
                  },
                ),
              ),

              /// divider
              Divider(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                thickness: 1,
              ),

              /// Sign Up
              GestureDetector(
                onTap: () => {context.replace(AppRoutes.SIGN_UP)},
                child: SizedBox(
                  width: double.infinity,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Don’t have an account? ',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        TextSpan(
                          text: 'Sign Up',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
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
