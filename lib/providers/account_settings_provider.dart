import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/services/oauth_service.dart';

class AccountSettingsProvider extends ChangeNotifier {
  final _oauthService = OAuthService();

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
        debugPrint('🔔 AccountSettingsProvider 收到 auth event: $event');
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
  /// 返回 true 表示绑定请求已发送(用户需要在浏览器中完成授权)
  /// 实际绑定结果会通过 auth state change 事件触发自动刷新
  Future<bool> linkApple() async {
    if (_disposed) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _oauthService.linkAppleAccount();

      if (success) {
        debugPrint('✅ Apple 绑定请求已发送,等待用户授权');
        // 不立即刷新,等待 auth state change 事件
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
  Future<bool> linkGoogle() async {
    if (_disposed) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _oauthService.linkGoogleAccount();
      if (success) {
        debugPrint('✅ Google 绑定请求已发送,等待用户授权');
        // 不立即刷新,等待 auth state change 事件
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

  /// 更新邮箱
  Future<bool> updateEmail(String newEmail) async {
    if (_disposed) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _oauthService.updateEmail(newEmail);
      if (success) {
        // 邮箱更新需要验证，暂不重新加载
        // await loadConnectedAccounts();
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ 更新邮箱失败: $e');
      return false;
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// 更改密码
  Future<bool> changePassword(String newPassword) async {
    if (_disposed) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _oauthService.changePassword(newPassword);
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ 更改密码失败: $e');
      return false;
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// 删除账号
  Future<bool> deleteAccount() async {
    if (_disposed) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _oauthService.deleteAccount();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ 删除账号失败: $e');
      return false;
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
