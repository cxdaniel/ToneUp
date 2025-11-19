import 'package:flutter/material.dart';
import 'package:jieba_flutter/analysis/jieba_segmenter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:toneup_app/components/mainshell.dart';
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
import 'package:toneup_app/providers/plan_provider.dart';
import 'package:toneup_app/providers/profile_provider.dart';
import 'package:toneup_app/providers/tts_provider.dart';
import 'package:toneup_app/services/config.dart';
import 'package:toneup_app/services/navigation_service.dart';
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
        // 🆕 OAuth 回调处理路由
        GoRoute(
          path: '/auth/callback',
          builder: (context, state) {
            debugPrint('📍 OAuth 回调路由被访问');
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Completing sign in...'),
                  ],
                ),
              ),
            );
          },
        ),
        // 有状态的嵌套路由（底部导航相关页面）
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          branches: branches,
        ),
      ],

      // 🆕 错误处理（处理 Deep Link）
      errorBuilder: (context, state) {
        debugPrint('🔴 路由错误: ${state.uri}');
        // 如果是 OAuth 回调的 Deep Link
        if (state.uri.toString().contains('login-callback')) {
          debugPrint('📱 检测到 OAuth Deep Link 回调');
          // 显示加载页面，OAuthService 会处理认证
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Completing sign in...'),
                  SizedBox(height: 8),
                  Text(
                    'Please wait',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }
        // 其他路由错误
        return Scaffold(
          body: Center(
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
                  onPressed: () => context.go(AppRoutes.LOGIN),
                  child: Text('Back to Login'),
                ),
              ],
            ),
          ),
        );
      },
    );
    // 🆕 监听登录状态变化（改进版）
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;
      debugPrint('📡 Auth State Change: $event');
      if (event == AuthChangeEvent.signedOut) {
        debugPrint('🚪 用户登出');
        _router.go(AppRoutes.LOGIN);
      } else if (event == AuthChangeEvent.signedIn) {
        debugPrint('✅ 用户登录成功');
        if (session != null) {
          final user = session.user;
          debugPrint('👤 用户信息: ${user.email}');
          // 检查是否需要创建 Profile
          _setOAuthInfoToTempProfile(user);
          // 小延迟确保状态完全同步
          // await Future.delayed(const Duration(milliseconds: 300));
          debugPrint('🏠 导航到首页');
          _router.go(AppRoutes.HOME);
        }
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        debugPrint('🔄 Token 已刷新');
      }
    });
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
      ),
    );
  }
}
