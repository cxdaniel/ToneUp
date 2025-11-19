import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/services/account_service.dart';

class AccountSettingsProvider extends ChangeNotifier {
  final _accountService = AccountService();

  Map<String, dynamic> _connectedAccounts = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  // Getters
  Map<String, dynamic> get connectedAccounts => _connectedAccounts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // 便捷访问器
  bool get hasEmail => _connectedAccounts['email'] != null;
  bool get hasApple => _connectedAccounts['apple'] != null;
  bool get hasGoogle => _connectedAccounts['google'] != null;
  String? get primaryProvider => _connectedAccounts['primary'];

  @override
  void dispose() {
    _disposed = true;
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _connectedAccounts = await _accountService.getConnectedAccounts();
      debugPrint('✅ 已连接账号: $_connectedAccounts');
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ 加载账号信息失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 绑定 Apple 账号
  Future<bool> linkApple() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _accountService.linkAppleAccount();
      if (success) {
        await loadConnectedAccounts(); // 重新加载账号信息
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ 绑定 Apple 失败: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 绑定 Google 账号
  Future<bool> linkGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _accountService.linkGoogleAccount();
      if (success) {
        await loadConnectedAccounts(); // 重新加载账号信息
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ 绑定 Google 失败: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 解绑账号
  Future<bool> unlinkAccount(
    UserIdentity identityId,
    String accountType,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _accountService.unlinkAccount(identityId);
      if (success) {
        await loadConnectedAccounts(); // 重新加载账号信息
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ 解绑 $accountType 失败: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 更新邮箱
  Future<bool> updateEmail(String newEmail) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _accountService.updateEmail(newEmail);
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
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 更改密码
  Future<bool> changePassword(String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _accountService.changePassword(newPassword);
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ 更改密码失败: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 删除账号
  Future<bool> deleteAccount() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _accountService.deleteAccount();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ 删除账号失败: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
