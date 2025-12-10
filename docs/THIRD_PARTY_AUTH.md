# 第三方登录实现说明

## 概述

ToneUp 应用实现了 Apple Sign In 和 Google Sign In 的原生体验,避免使用浏览器跳转,提供更流畅的用户体验。

## 技术栈

### Apple Sign In
- **包**: `sign_in_with_apple: ^7.0.1`
- **平台支持**: iOS 13+, macOS 10.15+, Web
- **体验**: 原生 UI,无浏览器跳转

### Google Sign In
- **包**: `google_sign_in: ^7.2.0`
- **平台支持**: iOS, Android, Web
- **体验**: iOS/Android 原生 UI,Web 使用 OAuth

## 关键配置

### 1. Supabase 配置

#### Google Provider
**必须开启**: Authentication → Providers → Google → "Skip nonce checks"

原因: `google_sign_in` SDK 会自动生成 nonce 并嵌入到 idToken 中,但我们无法获取原始 nonce 值。开启此选项后,Supabase 会跳过 nonce 验证,允许任意 nonce 的 idToken。

#### Apple Provider
无需特殊配置,iOS 原生环境不使用 nonce。

#### Redirect URLs
添加以下 URL 以支持本地调试:
```
http://localhost:*
http://127.0.0.1:*
io.supabase.toneup://login-callback/
io.supabase.toneup://linking-callback/
```

### 2. iOS 配置 (`ios/Runner/Info.plist`)

```xml
<!-- Google Client ID (iOS Client ID) -->
<key>GIDClientID</key>
<string>YOUR_IOS_CLIENT_ID.apps.googleusercontent.com</string>

<!-- Google Server Client ID (Web Client ID,用于获取 idToken) -->
<key>GIDServerClientID</key>
<string>YOUR_WEB_CLIENT_ID.apps.googleusercontent.com</string>

<!-- URL Schemes -->
<key>CFBundleURLTypes</key>
<array>
    <!-- Supabase Deep Link -->
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>io.supabase.toneup</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>io.supabase.toneup</string>
        </array>
    </dict>
    <!-- Google Sign In REVERSED_CLIENT_ID -->
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### 3. 代码配置 (`lib/services/config.dart`)

```dart
class OAuthConfig {
  // Google OAuth Client IDs
  static String clientIDGoogle = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
  static String serverClientIDGoogle = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
  
  // Apple Service ID (Web only)
  static String clientIDApple = 'YOUR_APPLE_SERVICE_ID';
}
```

## 实现细节

### Google Sign In 7.x API

**关键变化**:
- 使用 `GoogleSignIn.instance` 单例
- 使用 `initialize()` 方法初始化
- 使用 `authenticate()` 方法登录(替代 6.x 的 `signIn()`)
- `idToken` 通过 `googleUser.authentication.idToken` 获取
- `accessToken` 通过 `googleUser.authorizationClient.authorizationForScopes()` 获取

**平台差异**:
```dart
await _googleSignIn.initialize(
  clientId: kIsWeb ? OAuthConfig.clientIDGoogle : null,
  serverClientId: kIsWeb ? null : OAuthConfig.serverClientIDGoogle, // Web 不支持
);
```

### Apple Sign In

**iOS 原生**:
- 不需要传递 nonce
- 直接使用 `identityToken` 验证

**Web**:
- 需要配置 `webAuthenticationOptions`
- 使用 Apple Service ID

## 登录流程

### 移动端 (iOS/Android)

1. **用户点击登录按钮**
2. **调用 `OAuthService.signInWithProvider()`**
   - 优先尝试原生登录 (`NativeAuthService`)
   - 失败时降级到 OAuth 浏览器流程
3. **原生登录流程**:
   - Apple: 弹出系统原生 UI → 获取 identityToken → Supabase 验证
   - Google: 弹出 Google 原生 UI → 获取 idToken + accessToken → Supabase 验证
4. **登录成功,返回用户信息**

### Web 端

1. **用户点击登录按钮**
2. **调用 `OAuthService.signInWithProvider()`**
3. **OAuth 浏览器流程**:
   - 打开 OAuth 授权页面
   - 用户授权后重定向到配置的 callback URL
   - Supabase 处理回调,完成登录

## 账号绑定流程

### Supabase API

Supabase 提供两种账号绑定方式:

1. **OAuth 浏览器流程**: `linkIdentity(provider)`
   - 需要打开浏览器完成授权
   - Web 端必须使用此方式

2. **原生 Token 绑定**: `linkIdentityWithIdToken(provider, idToken, accessToken)` ✅
   - 使用原生 SDK 获取的 idToken 直接绑定
   - 体验与原生登录一致,无浏览器跳转
   - iOS/Android 优先使用此方式

### 移动端账号绑定

1. **用户在设置页面点击绑定按钮**
2. **调用 `AccountSettingsProvider.linkApple()` 或 `linkGoogle()`**
3. **原生绑定流程** (`NativeAuthService`):
   - Apple: 弹出系统原生 UI → 获取 identityToken → `linkIdentityWithIdToken`
   - Google: 弹出 Google 原生 UI → 获取 idToken + accessToken → `linkIdentityWithIdToken`
4. **绑定成功,auth state change 事件触发自动刷新**

### Web 端账号绑定

1. **用户在设置页面点击绑定按钮**
2. **调用 `OAuthService.linkAppleAccount()` 或 `linkGoogleAccount()`**
3. **OAuth 浏览器流程**:
   - 打开 OAuth 授权页面 (with `authScreenLaunchMode`)
   - 用户授权后重定向到 `io.supabase.toneup://linking-callback/`
   - Supabase 处理回调,完成绑定


## 常见问题

### Q: 为什么 Google 需要开启 "Skip nonce checks"?

A: `google_sign_in` SDK 在生成 idToken 时会自动添加 nonce,但这个 nonce 是 SDK 内部生成的,我们无法获取原始值。Supabase 的 `signInWithIdToken()` 需要验证 nonce 一致性,但我们只能从 idToken 中提取到 SHA256 哈希后的值,无法传递原始值。开启 "Skip nonce checks" 后,Supabase 会跳过这个验证。

### Q: Apple Sign In 为什么不需要 nonce?

A: iOS 原生环境中,Apple 的 identityToken 不包含 nonce 字段,Supabase 可以直接验证 identityToken 的签名。只有在 Web 环境下才需要使用 nonce 来防止重放攻击。

### Q: Web 端为什么不能传递 serverClientId?

A: `google_sign_in_web` 包不支持 `serverClientId` 参数,尝试传递会抛出断言错误。Web 端只需要 `clientId` 即可。

### Q: 如何固定 Flutter Web 调试端口?

A: 使用命令 `flutter run -d chrome --web-port=8080` 或在 Supabase 配置通配符 `http://localhost:*`。

## 测试清单

### iOS
- [ ] Apple 原生登录成功
- [ ] Google 原生登录成功
- [ ] 用户取消登录时正确处理
- [ ] 登录失败时显示错误信息
- [ ] 登出功能正常

### Android
- [ ] Google 原生登录成功
- [ ] OAuth 降级流程正常
- [ ] 登出功能正常

### Web
- [ ] Apple OAuth 流程正常
- [ ] Google OAuth 流程正常
- [ ] 回调 URL 正确处理
- [ ] 本地调试端口通配符生效

## 参考资源

- [Google Sign-In Package](https://pub.dev/packages/google_sign_in)
- [Sign in with Apple Package](https://pub.dev/packages/sign_in_with_apple)
- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [Google OAuth 2.0 Configuration](https://console.cloud.google.com/)
- [Apple Developer Portal](https://developer.apple.com/)
