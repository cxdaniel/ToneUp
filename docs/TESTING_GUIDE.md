# 快速测试指南 - 合规文档功能

## 🧪 测试步骤

### 1. 安装依赖并运行应用
```bash
cd /Users/daniel/WorkSpaces/toneup/toneup_app
flutter pub get
flutter run
```

### 2. 测试文档访问

#### 方式A: 通过Profile页面访问
1. 启动应用并登录
2. 导航到 **Profile** 标签页
3. 滚动到底部,找到以下链接:
   - **Terms of Service** (服务条款图标)
   - **Privacy Policy** (隐私政策图标)  
   - **About ToneUp** (关于图标)
4. 依次点击每个链接,验证:
   - ✅ 页面正常打开
   - ✅ Markdown内容正确渲染
   - ✅ 滚动流畅
   - ✅ 文本可选择和复制
   - ✅ 返回按钮工作正常

#### 方式B: 直接路由访问 (可选,用于调试)
在浏览器或深链接中访问:
- `yourapp://privacy-policy`
- `yourapp://terms-of-service`
- `yourapp://about`

### 3. 测试链接功能

#### 内部文档链接
在任一文档中,查找类似 `[Privacy Policy](privacy_policy)` 的链接:
1. 点击链接
2. 验证跳转到对应文档页面
3. 验证返回按钮正常

#### 外部链接
在About文档中,查找外部链接(如 Supabase隐私政策):
1. 点击链接
2. 验证在外部浏览器打开
3. 确认URL正确

#### 邮件链接
在任一文档中,查找邮件链接(如 `support@toneup.app`):
1. 点击链接
2. 验证打开邮件应用
3. 收件人地址正确填充

### 4. 测试主题适配

#### 浅色模式
1. 确保系统设置为浅色模式
2. 打开各文档页面
3. 验证颜色对比度合适
4. 标题、正文、链接颜色清晰可辨

#### 深色模式
1. 切换系统到深色模式
2. 重新打开各文档页面
3. 验证深色主题正确应用
4. 无刺眼白色或对比度过低

### 5. 测试错误处理

#### 场景A: 文件不存在
1. 临时重命名 `assets/docs/privacy_policy.md`
2. 尝试访问Privacy Policy
3. 验证显示错误提示
4. 验证"重试"按钮可用
5. 恢复文件名后重试成功

#### 场景B: 网络问题(外部链接)
1. 关闭网络连接
2. 点击外部链接
3. 验证显示无法打开提示
4. 重新连接网络后正常

### 6. 多平台测试

#### iOS
```bash
flutter run -d iPhone
```
测试要点:
- ✅ 字体渲染清晰
- ✅ 滚动惯性自然
- ✅ 返回手势正常
- ✅ SafeArea正确

#### Android
```bash
flutter run -d Android
```
测试要点:
- ✅ Material Design样式一致
- ✅ 返回按钮功能正常
- ✅ 状态栏颜色适配

#### Web (可选)
```bash
flutter run -d chrome
```
测试要点:
- ✅ 布局响应式
- ✅ 链接可点击
- ✅ 文本可选择

## ✅ 验收标准

### 文档内容
- [ ] 所有三个文档内容完整
- [ ] Markdown格式正确
- [ ] 邮箱地址拼写正确
- [ ] 日期显示为当前日期
- [ ] 版本号与应用一致

### 功能性
- [ ] 所有文档页面可正常打开
- [ ] 内部链接跳转正常
- [ ] 外部链接在浏览器打开
- [ ] 邮件链接打开邮件应用
- [ ] 返回导航正常
- [ ] 加载状态正确显示
- [ ] 错误提示友好

### 用户体验
- [ ] 滚动流畅无卡顿
- [ ] 文本可读性强
- [ ] 链接颜色明显
- [ ] 深浅主题都适配良好
- [ ] 字体大小合适
- [ ] 行间距舒适

### 技术质量
- [ ] 无Lint警告
- [ ] 无运行时错误
- [ ] BuildContext使用正确
- [ ] 异常处理完善
- [ ] 性能良好(无明显延迟)

## 🐛 已知问题

目前暂无已知问题。

## 📋 测试报告模板

```markdown
## 测试报告
**测试日期**: YYYY-MM-DD
**测试人**: [姓名]
**测试平台**: iOS 17.0 / Android 13 / Web

### 测试结果
- Privacy Policy: ✅/❌
- Terms of Service: ✅/❌  
- About ToneUp: ✅/❌
- 内部链接: ✅/❌
- 外部链接: ✅/❌
- 邮件链接: ✅/❌
- 主题适配: ✅/❌
- 错误处理: ✅/❌

### 发现的问题
1. [问题描述]
2. [问题描述]

### 建议
1. [改进建议]
```

## 🚀 快速命令

```bash
# 清理并重新构建
flutter clean && flutter pub get

# 运行在iOS模拟器
flutter run -d "iPhone 15 Pro"

# 运行在Android模拟器
flutter run -d emulator-5554

# 运行在Chrome
flutter run -d chrome

# 检查代码质量
flutter analyze

# 格式化代码
flutter format lib/pages/document_viewer_page.dart

# 查看文档内容
cat assets/docs/privacy_policy.md
cat assets/docs/terms_of_service.md  
cat assets/docs/about.md
```

---

**测试准备时间**: ~5分钟  
**完整测试时间**: ~20分钟  
**建议测试频率**: 每次文档更新后
