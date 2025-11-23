import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
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
      // authOptions: FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
    );
    await JiebaSegmenter.init();

    final initialLink = await AppLinks().getInitialLink();
    if (initialLink != null) {
      await _handleDeepLink(initialLink);
    }
    // 监听应用运行中的 Deeplink
    AppLinks().uriLinkStream.listen((uri) async {
      await _handleDeepLink(uri);
    });

    runApp(MyApp());
  } catch (e) {
    debugPrint('初始化失败:$e');
  }
}

/// 处理拦截到的 Deeplink
Future<void> _handleDeepLink(Uri uri) async {
  debugPrint('📥 应用层面拦截到 Deeplink: $uri');
  // 1️⃣ 必须屏蔽自定义 scheme，阻止传入 GoRouter
  if (uri.scheme == 'io.supabase.toneup') {
    debugPrint('🛑 屏蔽自定义 Deeplink，不让 GoRouter 处理');
    if (uri.host == 'linking-callback') {
      debugPrint('🔗 linking-callback 被拦截，手动 push FORGOT 页面');
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   rootNavigatorKey.currentContext?.push(AppRoutes.FORGOT);
      // });
    }
    return; // ⛔ VERY IMPORTANT — 阻断继续传入 GoRouter
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
  // 🆕 用于显示全局错误提示的 GlobalKey
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
          ),
        ],
      ),
    ];

    _router = GoRouter(
      initialLocation: _initialLocation,
      navigatorKey: rootNavigatorKey,
      debugLogDiagnostics: true,
      redirect: (context, state) async {
        final uri = state.uri;
        // 0️⃣ 屏蔽所有外部 Deeplink，不让进入 GoRouter 栈
        // if (state.uri.scheme == 'io.supabase.toneup') {
        //   debugPrint('🛑 redirect: 屏蔽外部 deeplink: ${state.uri}');
        //   return null; // 保持当前页，不跳转
        // }
        if (uri.host == 'linking-callback') {
          //   final newPath = uri.path; // 应该是 '/linking-callback' 或 '/'
          //   final queryParams = uri.queryParameters;
          //   String newLocation;
          //   if (queryParams.isNotEmpty) {
          //     final queryString = Uri(queryParameters: queryParams).query;
          //     // 确保路径正确，如果 uri.path 是 '/', 则使用 '/linking-callback'
          //     newLocation =
          //         '${newPath == '/' ? '/linking-callback' : newPath}?$queryString';
          //   } else {
          //     newLocation = newPath == '/' ? '/linking-callback' : newPath;
          //   }
          //   debugPrint('✅ redirect: 重定向到新路径: $newLocation');
          //   // return newLocation;
          await _router.push(AppRoutes.FORGOT);
          return null;
        }

        // 对于所有其他情况，不进行重定向
        return null;
      },
      routes: [
        GoRoute(
          path: '/linking-callback',
          name: 'linking-callback',
          // redirect: (context, state) async {
          //   try {
          //     await _router.push(AppRoutes.FORGOT);
          //     return null;
          //   } catch (e) {
          //     debugPrint('redirect: $e');
          //   }
          // },
          builder: (context, state) => const SizedBox.shrink(),
          // builder: (context, state) {
          //   debugPrint('📍 GoRouter 捕获到 linking-callback 路由，准备自销毁。');
          //   // 使用 addPostFrameCallback 确保在路由渲染后再执行 pop
          //   // WidgetsBinding.instance.addPostFrameCallback((_) {
          //   //   if (context.mounted) {
          //   //     // 将这个空路由从导航栈中移除
          //   //     GoRouter.of(context).pop();
          //   //     debugPrint('📍 linking-callback 路由已自销毁。');
          //   //   }
          //   // });
          //   // 返回一个完全透明、不占空间的 Widget
          //   return const SizedBox.shrink();
          // },
        ),
        if (kIsWeb)
          GoRoute(
            path: '/auth/callback/linking',
            builder: (context, state) {
              final callbackUri = state.uri;
              // 检查是否是绑定回调（含type=linking）
              if (callbackUri.queryParameters.containsKey('type') &&
                  callbackUri.queryParameters['type'] == 'linking') {
                // 重定向到移动端相同的回调路由处理
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    GoRouter.of(context).pushNamed(
                      'linking-callback',
                      queryParameters: callbackUri.queryParameters,
                    );
                  }
                });
              }
              return const SizedBox.shrink();
            },
          ),
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
            // 🆕 绑定操作:不跳转,只记录日志
            debugPrint('🔗 绑定操作中,不执行登录跳转');
            _showGlobalSnackBar('账号绑定成功', isError: false);
            // OAuthService().resetLinkingState(); // 重置绑定状态
          } else {
            final user = session.user;
            debugPrint('🔐 识别为登录成功，执行跳转,👤 用户信息: ${user.email}');
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
        // routerDelegate: _router.routerDelegate,
        // routeInformationParser: _router.routeInformationParser,
        // routeInformationProvider: _router.routeInformationProvider,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: _scaffoldMessengerKey,
      ),
    );
  }
}
