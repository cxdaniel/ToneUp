import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/components/mainshell.dart';
import 'package:toneup_app/main.dart';
import 'package:toneup_app/pages/create_goal_page.dart';
import 'package:toneup_app/pages/download_page.dart';
import 'package:toneup_app/pages/paywall.dart';
import 'package:toneup_app/pages/profile_account.dart';
import 'package:toneup_app/pages/evaluation_page.dart';
import 'package:toneup_app/pages/forgot_page.dart';
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
import 'package:toneup_app/services/oauth_service.dart';
import 'package:toneup_app/routes.dart';

/// 配置应用路由
class AppRouter {
  static GoRouter createRouter() {
    final session = Supabase.instance.client.auth.currentSession;
    final initialLocation = session != null ? AppRoutes.HOME : AppRoutes.LOGIN;

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
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final router = GoRouter.of(context);
                    if (router.canPop()) {
                      router.pop();
                    }
                    router.push(AppRoutes.SETTINGS);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      router.push(AppRoutes.ACCOUNT_SETTINGS);
                    });
                  });
                  return const SizedBox.shrink();
                },
              ),
              GoRoute(
                path: 'email-change-callback',
                name: 'email-change-callback',
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

                    if (router.canPop()) {
                      router.pop();
                    }
                    router.push(AppRoutes.SETTINGS);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      router.push(AppRoutes.ACCOUNT_SETTINGS);
                      // 延迟显示提示,确保页面已加载且数据已刷新
                      Future.delayed(const Duration(milliseconds: 500), () {
                        showGlobalSnackBar('邮箱验证成功! 新邮箱已生效', isError: false);
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
    debugPrint('🔀 处理重定向: ${uri.toString()}');
    // 处理账号绑定回调
    if (uri.toString().contains('linking-callback')) {
      final path = uri.path == '/' ? '/linking-callback' : uri.path;
      final newLocation = uri.query.isNotEmpty ? '$path?${uri.query}' : path;
      return '${AppRoutes.PROFILE}$newLocation';
    }
    // 处理邮箱变更回调
    if (uri.toString().contains('email-change-callback')) {
      final path = uri.path == '/' ? '/email-change-callback' : uri.path;
      final newLocation = uri.query.isNotEmpty ? '$path?${uri.query}' : path;
      return '${AppRoutes.PROFILE}$newLocation';
    }
    return null;
  }

  /// 创建所有路由
  static List<RouteBase> _createRoutes(List<StatefulShellBranch> branches) {
    return [
      GoRoute(
        path: AppRoutes.LOGIN,
        builder: (context, state) => const SigninPage(),
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
      GoRoute(
        path: AppRoutes.PAYWALL,
        redirect: (context, state) => kIsWeb ? AppRoutes.DOWNLOAD : null,
        builder: (context, state) => PaywallPage(),
      ),
      GoRoute(
        path: AppRoutes.SUBSCRIPTION_MANAGE,
        builder: (context, state) => SubscriptionManagePage(),
      ),
      GoRoute(
        path: AppRoutes.DOWNLOAD,
        builder: (context, state) => const DownloadPage(),
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
                onPressed: () => context.go(AppRoutes.HOME),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 设置认证状态监听器
void setupAuthStateListener(GoRouter router) {
  Supabase.instance.client.auth.onAuthStateChange.listen(
    (data) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedOut) {
        router.go(AppRoutes.LOGIN);
      } else if (event == AuthChangeEvent.signedIn && session != null) {
        if (OAuthService().isAuthenticating) {
          showGlobalSnackBar('账号绑定成功', isError: false);
        } else {
          final user = session.user;
          _cacheOAuthUserInfo(user);
          router.go(AppRoutes.HOME);
        }
      } else if (event == AuthChangeEvent.userUpdated) {
        await Supabase.instance.client.auth.refreshSession();
        if (OAuthService().isAuthenticating) {
          showGlobalSnackBar('账号绑定成功', isError: false);
        }
      }
    },
    onError: (error) {
      if (error is AuthException) {
        final message = error.message;
        String friendlyMessage;
        if (error.statusCode == 'identity_already_exists' ||
            message.toLowerCase().contains('already linked')) {
          friendlyMessage = '该账号已被其他用户绑定';
        } else if (message.toLowerCase().contains('cancelled')) {
          friendlyMessage = '用户取消了授权';
        } else {
          friendlyMessage = '操作失败: $message';
        }
        showGlobalSnackBar(friendlyMessage, isError: true);
      } else {
        showGlobalSnackBar('操作失败,请重试', isError: true);
      }
    },
  );
}

/// 缓存第三方登录的用户信息
void _cacheOAuthUserInfo(User user) {
  // 此处可添加用户信息缓存逻辑
  // 例如：保存昵称、头像等
}
