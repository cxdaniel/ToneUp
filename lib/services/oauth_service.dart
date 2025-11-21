import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class OAuthService {
  static final OAuthService _instance = OAuthService._internal();
  factory OAuthService() => _instance;
  OAuthService._internal();
  // 1. 添加绑定状态标记
  bool _isLinkingInProgress = false;
  bool get isLinkingInProgress => _isLinkingInProgress;

  final _supabase = Supabase.instance.client;
  Completer<bool>? _authCompleter;
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _timeoutTimer;
  LaunchMode launchMode = LaunchMode.externalApplication;
  String callbackUri = kIsWeb
      ? '${Uri.base.origin}/auth/callback/'
      : 'io.supabase.toneup://login-callback/';

  /// 检查当前是否有活跃的认证流程
  bool get isAuthenticating =>
      _authCompleter != null && !_authCompleter!.isCompleted;

  /// 启动 OAuth 登录流程
  ///
  /// [provider] - OAuth 提供商 (apple, google 等)
  /// [launchMode] - 启动模式，默认使用外部浏览器
  /// [timeout] - 超时时间，默认 60 秒
  ///
  /// 返回 true 表示登录成功，false 表示失败或取消
  Future<bool> signInWithProvider(
    OAuthProvider provider, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    // 如果有正在进行的认证，先取消
    if (_authCompleter != null && !_authCompleter!.isCompleted) {
      debugPrint('⚠️ 检测到正在进行的认证，先取消');
      cancelAuth();
    }
    // 创建新的完成器
    _authCompleter = Completer<bool>();
    // 监听认证状态变化
    // _setupAuthListener();
    // 设置超时定时器
    _timeoutTimer = Timer(timeout, () {
      debugPrint('⏱️ OAuth 认证超时 (${timeout.inSeconds}秒)');
      if (_authCompleter != null && !_authCompleter!.isCompleted) {
        _authCompleter!.complete(false);
        _cleanup();
      }
    });

    try {
      debugPrint('🚀 开始 ${provider.name} OAuth 登录流程');
      // 发起 OAuth 请求
      await _supabase.auth.signInWithOAuth(
        provider,
        redirectTo: callbackUri,
        authScreenLaunchMode: launchMode,
      );
      debugPrint('⏳ 等待认证完成...');
      _authCompleter!.complete(true);
      // 等待认证完成
      final result = await _authCompleter!.future;
      debugPrint(result ? '✅ OAuth 登录成功' : '❌ OAuth 登录失败');
      return result;
    } catch (e) {
      debugPrint('❌ OAuth 错误: $e');
      // 完成 completer（如果还未完成）
      if (_authCompleter != null && !_authCompleter!.isCompleted) {
        _authCompleter!.complete(false);
      }
      _cleanup();
      rethrow;
    }
  }

  /// 设置认证状态监听器
  // ignore: unused_element
  void _setupAuthListener() {
    // 取消之前的监听
    _authSubscription?.cancel();

    // 创建新的监听
    _authSubscription = _supabase.auth.onAuthStateChange.listen(
      (data) {
        final event = data.event;
        debugPrint('📡 Auth event: $event');

        if (event == AuthChangeEvent.signedIn) {
          debugPrint('✅ 检测到登录成功事件');
          // 验证 session 是否真的存在
          final session = _supabase.auth.currentSession;
          if (session != null) {
            debugPrint('✅ Session 已建立: ${session.user.email}');
            if (_authCompleter != null && !_authCompleter!.isCompleted) {
              // 添加小延迟确保状态完全同步
              Future.delayed(const Duration(milliseconds: 300), () {
                if (_authCompleter != null && !_authCompleter!.isCompleted) {
                  _authCompleter!.complete(true);
                  _cleanup();
                }
              });
            }
          } else {
            debugPrint('⚠️ 登录事件触发但 session 为 null');
          }
        } else if (event == AuthChangeEvent.signedOut) {
          debugPrint('🚪 检测到登出事件');
          if (_authCompleter != null && !_authCompleter!.isCompleted) {
            _authCompleter!.complete(false);
            _cleanup();
          }
        }
      },
      onError: (error) {
        // 捕获绑定过程中的错误
        debugPrint('❌ Linking: Auth error: $error');

        if (_authCompleter != null && !_authCompleter!.isCompleted) {
          // 处理不同类型的错误
          if (error is AuthException) {
            final code = error.statusCode ?? '';
            final message = error.message;

            debugPrint('❌ Auth错误码: $code');
            debugPrint('❌ Auth错误信息: $message');

            if (code == 'identity_already_exists' ||
                message.toLowerCase().contains('already linked')) {
              _authCompleter!.completeError(Exception('该账号已被其他用户绑定'));
            } else if (message.toLowerCase().contains('cancelled')) {
              _authCompleter!.completeError(Exception('用户取消了授权'));
            } else {
              _authCompleter!.completeError(Exception('绑定失败: $message'));
            }
          } else {
            _authCompleter!.completeError(error);
          }

          cancelAuth();
        }
      },
      onDone: () {},
    );
  }

  /// 取消当前认证流程
  void cancelAuth() {
    debugPrint('🛑 取消 OAuth 认证');
    if (_authCompleter != null && !_authCompleter!.isCompleted) {
      _authCompleter!.complete(false);
    }
    _cleanup();
  }

  /// 清理资源
  void _cleanup() {
    _authSubscription?.cancel();
    _authSubscription = null;

    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    _authCompleter = null;
    _isLinkingInProgress = false;
  }

  /// 释放所有资源
  void dispose() {
    debugPrint('🗑️ OAuthService dispose');
    cancelAuth();
  }

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
  ///
  /// 使用 Supabase 的 linkIdentity API 进行账号绑定
  /// 注意:这会打开浏览器进行 OAuth 认证,需要等待用户完成
  Future<bool> linkAppleAccount() async {
    try {
      debugPrint('🍎 开始绑定 Apple 账号');

      // 检查用户是否已登录
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('请先登录');
      }

      // 检查是否已经绑定了 Apple 账号
      final connections = await getConnectedAccounts();
      if (connections['apple'] != null) {
        throw Exception('已绑定 Apple 账号');
      }

      _isLinkingInProgress = true;
      _authCompleter = Completer<bool>();
      // _setupAuthListener();
      // 设置超时定时器
      _timeoutTimer = Timer(const Duration(seconds: 60), () {
        debugPrint('⏱️ OAuth 认证超时 ');
        if (_authCompleter != null && !_authCompleter!.isCompleted) {
          _authCompleter!.complete(false);
          _cleanup();
        }
      });

      // 使用 linkIdentity 进行账号绑定
      // 这会打开浏览器让用户进行 Apple 登录
      await _supabase.auth.linkIdentity(
        OAuthProvider.apple,
        authScreenLaunchMode: launchMode,
        redirectTo: '$callbackUri?type=linking',
      );

      debugPrint('✅ Apple 账号绑定请求已发送,等待用户完成授权');

      _authCompleter?.complete(true);
      // linkIdentity 返回 bool 表示请求是否成功发送
      // 实际绑定结果需要等待 OAuth 回调和 auth state change 事件
      final response = await _authCompleter!.future;
      return response;
    } catch (e) {
      debugPrint('❌ 绑定 Apple 账号异常: $e');
      _cleanup();
      rethrow;
    }
  }

  /// 绑定 Google 账号
  ///
  /// 使用 Supabase 的 linkIdentity API 进行账号绑定
  /// 注意:这会打开浏览器进行 OAuth 认证,需要等待用户完成
  Future<bool> linkGoogleAccount() async {
    try {
      debugPrint('🔍 开始绑定 Google 账号');

      // 检查用户是否已登录
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('请先登录');
      }

      // 检查是否已经绑定了 Google 账号
      final connections = await getConnectedAccounts();
      if (connections['google'] != null) {
        throw Exception('已绑定 Google 账号');
      }
      _isLinkingInProgress = true;
      _authCompleter = Completer<bool>();
      // _setupAuthListener();
      // 设置超时定时器
      _timeoutTimer = Timer(const Duration(seconds: 60), () {
        debugPrint('⏱️ OAuth 认证超时 ');
        if (_authCompleter != null && !_authCompleter!.isCompleted) {
          _authCompleter!.complete(false);
          _cleanup();
        }
      });
      // 使用 linkIdentity 进行账号绑定
      // 这会打开浏览器让用户进行 Google 登录
      await _supabase.auth.linkIdentity(
        OAuthProvider.google,
        authScreenLaunchMode: launchMode,
        redirectTo: '$callbackUri?type=linking',
      );

      debugPrint('✅ Google 账号绑定请求已发送,等待用户完成授权');
      _authCompleter!.complete(true);
      // linkIdentity 返回 bool 表示请求是否成功发送
      // 实际绑定结果需要等待 OAuth 回调和 auth state change 事件
      final response = await _authCompleter!.future;
      return response;
    } catch (e) {
      debugPrint('❌ 绑定 Google 账号异常: $e');
      _cleanup();
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

  /// 更新邮箱(需要验证)
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

  /// 删除账号(危险操作)
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
