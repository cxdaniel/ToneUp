import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/services/config.dart';

/// 原生第三方登录服务
///
/// 支持 Apple Sign In 和 Google Sign In 的原生体验
/// - Apple: iOS/macOS 原生 UI
/// - Google: 移动端原生 UI,Web 端使用 OAuth
class NativeAuthService {
  static final NativeAuthService _instance = NativeAuthService._internal();
  factory NativeAuthService() => _instance;
  NativeAuthService._internal();

  final _supabase = Supabase.instance.client;
  final _googleSignIn = GoogleSignIn.instance;

  /// 初始化 Google Sign In
  ///
  /// 注意: Web 端不支持 serverClientId 参数
  Future<void> initialize() async {
    await _googleSignIn.initialize(
      clientId: kIsWeb ? OAuthConfig.clientIDGoogle : null,
      serverClientId: kIsWeb ? null : OAuthConfig.serverClientIDGoogle,
    );
  }

  /// Apple 登录
  ///
  /// iOS 原生环境不使用 nonce,直接通过 identityToken 验证
  Future<AuthResponse?> signInWithApple() async {
    try {
      if (!await SignInWithApple.isAvailable()) {
        throw Exception('Apple Sign In 不可用(需要 iOS 13+ 或 macOS 10.15+)');
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: kIsWeb
            ? WebAuthenticationOptions(
                clientId: OAuthConfig.clientIDApple,
                redirectUri: Uri.parse('${Uri.base.origin}/auth/callback'),
              )
            : null,
      );

      if (credential.identityToken == null) {
        throw Exception('未获取到 identityToken');
      }

      return await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      rethrow;
    } on PlatformException catch (e) {
      if (e.code == 'not-available') {
        throw Exception('您的设备不支持 Apple 登录(需要 iOS 13+ 或 macOS 10.15+)');
      }
      rethrow;
    }
  }

  /// Apple 账号绑定
  ///
  /// 使用 linkIdentityWithIdToken 将 Apple 账号绑定到当前用户
  Future<AuthResponse?> linkAppleAccount() async {
    try {
      if (_supabase.auth.currentUser == null) {
        throw Exception('请先登录');
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.identityToken == null) {
        throw Exception('Apple 授权失败：未获取到 identityToken');
      }

      return await _supabase.auth.linkIdentityWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  /// Google 登录
  ///
  /// 使用 google_sign_in 7.x authenticate() API
  /// Supabase 需开启 "Skip nonce checks" 选项
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      if (!_googleSignIn.supportsAuthenticate()) {
        throw Exception('当前平台不支持 authenticate 方法');
      }

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw Exception('Google 授权失败:未获取到 idToken');
      }

      String? accessToken;
      try {
        final authorization = await googleUser.authorizationClient
            .authorizationForScopes(['email', 'profile']);
        accessToken = authorization?.accessToken;
      } catch (e) {
        debugPrint('获取 accessToken 失败: $e');
      }

      return await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: accessToken,
      );
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled') {
        return null;
      }
      rethrow;
    }
  }

  /// Google 账号绑定
  ///
  /// 使用 linkIdentityWithIdToken 将 Google 账号绑定到当前用户
  /// Supabase 需开启 "Skip nonce checks" 选项
  Future<AuthResponse?> linkGoogleAccount() async {
    try {
      if (_supabase.auth.currentUser == null) {
        throw Exception('请先登录');
      }

      if (!_googleSignIn.supportsAuthenticate()) {
        throw Exception('当前平台不支持 authenticate 方法');
      }

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw Exception('Google 授权失败:未获取到 idToken');
      }

      String? accessToken;
      try {
        final authorization = await googleUser.authorizationClient
            .authorizationForScopes(['email', 'profile']);
        accessToken = authorization?.accessToken;
      } catch (e) {
        debugPrint('获取 accessToken 失败: $e');
      }

      return await _supabase.auth.linkIdentityWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: accessToken,
      );
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled') {
        return null;
      }
      rethrow;
    }
  }

  /// Google 登出
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google 登出异常: $e');
    }
  }

  /// 检查 Apple Sign In 是否可用
  Future<bool> isAppleSignInAvailable() async {
    try {
      return await SignInWithApple.isAvailable();
    } catch (e) {
      return false;
    }
  }

  /// 释放资源
  void dispose() {
    _googleSignIn.disconnect();
  }
}
