# ToneUp 合规文档维护指南

## 📁 文档结构

```
assets/docs/
├── privacy_policy.md      # 隐私政策
├── terms_of_service.md    # 服务条款
└── about.md               # 关于页面
```

## 📝 文档说明

### 1. Privacy Policy (隐私政策)
**文件**: `assets/docs/privacy_policy.md`
**路由**: `/privacy-policy`
**用途**: App Store和Google Play上架必需文档

**包含内容**:
- 数据收集说明
- 数据使用方式
- 第三方服务声明(Supabase, RevenueCat, Apple/Google Sign In)
- 用户权利说明
- 数据安全措施
- 儿童隐私保护
- GDPR/CCPA合规性

**更新时机**:
- ✅ 添加新的数据收集功能
- ✅ 集成新的第三方服务
- ✅ 改变数据使用方式
- ✅ 法律法规变更

### 2. Terms of Service (服务条款)
**文件**: `assets/docs/terms_of_service.md`
**路由**: `/terms-of-service`
**用途**: 明确用户协议和法律责任

**包含内容**:
- 账户注册规则
- 订阅和支付条款(含7天免费试用)
- 用户行为规范
- 知识产权声明
- 服务可用性
- 责任限制
- 争议解决机制

**更新时机**:
- ✅ 修改订阅价格或条款
- ✅ 添加/删除功能
- ✅ 改变退款政策
- ✅ 法律要求变更

### 3. About (关于ToneUp)
**文件**: `assets/docs/about.md`
**路由**: `/about`
**用途**: 产品介绍和联系信息

**包含内容**:
- 应用简介和使命
- 功能列表
- Pro订阅说明
- 版本信息
- 联系方式
- 常见问题
- 技术栈说明

**更新时机**:
- ✅ 版本更新
- ✅ 添加新功能
- ✅ 联系信息变更
- ✅ 团队信息更新

## 🔄 维护工作流程

### 本地测试
1. 编辑Markdown文件
2. 运行应用: `flutter run`
3. 导航到Profile页面
4. 点击相应文档链接查看效果

### 发布前检查清单
- [ ] 更新"Last Updated"日期
- [ ] 检查所有链接是否有效
- [ ] 确认邮箱地址正确
- [ ] 验证法律条款准确性
- [ ] 多设备测试(iOS/Android/Web)
- [ ] 检查Markdown渲染效果

### 版本管理
每次重大更新时:
1. 在文档顶部更新日期
2. 在Git中提交更新: `git commit -m "docs: update privacy policy v1.1"`
3. 保留旧版本副本(可选): `privacy_policy_v1.0.md`

## 📱 应用集成说明

### 路由配置
文档路由已在 `lib/router_config.dart` 中配置:

```dart
static const PRIVACY_POLICY = '/privacy-policy';
static const TERMS_OF_SERVICE = '/terms-of-service';
static const ABOUT = '/about';
```

### 访问入口
**Profile页面** (`lib/pages/profile_page.dart`):
- Terms of Service
- Privacy Policy  
- About ToneUp

这些入口无需登录即可访问(已添加到公开路由列表)。

### 文档查看器
**组件**: `lib/pages/document_viewer_page.dart`

**特性**:
- ✅ Markdown渲染
- ✅ 深色/浅色主题适配
- ✅ 可选择文本
- ✅ 内部文档链接导航
- ✅ 外部链接打开
- ✅ 邮件链接支持
- ✅ 加载状态和错误处理

## 🌐 多语言支持(未来扩展)

如需添加中文版本:
```
assets/docs/
├── en/
│   ├── privacy_policy.md
│   ├── terms_of_service.md
│   └── about.md
└── zh/
    ├── privacy_policy.md
    ├── terms_of_service.md
    └── about.md
```

然后根据用户语言设置动态加载相应文件。

## 🔒 App Store Connect配置

### 上架时填写
1. **App Store Connect → App Information → Privacy Policy URL**
   - 填写: `https://toneup.app/privacy-policy` (需部署Web版本)
   - 或: 在App Store Connect中上传隐私政策文本

2. **App Privacy Details**
   - 根据 `privacy_policy.md` 中声明的数据收集填写
   - 数据类型: Contact Info, User Content, Usage Data等

3. **Support URL**
   - 填写: `https://toneup.app/support`
   - 确保About文档中的联系邮箱有效

## 📧 联系邮箱配置

当前使用的邮箱(需要配置):
- `privacy@toneup.app` - 隐私相关
- `support@toneup.app` - 用户支持
- `legal@toneup.app` - 法律事务
- `feedback@toneup.app` - 功能反馈
- `bugs@toneup.app` - Bug报告
- `partnerships@toneup.app` - 合作洽谈
- `press@toneup.app` - 媒体联系
- `hello@toneup.app` - 通用咨询

**TODO**: 在域名提供商处配置邮箱转发或设置专用邮箱服务。

## ⚠️ 法律声明

**重要**: 这些文档模板仅供参考,不构成法律建议。在正式发布前:

1. ✅ 咨询专业律师审核
2. ✅ 确保符合目标市场的法律法规
3. ✅ 验证第三方服务的隐私政策链接
4. ✅ 定期审查并更新(建议每6-12个月)

## 📚 相关资源

### App Store
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Privacy Requirements](https://developer.apple.com/app-store/app-privacy-details/)

### Google Play
- [Developer Policy Center](https://play.google.com/about/developer-content-policy/)
- [User Data Policy](https://support.google.com/googleplay/android-developer/answer/9888076)

### 合规工具
- [Termly](https://termly.io/) - 隐私政策生成器
- [TermsFeed](https://www.termsfeed.com/) - 服务条款生成器
- [iubenda](https://www.iubenda.com/) - 全面合规解决方案

## 🚀 快速命令

```bash
# 查看文档
cat assets/docs/privacy_policy.md

# 编辑文档
code assets/docs/privacy_policy.md

# 验证Markdown格式
# 使用VS Code Markdown预览: Cmd+Shift+V

# 运行应用测试
flutter run

# 构建发布版本
flutter build ios --release
flutter build apk --release
```

## 📝 更新日志

| 版本 | 日期 | 变更内容 |
|------|------|---------|
| 1.0 | 2024-12-11 | 初始版本,创建所有基础文档 |

---

**维护者**: ToneUp Development Team  
**最后更新**: 2024-12-11
