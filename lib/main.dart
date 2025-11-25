import 'package:flutter/material.dart';
import 'package:jieba_flutter/analysis/jieba_segmenter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:toneup_app/components/mainshell.dart';
import 'package:toneup_app/page_create_goal.dart';
import 'package:toneup_app/profile_account.dart';
import 'package:toneup_app/page_evaluation.dart';
import 'package:toneup_app/page_forgot.dart';
import 'package:toneup_app/page_home.dart';
import 'package:toneup_app/page_login.dart';
import 'package:toneup_app/page_plan.dart';
import 'package:toneup_app/page_practice.dart';
import 'package:toneup_app/page_profile.dart';
import 'package:toneup_app/page_signup.dart';
import 'package:toneup_app/page_welcome.dart';
import 'package:toneup_app/profile_settings.dart';
import 'package:toneup_app/providers/account_settings_provider.dart';
import 'package:toneup_app/providers/create_goal_provider.dart';
import 'package:toneup_app/providers/plan_provider.dart';
import 'package:toneup_app/providers/profile_provider.dart';
import 'package:toneup_app/providers/tts_provider.dart';
import 'package:toneup_app/services/config.dart';
import 'package:toneup_app/services/navigation_service.dart';
import 'package:toneup_app/services/oauth_service.dart';
import 'package:toneup_app/theme_data.dart';
import 'package:toneup_app/routes.dart';

void main() async {
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    await JiebaSegmenter.init();

    runApp(MyApp());
  } catch (e) {
    debugPrint('初始化失败:$e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final String _initialLocation;
  late final GoRouter _router;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();

    // 判断是否已登录
    final session = Supabase.instance.client.auth.currentSession;
    _initialLocation = session != null ? AppRoutes.HOME : AppRoutes.LOGIN;

    // 定义嵌套路由的分支（对应底部导航项）
    final branches = [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.HOME,
            builder: (context, state) => const HomePage(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.GOAL_LIST,
            builder: (context, state) => const PlanPage(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.PROFILE,
            builder: (context, state) => const ProfilePage(),
            routes: [
              GoRoute(
                path: 'linking-callback',
                name: 'linking-callback',
                builder: (context, state) {
                  debugPrint('📍 [Route] 进入 linking-callback 路由，准备自销毁。');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_router.canPop()) {
                      GoRouter.of(context).pop();
                      debugPrint('📍 [Route] linking-callback 路由已自销毁。');
                    }
                    _router.push(AppRoutes.SETTINGS);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _router.push(AppRoutes.ACCOUNT_SETTINGS);
                    });
                  });
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ],
      ),
    ];

    _router = GoRouter(
      initialLocation: _initialLocation,
      navigatorKey: rootNavigatorKey,
      // debugLogDiagnostics: true,
      redirect: (context, state) async {
        final uri = state.uri;
        debugPrint(
          '🛑 redirect: 重定向 deeplink: ${uri.toString()},host:${uri.host},query:${uri.query}',
        );
        if (uri.toString().contains('linking-callback')) {
          try {
            final path = uri.path == '/' ? '/linking-callback' : uri.path;
            final newLocation = uri.query.isNotEmpty
                ? '$path?${uri.query}'
                : path;
            debugPrint('重定向到：：：：：${AppRoutes.PROFILE}$newLocation');
            return '${AppRoutes.PROFILE}$newLocation';
          } catch (e) {
            debugPrint('❌ [Redirect] 解析 Deeplink 失败: $e');
          }
        }
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.LOGIN,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.SIGN_UP,
          builder: (context, state) => const SignUpPage(),
        ),
        GoRoute(
          path: AppRoutes.PRACTICE,
          builder: (context, state) => const PracticePage(),
        ),
        GoRoute(
          path: AppRoutes.EVALUATION,
          builder: (context, state) => const EvaluationPage(),
        ),
        GoRoute(
          path: AppRoutes.WELCOME,
          builder: (context, state) => const WelcomePage(),
        ),
        GoRoute(
          path: AppRoutes.FORGOT,
          builder: (context, state) => const ForgotPage(),
        ),
        GoRoute(
          path: AppRoutes.SETTINGS,
          builder: (context, state) => const ProfileSettings(),
        ),
        GoRoute(
          path: AppRoutes.ACCOUNT_SETTINGS,
          builder: (context, state) => ChangeNotifierProvider(
            create: (_) => AccountSettingsProvider(),
            child: const AccountSettings(),
          ),
        ),
        GoRoute(
          path: AppRoutes.CREATE_GOAL,
          builder: (context, state) => ChangeNotifierProvider(
            create: (_) => CreateGoalProvider(),
            child: const CreateGoalPage(),
          ),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          branches: branches,
        ),
      ],
      // 🆕 错误处理
      errorBuilder: (context, state) {
        debugPrint('🔴 路由错误: ${state.uri}');
        debugPrint('🔴 路由参数: ${state.uri.queryParameters}');
        // 错误路由
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Page not found'),
                  SizedBox(height: 8),
                  Text(
                    state.uri.toString(),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go(AppRoutes.HOME),
                    child: Text('Back to Home'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // 🆕 监听登录状态变化
    Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) async {
        final event = data.event;
        final session = data.session;
        debugPrint('📡 Auth State Change: $event');
        if (event == AuthChangeEvent.signedOut) {
          debugPrint('🚪 用户登出');
          _router.go(AppRoutes.LOGIN);
        } else if (event == AuthChangeEvent.signedIn && session != null) {
          debugPrint('✅ 检测到登录/绑定成功事件');
          // 🆕 检查是否是绑定操作
          if (OAuthService().isAuthenticating) {
            debugPrint('🔗 绑定操作中,不执行登录跳转');
            _showGlobalSnackBar('账号绑定成功', isError: false);
          } else {
            final user = session.user;
            debugPrint('🔐 识别为登录成功，执行跳转,👤 用户信息: ${user.email}');
            _setOAuthInfoToTempProfile(user);
            // 小延迟确保状态完全同步
            debugPrint('🏠 导航到首页');
            _router.go(AppRoutes.HOME);
          }
        } else if (event == AuthChangeEvent.tokenRefreshed) {
          debugPrint('🔄 Token 已刷新');
        } else if (event == AuthChangeEvent.userUpdated) {
          await Supabase.instance.client.auth.refreshSession();
          debugPrint('✅ 检测到用户信息更新事件');
          if (OAuthService().isAuthenticating) {
            debugPrint('🔗 识别为绑定成功(通过userUpdated)，不执行跳转');
            _showGlobalSnackBar('账号绑定成功', isError: false);
          }
        }
      },
      onError: (error) {
        // 捕获绑定过程中的错误
        debugPrint('❌ Linking: Auth error: $error');

        // 处理不同类型的错误
        if (error is AuthException) {
          final code = error.statusCode ?? '';
          final message = error.message;
          debugPrint('❌ Auth错误码: $code');
          debugPrint('❌ Auth错误信息: $message');
          String friendlyMessage;
          if (code == 'identity_already_exists' ||
              message.toLowerCase().contains('already linked')) {
            friendlyMessage = '该账号已被其他用户绑定';
          } else if (message.toLowerCase().contains('cancelled')) {
            friendlyMessage = '用户取消了授权';
          } else {
            friendlyMessage = '操作失败: $message';
          }
          _showGlobalSnackBar(friendlyMessage, isError: true);
        } else {
          _showGlobalSnackBar('操作失败,请重试', isError: true);
        }
      },
    );
  }

  /// 🆕 显示全局 SnackBar
  void _showGlobalSnackBar(String message, {required bool isError}) {
    debugPrint('📢 显示提示: $message');
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '关闭',
          textColor: Colors.white,
          onPressed: () {
            _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// 🆕 暂存第三方用户信息
  Future<void> _setOAuthInfoToTempProfile(User user) async {
    try {
      final metadata = user.userMetadata;
      final nickname =
          metadata?['full_name'] ??
          metadata?['name'] ??
          user.email?.split('@')[0] ??
          'User';
      debugPrint('👤 使用昵称: $nickname');
      ProfileProvider().tempProfile.nickname = nickname;
      // 如果有头像 URL
      if (metadata?['avatar_url'] != null) {
        debugPrint('🖼️ 检测到头像: ${metadata!['avatar_url']}');
        // 这里可以下载并保存头像
        // ProfileProvider().tempProfile.avatar = ...
      }
      debugPrint('✅ 暂存第三方用户信息-完成');
    } catch (e) {
      debugPrint('❌ 暂存第三方用户信息-失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlanProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => TTSProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: MaterialApp.router(
        title: 'ToneUp',
        theme: appThemeData,
        darkTheme: appDarkThemeData,
        themeMode: ThemeMode.system,
        routerDelegate: _router.routerDelegate,
        routeInformationParser: _router.routeInformationParser,
        routeInformationProvider: _router.routeInformationProvider,
        // routerConfig: _router,
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: _scaffoldMessengerKey,
      ),
    );
  }
}
