import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:jieba_flutter/analysis/jieba_segmenter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/providers/plan_provider.dart';
import 'package:toneup_app/providers/profile_provider.dart';
import 'package:toneup_app/providers/subscription_provider.dart';
import 'package:toneup_app/providers/tts_provider.dart';
import 'package:toneup_app/services/config.dart';
import 'package:toneup_app/services/native_auth_service.dart';
import 'package:toneup_app/theme_data.dart';
import 'package:toneup_app/router_config.dart';

/// 全局 ScaffoldMessengerKey
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 配置 Web URL 策略: 使用 Path URL Strategy (无 hash)
  usePathUrlStrategy();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  await JiebaSegmenter.init();
  await NativeAuthService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter();

    /// 设置 auth state change 监听
    Supabase.instance.client.auth.onAuthStateChange.listen(
      _authStateChangeHandler,
      onError: (error) {
        String friendlyMessage;
        if (error is AuthException) {
          if (error.statusCode == 'identity_already_exists' ||
              error.message.toLowerCase().contains('already linked')) {
            friendlyMessage = 'This account is already linked to another user.';
          } else if (error.message.toLowerCase().contains('cancelled')) {
            friendlyMessage = 'Account linking cancelled by user.';
          } else {
            friendlyMessage = 'Operation failed: ${error.message}';
          }
        } else {
          friendlyMessage = '❌ onAuthStateChange error: $error';
        }
        showGlobalSnackBar(friendlyMessage, isError: true);
      },
    );
  }

  /// 处理认证状态变化
  void _authStateChangeHandler(AuthState data) async {
    final event = data.event;
    final session = data.session;
    debugPrint('🔔 @main 收到 auth event: $event');
    if (event == AuthChangeEvent.signedOut) {
      /// 退出登录
      ProfileProvider().onUserSign(false);
      PlanProvider().onUserSign(false);
      SubscriptionProvider().onUserSign(false);
      _router.go(AppRouter.LOGIN);
    } else if (event == AuthChangeEvent.signedIn && session != null) {
      /// 登录成功或账号绑定
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // ✅ 获取当前路由信息
        final currentUri = _router.routerDelegate.currentConfiguration.uri;
        final currentLocation = currentUri.path;
        final currentUriString = currentUri.toString();

        debugPrint('🔄 当前路由: $currentLocation (URI: $currentUriString)');
        
        // 登录操作：在 LOGIN/SIGN_UP/LOGIN_CALLBACK 页面
        // 注意：Custom Scheme Deep Link 的 path 可能是 "/"，需要检查完整 URI
        final isLoginFlow =
            currentLocation == AppRouter.LOGIN ||
            currentLocation == AppRouter.SIGN_UP ||
            currentLocation == AppRouter.LOGIN_CALLBACK ||
            currentUriString.contains('login-callback');

        // 账号绑定操作：在 LINKING_CALLBACK 或其他已登录页面
        final isLinkingFlow = currentUriString.contains('linking-callback');

        if (isLoginFlow && !isLinkingFlow) {
          debugPrint('🔄 登录成功,跳转到首页 (from: $currentLocation)');
          _cacheOAuthUserInfo(user);
          _router.go(AppRouter.HOME);
          SubscriptionProvider().onUserSign(true);
          ProfileProvider().onUserSign(true);
          PlanProvider().onUserSign(true);
        } else {
          debugPrint('🔄 账号绑定成功,保持当前页面 (location: $currentLocation)');
          // 账号绑定后刷新 Provider 数据
          ProfileProvider().fetchProfile();
        }
      }
    } else if (event == AuthChangeEvent.userUpdated) {
      Supabase.instance.client.auth.refreshSession();
    }
  }

  /// 缓存第三方登录的用户信息
  void _cacheOAuthUserInfo(User? user) {
    // 此处可添加用户信息缓存逻辑
    // 例如：保存昵称、头像等
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlanProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => TTSProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(
          create: (_) => SubscriptionProvider()..initialize(),
        ),
      ],
      child: MaterialApp.router(
        title: 'ToneUp',
        theme: appThemeData,
        darkTheme: appDarkThemeData,
        themeMode: ThemeMode.system,
        routerDelegate: _router.routerDelegate,
        routeInformationParser: _router.routeInformationParser,
        routeInformationProvider: _router.routeInformationProvider,
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: scaffoldMessengerKey,
      ),
    );
  }
}

/// 显示全局 SnackBar
///
/// [message] - 要显示的消息
/// [isError] - 是否为错误消息（影响颜色）
/// [floating] - 是否使用浮动模式（浮动模式可以显示在 Dialog 上方）
void showGlobalSnackBar(
  String message, {
  bool isError = false,
  bool floating = false,
  Duration? duration,
}) {
  debugPrint('🔔 showGlobalSnackBar: $message');

  final context = scaffoldMessengerKey.currentContext;
  if (context == null) return;

  final theme = Theme.of(context);
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isError
              ? theme.colorScheme.onErrorContainer
              : theme.colorScheme.onPrimaryContainer,
        ),
      ),
      backgroundColor: isError
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.primaryContainer,
      duration: duration ?? Duration(seconds: 3),
      behavior: floating ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
      margin: floating
          ? const EdgeInsets.only(bottom: 80, left: 16, right: 16)
          : null,
      action: SnackBarAction(
        label: 'Close',
        textColor: isError
            ? theme.colorScheme.onErrorContainer
            : theme.colorScheme.onPrimaryContainer,
        onPressed: () {
          scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
        },
      ),
    ),
  );
}

/// 在 Dialog 上方显示提示（使用 Overlay）
///
/// 这个方法会在最顶层的 Overlay 显示提示，确保在 Dialog 之上可见
/// 适用于需要在 Dialog 内部显示验证错误等场景
void showOverlayMessage(
  BuildContext context,
  String message, {
  bool isError = false,
  Duration duration = const Duration(seconds: 2),
}) {
  final theme = Theme.of(context);
  final overlay = Overlay.of(context);

  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isError
                ? theme.colorScheme.errorContainer
                : theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onPrimaryContainer,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isError
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  // 自动移除
  Future.delayed(duration, () {
    overlayEntry.remove();
  });
}
