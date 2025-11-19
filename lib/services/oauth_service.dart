// lib/services/oauth_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class OAuthService {
  static final OAuthService _instance = OAuthService._internal();
  factory OAuthService() => _instance;
  OAuthService._internal();

  final _supabase = Supabase.instance.client;
  Completer<bool>? _authCompleter;
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _timeoutTimer;

  /// 启动 OAuth 登录流程
  ///
  /// [provider] - OAuth 提供商 (apple, google 等)
  /// [launchMode] - 启动模式，默认使用外部浏览器
  /// [timeout] - 超时时间，默认 60 秒
  ///
  /// 返回 true 表示登录成功，false 表示失败或取消
  Future<bool> signInWithProvider(
    OAuthProvider provider, {
    LaunchMode launchMode = LaunchMode.externalApplication,
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
    _setupAuthListener();

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
        redirectTo: 'io.supabase.toneup://login-callback/',
        authScreenLaunchMode: launchMode,
      );

      debugPrint('⏳ 等待认证完成...');

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
  void _setupAuthListener() {
    // 取消之前的监听
    _authSubscription?.cancel();

    // 创建新的监听
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
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
    });
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
  }

  /// 检查当前是否有活跃的认证流程
  bool get isAuthenticating =>
      _authCompleter != null && !_authCompleter!.isCompleted;
}
