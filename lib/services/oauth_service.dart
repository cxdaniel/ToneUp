import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/services/native_auth_service.dart';
import 'dart:async';

class OAuthService {
  static final OAuthService _instance = OAuthService._internal();
  factory OAuthService() => _instance;
  OAuthService._internal();

  final _supabase = Supabase.instance.client;
  final _nativeAuth = NativeAuthService();
  Completer<bool>? _authCompleter;
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _timeoutTimer;
  // Web 端使用 popup 模式,移动端使用外部浏览器
  LaunchMode get launchMode =>
      kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication;
  String loginCallbackUri = kIsWeb
      ? '${Uri.base.origin}/auth/callback/login/'
      : 'io.supabase.toneup://login-callback/';
  String linkingCallbackUri = kIsWeb
      ? '${Uri.base.origin}/linking-callback/'
      : 'io.supabase.toneup://linking-callback/';
  String emailChangeCallbackUri = kIsWeb
      ? '${Uri.base.origin}/email-change-callback/'
      : 'io.supabase.toneup://email-change-callback/';

  /// 检查当前是否有活跃的认证流程
  bool get isAuthenticating =>
      _authCompleter != null && !_authCompleter!.isCompleted;

  /// 启动 OAuth 登录流程
  /// [provider] - OAuth 提供商 (apple, google 等)
  /// [useNative] - 是否使用原生登录（移动端默认 true，Web 端自动为 false）
  /// [timeout] - 超时时间，默认 60 秒
  /// 返回 true 表示登录成功，false 表示失败或取消
  Future<bool> signInWithProvider(
    OAuthProvider provider, {
    bool? useNative,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    // 如果有正在进行的认证，先取消
    if (_authCompleter != null && !_authCompleter!.isCompleted) {
      debugPrint('⚠️ 检测到正在进行的认证，先取消');
      cancelAuth();
    }

    // 移动端默认使用原生登录（体验更好）
    final shouldUseNative = useNative ?? !kIsWeb;

    // 移动端使用原生登录
    if (shouldUseNative && !kIsWeb) {
      try {
        AuthResponse? response;
        if (provider == OAuthProvider.apple) {
          debugPrint('🍎 使用原生 Apple 登录');
          response = await _nativeAuth.signInWithApple();
        } else if (provider == OAuthProvider.google) {
          debugPrint('🔍 使用原生 Google 登录 (v7.x)');
          response = await _nativeAuth.signInWithGoogle();
        }

        // 成功或用户取消,直接返回
        if (response != null && response.user != null) {
          debugPrint('✅ 原生登录成功');
          return true;
        } else {
          debugPrint('⚠️ 用户取消了原生登录');
          return false; // 用户取消,不再尝试 OAuth
        }
      } catch (e) {
        // 只有在特定错误时才降级到 OAuth
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('不支持') || errorMsg.contains('not available')) {
          debugPrint('⚠️ 原生登录不支持,降级使用 OAuth: $e');
          // 继续执行下面的 OAuth 流程
        } else {
          // 其他错误直接抛出,不降级
          debugPrint('❌ 原生登录失败: $e');
          rethrow;
        }
      }
    } // Web 端或原生不支持时,使用 OAuth 流程
    return _signInWithOAuth(provider, timeout);
  }

  /// OAuth 登录流程（Web 端或降级方案）
  Future<bool> _signInWithOAuth(
    OAuthProvider provider,
    Duration timeout,
  ) async {
    // 创建新的完成器
    _authCompleter = Completer<bool>();
    // 设置超时定时器
    _timeoutTimer = Timer(timeout, () {
      debugPrint('⏱️ OAuth 认证超时 (${timeout.inSeconds}秒)');
      if (_authCompleter != null && !_authCompleter!.isCompleted) {
        _authCompleter!.complete(false);
        _cleanup();
      }
    });

    try {
      debugPrint(
        '🚀 开始 ${provider.name} OAuth 登录流程（${kIsWeb ? "Web 端" : "移动端"}）',
      );
      // 发起 OAuth 请求
      await _supabase.auth.signInWithOAuth(
        provider,
        redirectTo: loginCallbackUri,
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
      (data) async {
        final event = data.event;
        debugPrint('📡 Auth event: $event');

        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.userUpdated) {
          debugPrint('✅ 检测到登录成功事件');
          final session = _supabase.auth.currentSession;
          if (session != null) {
            if (_authCompleter != null && !_authCompleter!.isCompleted) {
              await _supabase.auth.refreshSession();
              debugPrint('✅ 绑定成功，用户信息已刷新');
              _authCompleter!.complete(true);
              _cleanup();
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
        debugPrint('❌ Linking: Auth error: $error');
        if (_authCompleter != null && !_authCompleter!.isCompleted) {
          if (error is AuthException) {
            final code = error.statusCode ?? '';
            final message = error.message;
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
  }

  /// 释放所有资源
  void dispose() {
    debugPrint('🗑️ OAuthService dispose');
    cancelAuth();
    _nativeAuth.dispose();
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

  /// Web端绑定 Apple 账号
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

      _authCompleter = Completer<bool>();
      _setupAuthListener();
      // 设置超时定时器
      _timeoutTimer = Timer(const Duration(seconds: 60), () {
        debugPrint('⏱️ OAuth 认证超时 ');
        if (_authCompleter != null && !_authCompleter!.isCompleted) {
          _authCompleter!.complete(false);
          _cleanup();
        }
      });

      // 使用 linkIdentity 进行 OAuth 账号绑定
      // 注意: 此方法需要打开浏览器
      // 移动端优先使用 NativeAuthService.linkIdentityWithIdToken (原生体验)
      await _supabase.auth.linkIdentity(
        OAuthProvider.apple,
        authScreenLaunchMode: launchMode,
        redirectTo: linkingCallbackUri,
      );

      debugPrint('✅ Apple 账号绑定请求已发送,等待用户完成授权');

      // 等待绑定结果
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
  /// 注意: 由于 Supabase 限制,账号绑定仍需使用 OAuth 流程
  /// 移动端会打开外部浏览器,Web 端会打开 popup
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
      _authCompleter = Completer<bool>();
      _setupAuthListener();
      // 设置超时定时器
      _timeoutTimer = Timer(const Duration(seconds: 60), () {
        debugPrint('⏱️ OAuth 认证超时 ');
        if (_authCompleter != null && !_authCompleter!.isCompleted) {
          _authCompleter!.complete(false);
          _cleanup();
        }
      });
      // 使用 linkIdentity 进行 OAuth 账号绑定
      // 注意: 此方法需要打开浏览器
      // 移动端优先使用 NativeAuthService.linkIdentityWithIdToken (原生体验)
      await _supabase.auth.linkIdentity(
        OAuthProvider.google,
        authScreenLaunchMode: launchMode,
        redirectTo: linkingCallbackUri,
      );

      debugPrint('✅ Google 账号绑定请求已发送,等待用户完成授权');
      // 等待绑定结果
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
      // await _supabase.auth.reauthenticate();
      await _supabase.auth.refreshSession();
      // await _supabase.auth.getUser();

      debugPrint('✅ 账号解绑成功');
      return true;
    } catch (e) {
      debugPrint('❌ 解绑账号异常: $e');
      rethrow;
    }
  }

  // ============================================================================
  // 敏感操作 OTP 重认证流程
  // ============================================================================

  /// 发送重认证 OTP
  ///
  /// 用于敏感操作(修改密码、邮箱、删除账号)前的身份验证
  /// OTP 会发送到用户当前的 email 或 phone
  /// 注意:需要用户已登录且24小时内未重新登录时才会触发
  Future<void> sendReauthenticationOtp() async {
    try {
      debugPrint('🔐 发送重认证 OTP');
      await _supabase.auth.reauthenticate();
      debugPrint('✅ 重认证 OTP 已发送');
    } catch (e) {
      debugPrint('❌ 发送重认证 OTP 失败: $e');
      rethrow;
    }
  }

  /// 验证重认证 OTP (简化版)
  ///
  /// reauthenticate() 发送的 OTP 不需要单独验证
  /// 它会在 updateUser(nonce: otpCode) 时自动验证
  /// 这个方法只是保存 OTP 码供后续使用
  Future<bool> verifyReauthenticationOtp(String otpCode) async {
    // reauthenticate 的 OTP 不需要预先验证
    // 它会在后续的 updateUser 调用中作为 nonce 参数自动验证
    debugPrint('✅ 重认证 OTP 已接收，将在更新时验证: ${otpCode.substring(0, 2)}****');
    return true;
  }

  /// 向新邮箱发送验证链接 (简化方案)
  ///
  /// 使用 Supabase 的 updateUser 自动发送确认邮件
  /// 这种方式会直接触发 Supabase 的邮箱变更流程:
  /// 1. 向新邮箱发送确认链接
  /// 2. 用户点击链接后自动完成验证
  ///
  /// 注意: 这是最简单可靠的方案,不需要手动处理 OTP
  Future<void> requestEmailChange(
    String newEmail,
    String currentOtpCode,
  ) async {
    try {
      debugPrint('📧 请求更改邮箱到: $newEmail');

      // 验证邮箱格式
      final emailRegExp = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      if (!emailRegExp.hasMatch(newEmail)) {
        throw Exception('邮箱格式不正确');
      }

      // 直接使用 updateUser 发起邮箱变更
      // Supabase 会自动向新邮箱发送确认链接
      await _supabase.auth.updateUser(
        UserAttributes(email: newEmail, nonce: currentOtpCode),
      );

      debugPrint('✅ 邮箱变更请求已发送,请检查新邮箱中的确认链接');
    } catch (e) {
      debugPrint('❌ 请求邮箱变更失败: $e');
      rethrow;
    }
  }

  // ============================================================================
  // 敏感操作方法(需要先通过 OTP 验证)
  // ============================================================================

  /// 添加邮箱(简化版 - 仅需当前账号 OTP)
  ///
  /// 为没有邮箱的账号添加邮箱地址和密码
  /// 新流程(使用 magic link):
  /// 1. 调用 sendReauthenticationOtp() - 向当前账号发送重认证 OTP
  /// 2. 调用此方法 - 使用 OTP 验证身份并发起邮箱添加
  /// 3. Supabase 会向新邮箱发送确认链接
  /// 4. 用户点击链接后自动完成邮箱添加
  ///
  /// @param email 要添加的新邮箱地址
  /// @param password 要设置的密码
  /// @param currentOtpCode 当前账号的重认证 OTP 码(作为nonce)
  Future<bool> addEmail(
    String email,
    String password,
    String currentOtpCode,
  ) async {
    try {
      debugPrint('📧 添加邮箱: $email');

      // 使用当前账号的 OTP 作为 nonce 更新邮箱和密码
      // nonce 会在这里自动验证,如果无效会抛出异常
      // Supabase 会自动向新邮箱发送确认链接
      await _supabase.auth.updateUser(
        UserAttributes(email: email, password: password, nonce: currentOtpCode),
        emailRedirectTo: emailChangeCallbackUri,
      );

      debugPrint('✅ 邮箱添加请求已发送,请检查新邮箱中的确认链接');
      return true;
    } catch (e) {
      debugPrint('❌ 添加邮箱失败: $e');
      rethrow;
    }
  }

  /// 更新邮箱(简化版 - 仅需当前邮箱 OTP)
  ///
  /// 修改现有邮箱地址
  /// 新流程(使用 magic link):
  /// 1. 调用 sendReauthenticationOtp() - 向当前邮箱发送重认证 OTP
  /// 2. 调用此方法 - 使用 OTP 验证身份并发起邮箱更新
  /// 3. Supabase 会向新邮箱发送确认链接
  /// 4. 用户点击链接后自动完成邮箱更新
  ///
  /// @param newEmail 新的邮箱地址
  /// @param currentOtpCode 当前邮箱收到的重认证 OTP 码(作为nonce)
  Future<bool> updateEmail(String newEmail, String currentOtpCode) async {
    try {
      debugPrint('📧 更新邮箱: $newEmail');

      // 使用当前邮箱的 OTP 作为 nonce 更新邮箱
      // nonce 会在这里自动验证,如果无效会抛出异常
      // Supabase 会自动向新邮箱发送确认链接
      await _supabase.auth.updateUser(
        UserAttributes(email: newEmail, nonce: currentOtpCode),
        emailRedirectTo: emailChangeCallbackUri,
      );

      debugPrint('✅ 邮箱更新请求已发送,请检查新邮箱中的确认链接');
      return true;
    } catch (e) {
      debugPrint('❌ 更新邮箱失败: $e');
      rethrow;
    }
  }

  /// 更改密码(使用 OTP 验证)
  Future<bool> changePassword(String newPassword, String otpCode) async {
    try {
      debugPrint('🔐 更改密码');

      // 验证密码长度
      if (newPassword.length < 6) {
        throw Exception('密码长度至少为 6 位');
      }

      // 使用 OTP nonce 更新密码
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword, nonce: otpCode),
      );

      debugPrint('✅ 密码更改成功');
      return true;
    } catch (e) {
      debugPrint('❌ 更改密码失败: $e');
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

  /// 删除账号(危险操作,使用 OTP 验证)
  Future<bool> deleteAccount(String otpCode) async {
    try {
      debugPrint('⚠️ 删除账号');

      // 这里需要调用 Edge Function 或 Admin API
      // 因为普通用户无法直接删除自己的账号
      final response = await _supabase.functions.invoke(
        'delete_user_account',
        body: {'nonce': otpCode},
      );

      if (response.status == 200) {
        debugPrint('✅ 账号删除成功');
        return true;
      } else {
        throw Exception('删除账号失败');
      }
    } catch (e) {
      debugPrint('❌ 删除账号失败: $e');
      rethrow;
    }
  }
}
