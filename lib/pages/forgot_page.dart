import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/main.dart';
import 'package:toneup_app/services/config.dart';

class ForgotPage extends StatefulWidget {
  const ForgotPage({super.key});

  @override
  State<StatefulWidget> createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  final emailController = TextEditingController();
  final supabase = Supabase.instance.client;
  late ThemeData theme;
  bool isRequesting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  Future<void> _sentForgot() async {
    final email = emailController.text.trim();
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegExp.hasMatch(email)) {
      showGlobalSnackBar(
        'Enter a valid email (e.g., user@example.com)',
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isRequesting = true;
    });

    try {
      // 发送密码重置邮件
      // Supabase 会发送一封包含重置链接的邮件
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: UriConfig.resetPasswordCallbackUri,
      );

      if (!mounted) return;

      // 显示成功提示
      showGlobalSnackBar(
        'Password reset email sent! Please check your inbox.',
        isError: false,
      );

      // 清空输入框
      emailController.clear();
    } catch (e) {
      if (!mounted) return;
      showGlobalSnackBar(
        'Failed to send reset email: ${e.toString()}',
        isError: true,
      );
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 40,
            children: [
              Text(
                'Reset Password',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontFamily: 'Righteous',
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  disabledBackgroundColor: theme.colorScheme.surfaceDim,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: isRequesting ? null : _sentForgot,
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
                        'Reset Password',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
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
