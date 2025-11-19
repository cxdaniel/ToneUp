import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/services/oauth_service.dart';

class AccountService {
  static final AccountService _instance = AccountService._internal();
  factory AccountService() => _instance;
  AccountService._internal();

  final _supabase = Supabase.instance.client;
  final _oauthService = OAuthService();

  /// 获取当前用户的所有已连接账号
  Future<Map<String, dynamic>> getConnectedAccounts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('用户未登录');

    // 从 user.identities 获取已连接的身份信息
    final identities = user.identities ?? [];

    final Map<String, dynamic> connections = {
      'email': null,
      'apple': null,
      'google': null,
      'primary': null,
    };

    // 解析身份信息，同时保存完整的 UserIdentity 对象
    for (final identity in identities) {
      final provider = identity.provider;
      final identityData = identity.identityData;

      if (provider == 'email') {
        connections['email'] = {
          'identity': identity, // 保存完整对象
          'id': identity.id,
          'email': identityData?['email'] ?? user.email,
          'verified': user.emailConfirmedAt != null,
          'isPrimary': user.appMetadata['provider'] == 'email',
        };
      } else if (provider == 'apple') {
        connections['apple'] = {
          'identity': identity, // 保存完整对象
          'id': identity.id,
          'email': identityData?['email'],
          'name': identityData?['full_name'],
          'isPrimary': user.appMetadata['provider'] == 'apple',
        };
      } else if (provider == 'google') {
        connections['google'] = {
          'identity': identity, // 保存完整对象
          'id': identity.id,
          'email': identityData?['email'],
          'name': identityData?['name'],
          'picture': identityData?['picture'],
          'isPrimary': user.appMetadata['provider'] == 'google',
        };
      }
    }

    // 确定主登录方式
    connections['primary'] = user.appMetadata['provider'] ?? 'email';

    return connections;
  }

  /// 绑定 Apple 账号
  Future<bool> linkAppleAccount() async {
    // TODO: 这里要解决绑定的账号已有账号的情况
    try {
      debugPrint('🍎 开始绑定 Apple 账号');

      final success = await _oauthService.signInWithProvider(
        OAuthProvider.apple,
        timeout: const Duration(seconds: 60),
      );

      if (success) {
        debugPrint('✅ Apple 账号绑定成功');
        return true;
      } else {
        debugPrint('❌ Apple 账号绑定失败或取消');
        return false;
      }
    } catch (e) {
      debugPrint('❌ 绑定 Apple 账号异常: $e');
      rethrow;
    }
  }

  /// 绑定 Google 账号
  Future<bool> linkGoogleAccount() async {
    try {
      debugPrint('🔍 开始绑定 Google 账号');

      final success = await _oauthService.signInWithProvider(
        OAuthProvider.google,
        timeout: const Duration(seconds: 60),
      );

      if (success) {
        debugPrint('✅ Google 账号绑定成功');
        return true;
      } else {
        debugPrint('❌ Google 账号绑定失败或取消');
        return false;
      }
    } catch (e) {
      debugPrint('❌ 绑定 Google 账号异常: $e');
      rethrow;
    }
  }

  /// 解绑账号
  Future<bool> unlinkAccount(UserIdentity identity) async {
    try {
      debugPrint('🔓 开始解绑账号: ${identity.provider}');

      // 检查是否至少保留一个登录方式
      final connections = await getConnectedAccounts();
      int connectedCount = 0;
      if (connections['email'] != null) connectedCount++;
      if (connections['apple'] != null) connectedCount++;
      if (connections['google'] != null) connectedCount++;

      if (connectedCount <= 1) {
        throw Exception('至少需要保留一种登录方式');
      }

      // 调用 Supabase API 解绑
      await _supabase.auth.unlinkIdentity(identity);

      debugPrint('✅ 账号解绑成功');
      return true;
    } catch (e) {
      debugPrint('❌ 解绑账号异常: $e');
      rethrow;
    }
  }

  /// 更新邮箱（需要验证）
  Future<bool> updateEmail(String newEmail) async {
    try {
      debugPrint('📧 开始更新邮箱: $newEmail');

      // 验证邮箱格式
      final emailRegExp = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      if (!emailRegExp.hasMatch(newEmail)) {
        throw Exception('邮箱格式不正确');
      }

      // 发送验证邮件
      await _supabase.auth.updateUser(UserAttributes(email: newEmail));

      debugPrint('✅ 验证邮件已发送到: $newEmail');
      return true;
    } catch (e) {
      debugPrint('❌ 更新邮箱异常: $e');
      rethrow;
    }
  }

  /// 更改密码
  Future<bool> changePassword(String newPassword) async {
    try {
      debugPrint('🔐 开始更改密码');

      // 验证密码长度
      if (newPassword.length < 6) {
        throw Exception('密码至少需要6个字符');
      }

      await _supabase.auth.updateUser(UserAttributes(password: newPassword));

      debugPrint('✅ 密码更改成功');
      return true;
    } catch (e) {
      debugPrint('❌ 更改密码异常: $e');
      rethrow;
    }
  }

  /// 发送密码重置邮件
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      debugPrint('📧 发送密码重置邮件到: $email');

      await _supabase.auth.resetPasswordForEmail(email);

      debugPrint('✅ 密码重置邮件已发送');
      return true;
    } catch (e) {
      debugPrint('❌ 发送密码重置邮件异常: $e');
      rethrow;
    }
  }

  /// 删除账号（危险操作）
  Future<bool> deleteAccount() async {
    try {
      debugPrint('⚠️ 开始删除账号');

      // 这里需要调用 Edge Function 或 Admin API
      // 因为普通用户无法直接删除自己的账号
      final response = await _supabase.functions.invoke(
        'delete_user_account',
        body: {},
      );

      if (response.status == 200) {
        debugPrint('✅ 账号删除成功');
        return true;
      } else {
        throw Exception('删除账号失败');
      }
    } catch (e) {
      debugPrint('❌ 删除账号异常: $e');
      rethrow;
    }
  }
}
