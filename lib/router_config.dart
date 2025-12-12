import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/components/mainshell.dart';
import 'package:toneup_app/main.dart';
import 'package:toneup_app/pages/create_goal_page.dart';
import 'package:toneup_app/pages/document_viewer_page.dart';
import 'package:toneup_app/pages/download_page.dart';
import 'package:toneup_app/pages/paywall.dart';
import 'package:toneup_app/pages/profile_account.dart';
import 'package:toneup_app/pages/evaluation_page.dart';
import 'package:toneup_app/pages/forgot_page.dart';
import 'package:toneup_app/pages/reset_password_callback.dart';
import 'package:toneup_app/pages/home_page.dart';
import 'package:toneup_app/pages/signin_page.dart';
import 'package:toneup_app/pages/plan_page.dart';
import 'package:toneup_app/pages/practice_page.dart';
import 'package:toneup_app/pages/profile_page.dart';
import 'package:toneup_app/pages/signup_page.dart';
import 'package:toneup_app/pages/subscription_manage.dart';
import 'package:toneup_app/pages/welcome_page.dart';
import 'package:toneup_app/pages/profile_settings.dart';
import 'package:toneup_app/providers/account_settings_provider.dart';
import 'package:toneup_app/providers/create_goal_provider.dart';
import 'package:toneup_app/services/navigation_service.dart';

/// 配置应用路由
class AppRouter {
  // ignore_for_file: constant_identifier_names
  static const SPLASH = '/splash';
  static const LOGIN = '/login';
  static const SIGN_UP = '/sign_up';
  static const HOME = '/home';
  static const GOAL_LIST = '/goal_list';
  static const PRACTICE = '/practice';
  static const ACTIVE = '/active';
  static const PROFILE = '/profile';
  static const PODCASTS = '/podcasts';
  static const EVALUATION = '/evaluation';
  static const WELCOME = '/welcome';
  static const FORGOT = '/forgot';
  static const SETTINGS = '/settings';
  static const ACCOUNT_SETTINGS = '/account_settings';
  static const CREATE_GOAL = '/create_goal';
  static const PAYWALL = '/paywall';
  static const SUBSCRIPTION_MANAGE = '/profile/subscription';
  static const DOWNLOAD = '/download';
  static const LOGIN_CALLBACK = '/login-callback';
  static const LINKING_CALLBACK = '/linking-callback';
  static const EMAIL_CHANGE_CALLBACK = '/email-change-callback';
  static const RESET_PASSWORD_CALLBACK = '/reset-password-callback';
  static const PRIVACY_POLICY = '/privacy-policy';
  static const TERMS_OF_SERVICE = '/terms-of-service';
  static const ABOUT = '/about';

  static GoRouter createRouter() {
    final session = Supabase.instance.client.auth.currentSession;
    final initialLocation = session != null ? AppRouter.HOME : AppRouter.LOGIN;

    final branches = _createShellBranches();

    return GoRouter(
      initialLocation: initialLocation,
      navigatorKey: rootNavigatorKey,
      redirect: _handleRedirect,
      routes: _createRoutes(branches),
      errorBuilder: _buildErrorPage,
    );
  }

  /// 创建 Shell 分支（底部导航）
  static List<StatefulShellBranch> _createShellBranches() {
    return [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRouter.HOME,
            builder: (context, state) => const HomePage(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRouter.GOAL_LIST,
            builder: (context, state) => const PlanPage(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRouter.PROFILE,
            builder: (context, state) => const ProfilePage(),
            routes: [
              GoRoute(
                path: AppRouter.LINKING_CALLBACK,
                builder: (context, state) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final router = GoRouter.of(context);
                    if (router.canPop()) router.pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      router.push(AppRouter.ACCOUNT_SETTINGS);
                    });
                  });
                  return const SizedBox.shrink();
                },
              ),
              GoRoute(
                path: AppRouter.EMAIL_CHANGE_CALLBACK,
                builder: (context, state) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    final router = GoRouter.of(context);
                    // 刷新用户会话以获取最新的邮箱信息
                    try {
                      await Supabase.instance.client.auth.refreshSession();
                      debugPrint('✅ 邮箱变更回调: 用户会话已刷新');
                    } catch (e) {
                      debugPrint('❌ 邮箱变更回调: 刷新会话失败 $e');
                    }
                    if (router.canPop()) router.pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      router.push(AppRouter.ACCOUNT_SETTINGS);
                      // 延迟显示提示,确保页面已加载且数据已刷新
                      Future.delayed(const Duration(milliseconds: 500), () {
                        showGlobalSnackBar(
                          'Email verification successful! Your new email is now active.',
                          isError: false,
                        );
                      });
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
  }

  /// 处理重定向
  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    final uri = state.uri;
    final path = uri.path;
    debugPrint(
      '🔀 处理重定向: ${uri.toString()}, path:${uri.path}, query:${uri.query}',
    );

    // 检查用户是否已登录
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

    // 公开路由列表(无需登录即可访问)
    final publicRoutes = [
      AppRouter.LOGIN,
      AppRouter.SIGN_UP,
      AppRouter.FORGOT,
      AppRouter.LOGIN_CALLBACK,
      AppRouter.LINKING_CALLBACK,
      AppRouter.EMAIL_CHANGE_CALLBACK,
      AppRouter.RESET_PASSWORD_CALLBACK,
      AppRouter.PRIVACY_POLICY,
      AppRouter.TERMS_OF_SERVICE,
      AppRouter.ABOUT,
    ];

    // OAuth 登录回调处理
    if (path == AppRouter.LOGIN_CALLBACK ||
        uri.toString().contains(AppRouter.LOGIN_CALLBACK)) {
      debugPrint('➡️ 检测到登录回调,无需重定向,继续访问: $path');
      return AppRouter.HOME;
    }

    // 处理账号绑定回调
    if (path == AppRouter.LINKING_CALLBACK ||
        uri.toString().contains(AppRouter.LINKING_CALLBACK)) {
      debugPrint(
        '➡️ 检测到账号绑定回调,重定向到 ${AppRouter.PROFILE}${AppRouter.LINKING_CALLBACK}?${uri.query}',
      );
      return '${AppRouter.PROFILE}${AppRouter.LINKING_CALLBACK}?${uri.query}';
    }

    // 处理邮箱变更回调
    if (uri.toString().contains(AppRouter.EMAIL_CHANGE_CALLBACK)) {
      debugPrint(
        '➡️ 检测到邮箱变更回调,重定向到 ${AppRouter.PROFILE}${AppRouter.EMAIL_CHANGE_CALLBACK}?${uri.query}',
      );
      return '${AppRouter.PROFILE}${AppRouter.EMAIL_CHANGE_CALLBACK}?${uri.query}';
    }

    if (uri.toString().contains(AppRouter.RESET_PASSWORD_CALLBACK)) {
      debugPrint(
        '➡️ 检测到重置密码回调,重定向到 ${AppRouter.RESET_PASSWORD_CALLBACK}?${uri.query}',
      );
      return '${AppRouter.RESET_PASSWORD_CALLBACK}?${uri.query}';
    }

    // 未登录且访问受保护路由 -> 重定向到登录页
    if (!isLoggedIn && !publicRoutes.contains(path)) {
      debugPrint('⚠️ 未登录访问受保护路由: $path -> 重定向到登录页');
      return AppRouter.LOGIN;
    }

    // 已登录且访问登录页 -> 重定向到首页
    if (isLoggedIn && (path == AppRouter.LOGIN || path == AppRouter.SIGN_UP)) {
      debugPrint('✅ 已登录访问登录页 -> 重定向到首页');
      return AppRouter.HOME;
    }

    debugPrint('➡️ 无需重定向,继续访问: $path');
    return path;
  }

  /// 创建所有路由
  static List<RouteBase> _createRoutes(List<StatefulShellBranch> branches) {
    return [
      GoRoute(
        path: AppRouter.LOGIN,
        builder: (context, state) => const SigninPage(),
      ),
      GoRoute(
        path: AppRouter.SIGN_UP,
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: AppRouter.PRACTICE,
        builder: (context, state) => const PracticePage(),
      ),
      GoRoute(
        path: AppRouter.EVALUATION,
        builder: (context, state) => const EvaluationPage(),
      ),
      GoRoute(
        path: AppRouter.WELCOME,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRouter.FORGOT,
        builder: (context, state) => const ForgotPage(),
      ),
      GoRoute(
        path: AppRouter.RESET_PASSWORD_CALLBACK,
        builder: (context, state) => const ResetPasswordCallbackPage(),
      ),
      GoRoute(
        path: AppRouter.SETTINGS,
        builder: (context, state) => const ProfileSettings(),
      ),
      GoRoute(
        path: AppRouter.ACCOUNT_SETTINGS,
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => AccountSettingsProvider(),
          child: const AccountSettings(),
        ),
      ),
      GoRoute(
        path: AppRouter.CREATE_GOAL,
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => CreateGoalProvider(),
          child: const CreateGoalPage(),
        ),
      ),
      GoRoute(
        path: AppRouter.PAYWALL,
        redirect: (context, state) => kIsWeb ? AppRouter.DOWNLOAD : null,
        builder: (context, state) => PaywallPage(),
      ),
      GoRoute(
        path: AppRouter.SUBSCRIPTION_MANAGE,
        builder: (context, state) => SubscriptionManagePage(),
      ),
      GoRoute(
        path: AppRouter.DOWNLOAD,
        builder: (context, state) => const DownloadPage(),
      ),
      GoRoute(
        path: AppRouter.LOGIN_CALLBACK,
        builder: (context, state) {
          // OAuth 登录回调处理
          // Supabase 会自动处理回调并触发 AuthStateChange
          // 这里只需要显示加载状态,等待认证完成后自动跳转
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
      GoRoute(
        path: AppRouter.PRIVACY_POLICY,
        builder: (context, state) => const DocumentViewerPage(
          title: 'Privacy Policy',
          assetPath: 'assets/docs/privacy_policy.md',
        ),
      ),
      GoRoute(
        path: AppRouter.TERMS_OF_SERVICE,
        builder: (context, state) => const DocumentViewerPage(
          title: 'Terms of Service',
          assetPath: 'assets/docs/terms_of_service.md',
        ),
      ),
      GoRoute(
        path: AppRouter.ABOUT,
        builder: (context, state) => const DocumentViewerPage(
          title: 'About ToneUp',
          assetPath: 'assets/docs/about.md',
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: branches,
      ),
    ];
  }

  /// 构建错误页面
  static Widget _buildErrorPage(BuildContext context, GoRouterState state) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Page not found'),
              const SizedBox(height: 8),
              Text(
                state.uri.toString(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(AppRouter.HOME),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
