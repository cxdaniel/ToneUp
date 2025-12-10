import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/components/components.dart';
import 'package:toneup_app/components/feedback_button.dart';
import 'package:toneup_app/main.dart';
import 'package:toneup_app/providers/account_settings_provider.dart';
import 'package:toneup_app/routes.dart';

class AccountSettings extends StatefulWidget {
  const AccountSettings({super.key});

  @override
  State<StatefulWidget> createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings> {
  late ThemeData theme;
  late AccountSettingsProvider accountProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountSettingsProvider>().loadConnectedAccounts();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Account',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
      body: Consumer<AccountSettingsProvider>(
        builder: (context, provider, child) {
          accountProvider = provider;

          if (provider.isLoading) {
            LoadingOverlay.show(
              context,
              label: 'Waiting for authentication...',
            );
          } else {
            LoadingOverlay.hide();
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                spacing: 16,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Connected Accounts'),
                  _buildConnectedAccountsSection(),
                  SizedBox(height: 0),
                  _buildSectionTitle('Security'),
                  _buildSecuritySection(),
                  SizedBox(height: 0),
                  _buildSectionTitle('Danger Zone'),
                  _buildDangerZoneSection(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 章节标题
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium!.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// 已连接账号部分
  Widget _buildConnectedAccountsSection() {
    return Column(
      spacing: 12,
      children: [
        _buildEmailAccountCard(),
        _buildAppleAccountCard(),
        _buildGoogleAccountCard(),
      ],
    );
  }

  /// 邮箱账号卡片
  Widget _buildEmailAccountCard() {
    final emailData = accountProvider.connectedAccounts['email'];
    final isConnected = emailData != null;
    final isPrimary = emailData?['isPrimary'] == true;
    final email = emailData?['email'] ?? '';
    final isVerified = emailData?['verified'] == true;

    return _buildAccountCard(
      icon: Icons.email_outlined,
      iconColor: theme.colorScheme.primary,
      title: 'Email',
      subtitle: isConnected ? email : 'Not connected',
      isConnected: isConnected,
      isPrimary: isPrimary,
      isVerified: isVerified,
      onTap: isConnected ? _showEmailOptions : null,
      onConnect: isConnected ? null : _showAddEmailDialog,
    );
  }

  /// Apple 账号卡片
  Widget _buildAppleAccountCard() {
    final appleData = accountProvider.connectedAccounts['apple'];
    final isConnected = appleData != null;
    final isPrimary = appleData?['isPrimary'] == true;
    final email = appleData?['email'] ?? 'Apple Account';

    return _buildAccountCard(
      iconWidget: SvgPicture.asset(
        'assets/images/login_icon_apple.svg',
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
          theme.colorScheme.onSurface,
          BlendMode.srcIn,
        ),
      ),
      title: 'Apple',
      subtitle: isConnected ? email : 'Not connected',
      isConnected: isConnected,
      isPrimary: isPrimary,
      onTap: isConnected
          ? () => _showUnlinkConfirmation('Apple', appleData['identity'])
          : null,
      onConnect: isConnected ? null : _linkAppleAccount,
    );
  }

  /// Google 账号卡片
  Widget _buildGoogleAccountCard() {
    final googleData = accountProvider.connectedAccounts['google'];
    final isConnected = googleData != null;
    final isPrimary = googleData?['isPrimary'] == true;
    final email = googleData?['email'] ?? 'Google Account';

    return _buildAccountCard(
      iconWidget: SvgPicture.asset(
        'assets/images/login_icon_google.svg',
        width: 24,
        height: 24,
      ),
      title: 'Google',
      subtitle: isConnected ? email : 'Not connected',
      isConnected: isConnected,
      isPrimary: isPrimary,
      onTap: isConnected
          ? () => _showUnlinkConfirmation('Google', googleData['identity'])
          : null,
      onConnect: isConnected ? null : _linkGoogleAccount,
    );
  }

  /// 通用账号卡片
  Widget _buildAccountCard({
    IconData? icon,
    Widget? iconWidget,
    Color? iconColor,
    required String title,
    required String subtitle,
    required bool isConnected,
    bool isPrimary = false,
    bool isVerified = false,
    VoidCallback? onTap,
    VoidCallback? onConnect,
  }) {
    return FeedbackButton(
      borderRadius: BorderRadius.circular(16),
      onTap: isConnected ? onTap : onConnect,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: isConnected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            // 图标
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child:
                    iconWidget ??
                    Icon(
                      icon ?? Icons.link,
                      color: iconColor ?? theme.colorScheme.primary,
                      size: 24,
                    ),
              ),
            ),
            const SizedBox(width: 16),

            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium!.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isPrimary) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Primary',
                            style: theme.textTheme.labelSmall!.copyWith(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                      if (title == 'Email' && isConnected && !isVerified) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Unverified',
                            style: theme.textTheme.labelSmall!.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // 操作按钮
            Icon(
              isConnected ? Icons.chevron_right : Icons.add_circle_outline,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  /// 安全部分
  Widget _buildSecuritySection() {
    final hasEmail = accountProvider.hasEmail;

    return Column(
      spacing: 12,
      children: [
        if (hasEmail)
          _buildListTile(
            icon: Icons.lock_outline,
            label: 'Change Password',
            onTap: _showChangePasswordDialog,
          ),
      ],
    );
  }

  /// 危险区域
  Widget _buildDangerZoneSection() {
    return Column(
      spacing: 12,
      children: [
        _buildListTile(
          icon: Icons.delete_forever_outlined,
          label: 'Delete Account',
          labelColor: theme.colorScheme.error,
          iconColor: theme.colorScheme.error,
          onTap: _showDeleteAccountConfirmation,
        ),
      ],
    );
  }

  /// 通用列表项
  Widget _buildListTile({
    required IconData icon,
    required String label,
    String? subtitle,
    Color? labelColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return FeedbackButton(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: theme.colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleMedium!.copyWith(
                      color: labelColor ?? theme.colorScheme.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  // ========== 交互方法 ==========

  /// 显示邮箱选项
  void _showEmailOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Change Email'),
                onTap: () {
                  Navigator.pop(context);
                  _showChangeEmailDialog();
                },
              ),
              ListTile(
                leading: Icon(Icons.link_off),
                title: Text('Unlink Email'),
                enabled:
                    !accountProvider.connectedAccounts['email']['isPrimary'],
                onTap: () {
                  Navigator.pop(context);
                  final emailData = accountProvider.connectedAccounts['email'];
                  _showUnlinkConfirmation('Email', emailData['identity']);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 添加邮箱对话框(使用 OTP 验证)
  Future<void> _showAddEmailDialog() async {
    // 步骤 1: 获取用户输入的新邮箱地址
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Email & Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password (min 6 characters)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              Text(
                'After verification, you will receive a confirmation link in your new email. Click it to complete the setup.',
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final email = emailController.text.trim();
                final password = passwordController.text;
                if (email.isEmpty || password.length < 6) {
                  showOverlayMessage(
                    context,
                    'Please fill all fields',
                    isError: true,
                  );
                  return;
                }
                Navigator.pop(context, {'email': email, 'password': password});
              },
              child: const Text('Next'),
            ),
          ],
        );
      },
    );

    if (result == null || !mounted) return;
    final newEmail = result['email']!;
    final password = result['password']!;

    // 步骤 2: 发送当前账号的重认证 OTP
    final currentOtpSent = await accountProvider.sendReauthenticationOtp();
    if (!currentOtpSent || !mounted) {
      showGlobalSnackBar(
        accountProvider.errorMessage ?? 'Failed to send verification code',
        isError: true,
      );
      return;
    }

    // 步骤 3: 验证当前账号的 OTP 并完成添加
    String? resultMessage;
    final verified = await OtpVerificationDialog.show(
      context: context,
      title: 'Verify Current Account',
      description:
          'Enter the 6-digit code sent to your current account. '
          'You can switch to your email app and come back here.',
      onVerify: (otpCode) async {
        final (success, message) = await accountProvider.addEmail(
          newEmail,
          password,
          otpCode,
        );
        resultMessage = message;
        return (success, message);
      },
      onResend: () => accountProvider.sendReauthenticationOtp(),
    );

    if (!mounted) return;
    if (verified == true) {
      showGlobalSnackBar(
        resultMessage ??
            'Email add request sent. Please check your new email inbox for confirmation link.',
        isError: false,
      );
    } else if (verified == false) {
      showGlobalSnackBar(resultMessage ?? 'Failed to add email', isError: true);
    }
  }

  /// 更改邮箱对话框(使用三步OTP验证)
  Future<void> _showChangeEmailDialog() async {
    // 步骤 1: 获取用户输入的新邮箱地址
    final emailController = TextEditingController();

    final newEmail = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'New Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              Text(
                'After verification, you will receive a confirmation link in your new email. Click it to complete the change.',
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final email = emailController.text.trim();
                if (email.isEmpty) return;
                Navigator.pop(context, email);
              },
              child: const Text('Next'),
            ),
          ],
        );
      },
    );

    if (newEmail == null || !mounted) return;

    // 步骤 2: 发送当前邮箱的重认证 OTP
    final currentOtpSent = await accountProvider.sendReauthenticationOtp();
    if (!currentOtpSent || !mounted) {
      showGlobalSnackBar(
        accountProvider.errorMessage ?? 'Failed to send verification code',
        isError: true,
      );
      return;
    }

    // 步骤 3: 验证当前邮箱的 OTP 并完成更新
    String? resultMessage;
    final verified = await OtpVerificationDialog.show(
      context: context,
      title: 'Verify Current Email',
      description:
          'Enter the 6-digit code sent to your current email. '
          'You can switch to your email app and come back here.',
      onVerify: (otpCode) async {
        final (success, message) = await accountProvider.updateEmail(
          newEmail,
          otpCode,
        );
        resultMessage = message;
        return (success, message);
      },
      onResend: () => accountProvider.sendReauthenticationOtp(),
    );

    if (!mounted) return;
    if (verified == true) {
      showGlobalSnackBar(
        resultMessage ??
            'Email update request sent. Please check your new email inbox for confirmation link.',
        isError: false,
      );
    } else if (verified == false) {
      showGlobalSnackBar(
        resultMessage ?? 'Failed to update email',
        isError: true,
      );
    }
  }

  /// 更改密码对话框(使用 OTP 验证)
  Future<void> _showChangePasswordDialog() async {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final passwords = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Change Password',
            style: theme.textTheme.titleMedium!.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPasswordController,
                decoration: InputDecoration(
                  labelText: 'New Password (min 6 characters)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true, // 隐藏输入
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              Text(
                'A verification code will be sent to your email.',
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final newPassword = newPasswordController.text;
                final confirmPassword = confirmPasswordController.text;

                if (newPassword != confirmPassword) {
                  showOverlayMessage(
                    context,
                    'Passwords do not match',
                    isError: true,
                  );
                  return;
                }
                if (newPassword.length < 6) {
                  showOverlayMessage(
                    context,
                    'Password must be at least 6 characters',
                    isError: true,
                  );
                  return;
                }

                Navigator.pop(context, {'password': newPassword});
              },
              child: const Text('Send Code'),
            ),
          ],
        );
      },
    );

    if (passwords == null || !mounted) return;

    // 发送 OTP
    final otpSent = await accountProvider.sendReauthenticationOtp();
    if (!otpSent || !mounted) {
      showGlobalSnackBar(
        accountProvider.errorMessage ?? 'Failed to send verification code',
        isError: true,
      );
      return;
    }

    // 显示 OTP 验证对话框
    final verified = await OtpVerificationDialog.show(
      context: context,
      title: 'Verify Password Change',
      description:
          'Enter the 6-digit code sent to your email. '
          'You can switch to your email app and return here.',
      onVerify: (otpCode) =>
          accountProvider.changePassword(passwords['password']!, otpCode),
      onResend: () => accountProvider.sendReauthenticationOtp(),
    );

    if (!mounted) return;
    if (verified == true) {
      showGlobalSnackBar('Password changed successfully', isError: false);
    }
  }

  /// 绑定 Apple 账号
  Future<void> _linkAppleAccount() async {
    final success = await accountProvider.linkApple();
    if (success) {
      showGlobalSnackBar('Apple account linked successfully', isError: false);
    } else if (accountProvider.errorMessage != null) {
      showGlobalSnackBar(accountProvider.errorMessage!, isError: true);
    }
    // 用户取消不显示任何提示
  }

  /// 绑定 Google 账号
  Future<void> _linkGoogleAccount() async {
    final success = await accountProvider.linkGoogle();
    if (success) {
      showGlobalSnackBar('Google account linked successfully', isError: false);
    } else if (accountProvider.errorMessage != null) {
      showGlobalSnackBar(accountProvider.errorMessage!, isError: true);
    }
    // 用户取消不显示任何提示
  }

  /// 显示解绑确认
  void _showUnlinkConfirmation(String accountType, UserIdentity identityId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Unlink $accountType'),
          content: Text(
            'Are you sure you want to unlink your $accountType account? '
            'You can always reconnect it later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              onPressed: () async {
                Navigator.pop(context);
                final success = await accountProvider.unlinkAccount(
                  identityId,
                  accountType,
                );
                if (success) {
                  showGlobalSnackBar(
                    '$accountType account unlinked',
                    isError: false,
                  );
                } else {
                  showGlobalSnackBar(
                    accountProvider.errorMessage ??
                        'Failed to unlink $accountType account',
                    isError: true,
                  );
                }
              },
              child: Text('Unlink'),
            ),
          ],
        );
      },
    );
  }

  /// 显示删除账号确认(使用 OTP 验证)
  Future<void> _showDeleteAccountConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Delete Account',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action cannot be undone. All your data will be permanently deleted.',
              ),
              const SizedBox(height: 12),
              Text(
                'A verification code will be sent to confirm this action.',
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send Code'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    // 发送 OTP
    final otpSent = await accountProvider.sendReauthenticationOtp();
    if (!otpSent || !mounted) {
      showGlobalSnackBar(
        accountProvider.errorMessage ?? 'Failed to send verification code',
        isError: true,
      );
      return;
    }

    // 显示 OTP 验证对话框
    final verified = await OtpVerificationDialog.show(
      context: context,
      title: 'Verify Account Deletion',
      description:
          'Enter the 6-digit code sent to your email to confirm deletion. '
          'You can check your email and return here.',
      onVerify: (otpCode) => accountProvider.deleteAccount(otpCode),
      onResend: () => accountProvider.sendReauthenticationOtp(),
    );

    if (!mounted) return;
    if (verified == true) {
      // 返回登录页
      context.go(AppRoutes.LOGIN);
    }
  }
}
