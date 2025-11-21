import 'package:flutter/material.dart';
import 'package:jieba_flutter/analysis/jieba_segmenter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:toneup_app/components/mainshell.dart';
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
  late final GoRouter _router;
  // 🆕 用于显示全局错误提示的 GlobalKey
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();

    // 判断是否已登录
    final session = Supabase.instance.client.auth.currentSession;
    final initialLocation = session != null ? AppRoutes.HOME : AppRoutes.LOGIN;

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
          ),
        ],
      ),
    ];

    _router = GoRouter(
      initialLocation: initialLocation,
      navigatorKey: rootNavigatorKey,
      debugLogDiagnostics: true,
      // redirect: (context, state) {
      //   final uri = state.uri.toString();
      //   // 如果是 Deep Link，提取路径部分
      //   if (uri.contains('io.supabase.toneup://')) {
      //     // 提取路径和查询参数
      //     final uriObj = Uri.parse(uri);
      //     final path = uriObj.path;
      //     final query = uriObj.query;

      //     debugPrint('📍 检测到 Deep Link，提取路径 $path$query');
      //     // 重定向到路径版本
      //     // return '$path${query.isNotEmpty ? "?$query" : ""}';
      //     return '/login-callback?type=linking';
      //   }
      //   return null;
      // },
      routes: [
        // 登录/注册页
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
        // 🆕 Web 环境的 OAuth 回调
        // GoRoute(
        //   path: '/auth/callback',
        //   redirect: (context, state) {
        //     debugPrint('📍 OAuth 回调路由被访问');
        //     final type = state.uri.queryParameters['type'];
        //     if (type == 'linking') {
        //       // 绑定操作,不跳转
        //       debugPrint('🔗 检测到绑定操作,保持当前页面');
        //       return null; // 不跳转
        //     } else {
        //       // 登录操作,跳转到首页
        //       debugPrint('🏠 检测到登录操作,跳转到首页');
        //       return AppRoutes.HOME;
        //     }
        //   },
        //   builder: (context, state) {
        //     debugPrint('📍 OAuth 回调路由被访问');
        //     return Scaffold(
        //       body: Center(
        //         child: Column(
        //           mainAxisAlignment: MainAxisAlignment.center,
        //           children: [
        //             CircularProgressIndicator(),
        //             SizedBox(height: 16),
        //             Text('Completing sign in...'),
        //           ],
        //         ),
        //       ),
        //     );
        //   },
        // ),
        // // Deep Link: io.supabase.toneup://login-callback
        // // 🆕 APP 环境的 OAuth 回调: /login-callback
        // GoRoute(
        //   path: '/login-callback',
        //   redirect: (context, state) {
        //     debugPrint('📍 Deep Link 回调路由: ${state.uri}');
        //     final type = state.uri.queryParameters['type'];
        //     if (type == 'linking') {
        //       // 🎯 绑定操作:返回 null,然后在 builder 中处理
        //       debugPrint('🔗 检测到绑定操作');
        //       return null;
        //     } else {
        //       // 登录操作:直接跳转到首页
        //       debugPrint('🏠 检测到登录操作,跳转到首页');
        //       return AppRoutes.HOME;
        //     }
        //   },
        // ),
        // 有状态的嵌套路由（底部导航相关页面）
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
        } else if (event == AuthChangeEvent.signedIn) {
          debugPrint('✅ 用户登录成功');
          // 🆕 检查是否是绑定操作
          if (OAuthService().isAuthenticating) {
            // 🆕 绑定操作:不跳转,只记录日志
            debugPrint('🔗 绑定操作中,不执行登录跳转');
          } else if (session != null) {
            final user = session.user;
            debugPrint('👤 用户信息: ${user.email}');
            // 暂存第三方用户信息
            _setOAuthInfoToTempProfile(user);
            // 小延迟确保状态完全同步
            // await Future.delayed(const Duration(milliseconds: 300));
            debugPrint('🏠 导航到首页');
            _router.go(AppRoutes.HOME);
          }
        } else if (event == AuthChangeEvent.tokenRefreshed) {
          debugPrint('🔄 Token 已刷新');
        } else if (event == AuthChangeEvent.userUpdated) {
          debugPrint('🔄 用户信息更新');
          if (OAuthService().isAuthenticating) {
            debugPrint('✅ 绑定操作成功');
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
      onDone: () {},
      cancelOnError: true,
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
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: _scaffoldMessengerKey,
      ),
    );
  }
}
