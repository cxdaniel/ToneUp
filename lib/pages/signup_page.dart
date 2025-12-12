import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:toneup_app/components/components.dart';
import 'package:toneup_app/main.dart';
import 'package:toneup_app/router_config.dart';
import 'package:toneup_app/services/utils.dart';

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

  bool isLoading = false;

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
    isLoading = false;
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
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (password != confirmPasswordController.text) {
      showGlobalSnackBar('Passwords do not match', isError: true);
      setState(() {
        isLoading = false;
      });
      return;
    }

    FocusScope.of(context).unfocus();

    try {
      // 步骤 1: 注册账号并发送 OTP 验证码
      // 注意: 需要在 Supabase Dashboard 配置邮件模板为 OTP 而不是 Magic Link
      // Authentication → Email Templates → Change Email (OTP) 模板
      final signUpResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: null, // 不使用重定向链接，强制使用 OTP
      );

      if (!mounted) return;

      // 检查是否成功
      if (signUpResponse.user == null) {
        showGlobalSnackBar(
          'Sign up failed. This email may already be registered.',
          isError: true,
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      // 如果已经有 session，说明是自动确认模式，直接跳转
      if (signUpResponse.session != null) {
        setState(() {
          isLoading = false;
        });
        if (!mounted) return;
        showGlobalSnackBar('Registration successful!', isError: false);
        context.go(AppRouter.HOME);
        return;
      }

      // 步骤 2: 关闭加载状态，显示 OTP 验证对话框
      setState(() {
        isLoading = false;
      });

      // 步骤 3: 弹出 OTP 验证对话框
      String? verifyMessage;
      final verified = await OtpVerificationDialog.show(
        context: context,
        title: 'Verify Your Email',
        description:
            'We\'ve sent a 6-digit verification code to $email. '
            'Please check your inbox and enter the code below.',
        onVerify: (otpCode) async {
          try {
            // 验证 OTP
            final response = await supabase.auth.verifyOTP(
              type: OtpType.signup,
              email: email,
              token: otpCode,
            );

            if (response.session != null) {
              verifyMessage = 'Email verified successfully!';
              return (true, verifyMessage);
            } else {
              verifyMessage = 'Verification failed. Please try again.';
              return (false, verifyMessage);
            }
          } catch (e) {
            verifyMessage = e.toString().replaceAll('Exception: ', '');
            return (false, verifyMessage);
          }
        },
        onResend: () async {
          // 重新发送 OTP
          try {
            await supabase.auth.resend(type: OtpType.signup, email: email);
          } catch (e) {
            if (mounted) {
              showGlobalSnackBar(
                'Failed to resend code: ${e.toString()}',
                isError: true,
              );
            }
          }
        },
      );

      if (!mounted) return;

      // 步骤 4: 处理验证结果
      if (verified == true) {
        showGlobalSnackBar(
          verifyMessage ?? 'Registration successful!',
          isError: false,
        );
        // 验证成功后跳转到首页
        context.go(AppRouter.HOME);
      } else if (verified == false) {
        showGlobalSnackBar(
          verifyMessage ?? 'Email verification failed',
          isError: true,
        );
      }
      // verified == null 表示用户取消了验证，不做任何操作
    } catch (e) {
      if (mounted) {
        showGlobalSnackBar('Sign up failed: $e', isError: true);
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 加载中状态
    if (isLoading) {
      LoadingOverlay.show(context, label: 'Signing up...');
    } else {
      LoadingOverlay.hide();
    }
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
                          if (!AppUtils.isEmail(value)) {
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
                            disabledBackgroundColor:
                                theme.colorScheme.surfaceDim,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  if (formKey.currentState?.validate() ??
                                      false) {
                                    _signUp();
                                  } else {
                                    setState(() {
                                      isLoading = false;
                                    });
                                  }
                                },
                          child: isLoading
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
                        context.replace(AppRouter.LOGIN);
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
      ),
    );
  }
}
