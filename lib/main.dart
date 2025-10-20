import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:toneup_app/components/mainshell.dart';
import 'package:toneup_app/page_home.dart';
import 'package:toneup_app/page_login.dart';
import 'package:toneup_app/page_plan.dart';
import 'package:toneup_app/page_podcast.dart';
import 'package:toneup_app/page_practice.dart';
import 'package:toneup_app/page_profile.dart';
import 'package:toneup_app/page_signup.dart';
import 'package:toneup_app/providers/plan_provider.dart';
import 'package:toneup_app/providers/tts_provider.dart';
import 'package:toneup_app/services/navigation_service.dart';
import 'package:toneup_app/theme_data.dart';
import 'package:toneup_app/routes.dart';

void main() async {
  try {
    await Supabase.initialize(
      url: 'https://kixonwnuivnjqlraydmz.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtpeG9ud251aXZuanFscmF5ZG16Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY4MjUxMjMsImV4cCI6MjA3MjQwMTEyM30.PWwgMIdde9OMJLA-D5kzlEl9APUvAoeFwWtInXzb4a0',
    );

    runApp(MyApp());
  } catch (e) {
    debugPrint('Supabase初始化失败:$e');
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
            path: AppRoutes.PODCASTS,
            builder: (context, state) => const PodcastPage(),
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
        // 登录/注册页（不需要保留状态，用普通路由）
        GoRoute(
          path: AppRoutes.LOGIN,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.SIGN_UP,
          builder: (context, state) => const SignUpPage(),
        ),
        GoRoute(
          path: AppRoutes.GOAL_LIST,
          builder: (context, state) => const PlanPage(),
        ),
        GoRoute(
          path: AppRoutes.PRACTICE,
          builder: (context, state) => const PracticePage(),
        ),
        // 有状态的嵌套路由（底部导航相关页面）
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          branches: branches,
        ),
      ],
    );

    // 监听登录状态变化
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedOut) {
        _router.go(AppRoutes.LOGIN);
      } else if (event == AuthChangeEvent.signedIn) {
        _router.go(AppRoutes.HOME);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => PlanProvider()..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => TTSProvider()),
      ],
      child: MaterialApp.router(
        title: 'ToneUp',
        theme: appThemeData,
        darkTheme: appDarkThemeData,
        themeMode: ThemeMode.light,
        // themeMode: ThemeMode.dark,
        // routerConfig: _router,
        routerDelegate: _router.routerDelegate,
        routeInformationParser: _router.routeInformationParser,
        routeInformationProvider: _router.routeInformationProvider,
      ),
    );
  }
}
