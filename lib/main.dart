import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
// 条件导入：仅在 Web 平台导入 dart:html
import 'web_utils_stub.dart'
    if (dart.library.html) 'package:toneup_app/web_utils.dart';

/// 全局 ScaffoldMessengerKey
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
void main() async {
  // 加载环境变量
  await dotenv.load(fileName: '.env');

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
    setupAuthStateListener(_router);

    // Web 平台：检查完整 URL 是否包含回调路径
    if (kIsWeb) {
      _checkWebCallbackUrl();
    }
  }

  /// Web 平台：检查并处理回调 URL
  void _checkWebCallbackUrl() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final fullUrl = getWindowLocationHref();
        debugPrint('🌐 检查 Web URL: $fullUrl');

        // 检查是否是账号绑定回调
        if (fullUrl.contains('/linking-callback')) {
          debugPrint('🔗 检测到账号绑定回调，导航到回调路由');
          _router.go('/linking-callback');
          // _router.go('${AppRoutes.PROFILE}/linking-callback');
          return;
        }

        // 检查是否是邮箱变更回调
        if (fullUrl.contains('/email-change-callback')) {
          debugPrint('📧 检测到邮箱变更回调，导航到回调路由');
          _router.go('/email-change-callback');
          // _router.go('${AppRoutes.PROFILE}/email-change-callback');
          return;
        }

        debugPrint('✅ 非回调 URL，正常启动');
      } catch (e) {
        debugPrint('❌ 检查 Web URL 失败: $e');
      }
    });
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
}) {
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
      duration: const Duration(seconds: 3),
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
