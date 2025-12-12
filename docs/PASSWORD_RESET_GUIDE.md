# 密码重置功能实现指南

## 功能概述

用户通过 Forgot Password 页面重置密码的完整流程：

1. 用户在 `/forgot` 页面输入邮箱
2. 点击 "Reset Password" 按钮
3. Supabase 发送包含重置链接的邮件
4. 用户在邮件中点击链接
5. 打开 `/reset-password-callback` 页面
6. 用户输入新密码并确认
7. 密码重置成功，根据平台显示不同的后续操作

## 文件结构

### 新增文件
- `lib/pages/reset_password_callback.dart` - 密码重置回调页面

### 修改文件
- `lib/pages/forgot_page.dart` - 添加发送重置邮件逻辑
- `lib/router_config.dart` - 添加重置密码路由
- `lib/services/config.dart` - 添加重置密码回调 URI 配置

## 路由配置

### 公开路由
`/forgot` 和 `/reset-password-callback` 已添加到公开路由列表，无需登录即可访问。

### 回调 URI
- **Web**: `https://app.toneup.top/reset-password-callback/`
- **Mobile**: `io.supabase.toneup://reset-password-callback/`

配置位置: `lib/services/config.dart` → `UriConfig.resetPasswordCallbackUri`

## Supabase 邮件模板配置

### 配置步骤

1. 登录 Supabase Dashboard
2. 进入项目设置: **Authentication → Email Templates**
3. 找到 **"Reset Password"** 模板
4. 修改邮件内容以包含重置链接

### 推荐模板

```html
<h2>Reset Your Password</h2>
<p>Hi there,</p>
<p>We received a request to reset your password for your ToneUp account.</p>
<p>Click the button below to set a new password:</p>
<p><a href="{{ .ConfirmationURL }}" style="display: inline-block; padding: 12px 24px; background-color: #4F46E5; color: white; text-decoration: none; border-radius: 8px;">Reset Password</a></p>
<p>Or copy and paste this URL into your browser:</p>
<p>{{ .ConfirmationURL }}</p>
<p>If you didn't request this, you can safely ignore this email.</p>
<p>This link will expire in 1 hour.</p>
<p>Best regards,<br>The ToneUp Team</p>
```

### 重要变量
- `{{ .ConfirmationURL }}` - Supabase 自动生成的重置链接，包含 token
- 链接格式: `{redirectTo}?token={token}&type=recovery`

## 平台特定行为

### Web 端
- 重置成功后显示 "Go to Login" 按钮
- 点击后跳转到 `/login` 页面
- 用户可以直接用新密码登录

### 移动端 (iOS/Android)
- 重置成功后提示用户返回 App
- 显示 "Open ToneUp App" 按钮
- 点击后尝试通过 Deep Link 打开应用
- 用户在 App 中用新密码登录

## 用户体验优化

### 成功状态
- ✅ 显示成功图标和提示信息
- ✅ 清晰说明下一步操作
- ✅ 根据平台显示不同的操作按钮

### 错误处理
- ❌ 邮箱格式验证
- ❌ Supabase API 错误提示
- ❌ 网络错误处理

### 加载状态
- 🔄 发送邮件时显示加载指示器
- 🔄 重置密码时显示加载指示器
- 🔄 按钮文本变化 (Reset Password → Resetting...)

## 测试流程

### 本地测试 (开发环境)

1. 启动应用: `flutter run`
2. 访问 Forgot Password 页面
3. 输入测试邮箱
4. 检查邮箱收到的重置邮件
5. 点击邮件中的链接
6. 验证是否正确打开重置页面
7. 输入新密码并提交
8. 验证成功提示和后续操作

### 注意事项

- **开发环境**: 邮件可能被标记为垃圾邮件，检查垃圾邮件文件夹
- **Token 过期**: 重置链接默认 1 小时有效
- **重复请求**: 用户可以多次请求重置邮件
- **安全性**: Supabase 自动处理 token 验证和过期

## Supabase Redirect URLs 配置

确保在 Supabase Dashboard 中添加以下 Redirect URLs:

### Authentication → URL Configuration → Redirect URLs

```
# Web
https://app.toneup.top/reset-password-callback/
http://localhost:*
http://127.0.0.1:*

# Mobile
io.supabase.toneup://reset-password-callback/
```

## Deep Link 配置 (移动端)

### iOS (Info.plist)
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>io.supabase.toneup</string>
    </array>
  </dict>
</array>
```

### Android (AndroidManifest.xml)
```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="io.supabase.toneup" />
</intent-filter>
```

## 常见问题

### Q: 为什么邮件中的链接打开后显示 404？
A: 检查 Supabase Redirect URLs 配置是否包含正确的回调地址。

### Q: 密码重置后用户需要重新登录吗？
A: 是的，密码重置会使当前 session 失效，用户需要用新密码登录。

### Q: 可以自定义密码复杂度要求吗？
A: 当前最小长度为 6 个字符，可以在 `reset_password_callback.dart` 的表单验证中修改。

### Q: 如何限制重置邮件发送频率？
A: Supabase 有内置的速率限制，可以在 Dashboard → Authentication → Rate Limits 中配置。

## 后续优化建议

1. **邮件美化**: 使用更精美的 HTML 模板
2. **多语言支持**: 根据用户偏好语言发送不同语言的邮件
3. **密码强度指示器**: 在输入新密码时显示强度提示
4. **Deep Link 优化**: 改进移动端打开 App 的体验
5. **Analytics**: 追踪密码重置流程的完成率
