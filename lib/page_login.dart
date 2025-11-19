import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:toneup_app/routes.dart';
import 'package:toneup_app/services/oauth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final supabase = Supabase.instance.client;
  final _oauthService = OAuthService();
  late ThemeData theme;
  bool isRequesting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    // 取消正在进行的 OAuth 认证
    _oauthService.cancelAuth();
    super.dispose();
  }

  /// 邮箱密码登录
  Future<void> _signIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    // 验证邮箱格式
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegExp.hasMatch(email)) {
      _showError('Enter a valid email (e.g., user@example.com)');
      return;
    }

    // 验证密码长度
    if (password.length < 6) {
      _showError('The password must be at least 6 characters.');
      return;
    }

    setState(() => isRequesting = true);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null && mounted) {
        debugPrint('✅ 邮箱登录成功: ${response.user!.email}');
        context.go(AppRoutes.HOME);
      }
    } catch (e) {
      debugPrint('❌ 邮箱登录失败: $e');
      if (mounted) {
        _showError('Login failed: ${_getErrorMessage(e)}');
      }
    } finally {
      if (mounted) {
        setState(() => isRequesting = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    context.push(AppRoutes.FORGOT);
  }

  /// Apple 登录
  Future<void> _loginWithApple() async {
    if (isRequesting) return;

    setState(() => isRequesting = true);

    try {
      debugPrint('🍎 开始 Apple 登录');

      final success = await _oauthService.signInWithProvider(
        OAuthProvider.apple,
        timeout: const Duration(seconds: 60),
      );

      if (success) {
        debugPrint('✅ Apple 登录成功，等待导航...');
        // 导航由 main.dart 的 onAuthStateChange 处理
      } else {
        debugPrint('❌ Apple 登录失败或取消');
        if (mounted) {
          _showError('Apple login was cancelled or failed');
        }
      }
    } on PlatformException catch (pe) {
      debugPrint('❌ Apple 登录 PlatformException: ${pe.code} - ${pe.message}');

      // 忽略 Safari View Controller 启动警告
      if (!pe.message!.contains('Error while launching')) {
        if (mounted) {
          _showError('Apple login error: ${pe.message}');
        }
      }
    } catch (e) {
      debugPrint('❌ Apple 登录异常: $e');
      if (mounted) {
        _showError('Apple login failed: ${_getErrorMessage(e)}');
      }
    } finally {
      if (mounted) {
        setState(() => isRequesting = false);
      }
    }
  }

  /// Google 登录
  Future<void> _loginWithGoogle() async {
    if (isRequesting) return;

    setState(() => isRequesting = true);

    try {
      debugPrint('🔍 开始 Google 登录');

      final success = await _oauthService.signInWithProvider(
        OAuthProvider.google,
        timeout: const Duration(seconds: 60),
      );

      if (success) {
        debugPrint('✅ Google 登录成功，等待导航...');
      } else {
        debugPrint('❌ Google 登录失败或取消');
        if (mounted) {
          _showError('Google login was cancelled or failed');
        }
      }
    } on PlatformException catch (pe) {
      debugPrint('❌ Google 登录 PlatformException: ${pe.code} - ${pe.message}');

      if (!pe.message!.contains('Error while launching')) {
        if (mounted) {
          _showError('Google login error: ${pe.message}');
        }
      }
    } catch (e) {
      debugPrint('❌ Google 登录异常: $e');
      if (mounted) {
        _showError('Google login failed: ${_getErrorMessage(e)}');
      }
    } finally {
      if (mounted) {
        setState(() => isRequesting = false);
      }
    }
  }

  /// 显示错误提示
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 获取友好的错误信息
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('invalid login credentials')) {
      return 'Invalid email or password';
    } else if (errorStr.contains('email not confirmed')) {
      return 'Please verify your email first';
    } else if (errorStr.contains('network')) {
      return 'Network error, please check your connection';
    }

    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              TextButton(
                onPressed: _forgotPassword,
                style: TextButton.styleFrom(padding: EdgeInsets.all(4)),
                child: Text(
                  'Forgot Password',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
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
                  onPressed: isRequesting ? null : _signIn,
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
                  onPressed: _loginWithGoogle,
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
                    colorFilter: ColorFilter.mode(
                      theme.colorScheme.onSurface,
                      BlendMode.srcIn,
                    ),
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
                  onPressed: _loginWithApple,
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
                      padding: EdgeInsets.all(4),
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
