import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/services/oauth_service.dart';
import 'package:toneup_app/services/native_auth_service.dart';

class AccountSettingsProvider extends ChangeNotifier {
  final _oauthService = OAuthService();
  final _nativeAuthService = NativeAuthService();

  Map<String, dynamic> _connectedAccounts = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;
  StreamSubscription<AuthState>? _authSubscription;
  final _supabase = Supabase.instance.client;

  // Getters
  Map<String, dynamic> get connectedAccounts => _connectedAccounts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 便捷访问器
  bool get hasEmail => _connectedAccounts['email'] != null;
  bool get hasApple => _connectedAccounts['apple'] != null;
  bool get hasGoogle => _connectedAccounts['google'] != null;
  String? get primaryProvider => _connectedAccounts['primary'];

  AccountSettingsProvider() {
    // 初始化时加载账号信息
    loadConnectedAccounts();
    // 设置 auth state change 监听
    _setupAuthListener();
  }

  /// 设置认证状态监听器
  /// 当账号绑定/解绑成功时,会自动刷新账号列表
  void _setupAuthListener() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen(
      (data) {
        final event = data.event;
        debugPrint('🔔 @AccountSettingsProvider 收到 auth event: $event');
        // 当检测到用户信息变化时,重新加载账号列表
        if (event == AuthChangeEvent.userUpdated ||
            event == AuthChangeEvent.tokenRefreshed) {
          debugPrint('🔄 用户信息已更新,重新加载账号列表');
          loadConnectedAccounts();
        }
      },
      onError: (error) {
        debugPrint('❌ onAuthStateChange error: $error');
      },
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  /// 加载已连接账号信息
  Future<void> loadConnectedAccounts() async {
    if (_disposed) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _connectedAccounts = await _oauthService.getConnectedAccounts();
      debugPrint('✅ 已连接账号: $_connectedAccounts');
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ 加载账号信息失败: $e');
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// 绑定 Apple 账号
  ///
  /// 移动端使用原生绑定(linkIdentityWithIdToken),Web 端使用 OAuth 流程
  /// 实际绑定结果会通过 auth state change 事件触发自动刷新
  Future<bool> linkApple() async {
    if (_disposed) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 移动端使用原生绑定
      if (!kIsWeb) {
        final isAvailable = await _nativeAuthService.isAppleSignInAvailable();
        if (!isAvailable) {
          throw Exception('当前设备不支持 Apple 登录');
        }

        final response = await _nativeAuthService.linkAppleAccount();
        if (response == null) {
          // 用户取消
          return false;
        }
        debugPrint('✅ Apple 原生绑定成功');
        return true;
      }

      // Web 端使用 OAuth
      final success = await _oauthService.linkAppleAccount();
      if (success) {
        debugPrint('✅ Apple OAuth 绑定请求已发送');
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ 绑定 Apple 失败: $e');
      return false;
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// 绑定 Google 账号
  ///
  /// 移动端使用原生绑定(linkIdentityWithIdToken),Web 端使用 OAuth 流程
  /// Supabase 需开启 "Skip nonce checks" 选项
  /// 实际绑定结果会通过 auth state change 事件触发自动刷新
  Future<bool> linkGoogle() async {
    if (_disposed) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 移动端使用原生绑定
      if (!kIsWeb) {
        final response = await _nativeAuthService.linkGoogleAccount();
        if (response == null) {
          // 用户取消
          return false;
        }
        debugPrint('✅ Google 原生绑定成功');
        return true;
      }

      // Web 端使用 OAuth
      final success = await _oauthService.linkGoogleAccount();
      if (success) {
        debugPrint('✅ Google OAuth 绑定请求已发送');
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ 绑定 Google 失败: $e');
      return false;
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// 解绑账号
  Future<bool> unlinkAccount(
    UserIdentity identityId,
    String accountType,
  ) async {
    if (_disposed) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _oauthService.unlinkAccount(identityId);
      if (success) {
        await loadConnectedAccounts(); // 重新加载账号信息
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ 解绑 $accountType 失败: $e');
      return false;
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // ============================================================================
  // OTP 重认证相关方法
  // ============================================================================

  /// 发送重认证 OTP
  Future<bool> sendReauthenticationOtp() async {
    if (_disposed) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _oauthService.sendReauthenticationOtp();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ 发送重认证 OTP 失败: $e');
      return false;
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// 验证重认证 OTP
  Future<bool> verifyReauthenticationOtp(String otpCode) async {
    if (_disposed) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _oauthService.verifyReauthenticationOtp(otpCode);
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ 验证重认证 OTP 失败: $e');
      return false;
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// 验证新邮箱的 OTP（用于邮箱变更/添加）
  Future<(bool, String?)> verifyNewEmailOtp(
    String email,
    String otpCode,
  ) async {
    if (_disposed) return (false, null);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _oauthService.verifyNewEmailOtp(email, otpCode);
      if (success) {
        await loadConnectedAccounts(); // 验证成功后刷新账号信息
      }
      return (success, success ? '邮箱验证成功！' : '验证失败，请检查验证码');
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ 验证新邮箱 OTP 失败: $e');
      return (false, '$e');
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// 添加邮箱(简化版 - 仅需新邮箱 OTP)
  /// @param email 新邮箱地址
  /// @param password 要设置的密码
  Future<(bool, String?)> addEmail(String email, String password) async {
    if (_disposed) return (false, null);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _oauthService.addEmail(email, password);
      if (success) {
        // 不立即刷新账号信息,等待新邮箱 OTP 验证后自动刷新
      }
      return (success, 'OTP 验证码已发送到新邮箱,请输入验证码完成添加');
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ 添加邮箱失败: $e');
      return (false, '$e');
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// 更新邮箱(简化版 - 仅需新邮箱 OTP)
  ///
  /// 简化流程:
  /// 1. 调用此方法发起更新
  /// 2. Supabase 向新邮箱发送 OTP 验证码
  /// 3. 用户输入新邮箱的 OTP 完成验证
  ///
  /// @param newEmail 新邮箱地址
  Future<(bool, String?)> updateEmail(String newEmail) async {
    if (_disposed) return (false, null);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _oauthService.updateEmail(newEmail);
      if (success) {
        // 不立即刷新账号信息,等待新邮箱 OTP 验证后自动刷新
      }
      return (success, 'OTP 验证码已发送到新邮箱,请输入验证码完成更新');
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ 更新邮箱失败: $e');
      return (false, '$e');
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// 更改密码
  Future<(bool, String?)> changePassword(
    String newPassword,
    String otpCode,
  ) async {
    if (_disposed) return (false, null);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _oauthService.changePassword(newPassword, otpCode);
      return (success, null);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ 更改密码失败: $e');
      return (false, '$e');
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// 删除账号
  Future<(bool, String?)> deleteAccount(String otpCode) async {
    if (_disposed) return (false, null);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _oauthService.deleteAccount(otpCode);
      return (success, null);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ 删除账号失败: $e');
      return (false, '$e');
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
