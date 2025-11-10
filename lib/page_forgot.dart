import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final email = emailController.text;
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegExp.hasMatch(email.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter a valid email (e.g., user@example.com)')),
      );
      return;
    }
    if (email.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('The password is exceeding 6 characters.')),
      );
      return;
    }

    setState(() {
      isRequesting = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 40,
          children: [
            Text(
              'Login to ToneUp',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontFamily: 'Righteous',
                color: theme.colorScheme.primary,
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
    );
  }
}
