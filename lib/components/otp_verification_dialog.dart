import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// OTP 验证对话框
///
/// 特性:
/// - 不可通过点击背景关闭 (barrierDismissible: false)
/// - 不可通过返回键关闭 (WillPopScope)
/// - 显式的"取消"按钮供用户主动退出
/// - 防止用户切换到邮件查看验证码后无法回到输入界面
class OtpVerificationDialog extends StatefulWidget {
  final String title;
  final String description;
  final Future<(bool, String?)> Function(String otpCode) onVerify;
  final VoidCallback? onResend;

  const OtpVerificationDialog({
    super.key,
    required this.title,
    required this.description,
    required this.onVerify,
    this.onResend,
  });

  /// 显示 OTP 验证对话框
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String description,
    required Future<(bool, String?)> Function(String otpCode) onVerify,
    VoidCallback? onResend,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // 不可点击背景关闭
      builder: (context) => OtpVerificationDialog(
        title: title,
        description: description,
        onVerify: onVerify,
        onResend: onResend,
      ),
    );
  }

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final (success, message) = await widget.onVerify(
        _otpController.text.trim(),
      );
      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage =
              message ?? 'Verification failed. Please check the code.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  void _handleCancel() {
    if (_isVerifying) return; // 验证中不允许取消
    Navigator.of(context).pop(false);
  }

  void _handleResend() {
    if (_isVerifying) return;
    widget.onResend?.call();
    // 使用 ScaffoldMessenger 的根 context，确保在 Dialog 上方显示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Verification code sent!'),
        behavior: SnackBarBehavior.floating, // 浮动模式，显示在更高层级
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_isVerifying, // 验证中不允许返回
      child: AlertDialog(
        title: Text(
          widget.title,
          style: theme.textTheme.titleMedium!.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.description, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: _otpController,
                decoration: InputDecoration(
                  labelText: 'Verification Code',
                  hintText: 'Enter 6-digit code',
                  border: const OutlineInputBorder(),
                  errorText: _errorMessage,
                  errorMaxLines: 3,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                autofocus: true,
                enabled: !_isVerifying,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter verification code';
                  }
                  if (value.length != 6) {
                    return 'Code must be 6 digits';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _handleVerify(),
              ),
              if (widget.onResend != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isVerifying ? null : _handleResend,
                    child: const Text('Resend Code'),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isVerifying ? null : _handleCancel,
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _isVerifying ? null : _handleVerify,
            child: _isVerifying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Verify'),
          ),
        ],
      ),
    );
  }
}
