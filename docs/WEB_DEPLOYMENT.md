# 手动部署Web版本到Netlify

## 🚀 部署步骤

### 1. 构建Web版本
```bash
flutter build web --release --wasm
```

### 2. 部署到Netlify
1. 访问 [Netlify Dashboard](https://app.netlify.com)
2. 找到你的ToneUp站点
3. 点击 "Deploys" 标签
4. 拖拽 `build/web` 文件夹到上传区域
5. 等待部署完成

## 📋 部署后验证

确保以下URL可以正常访问:

- ✅ Privacy Policy: `https://your-site.netlify.app/privacy-policy`
- ✅ Terms of Service: `https://your-site.netlify.app/terms-of-service`
- ✅ About: `https://your-site.netlify.app/about`

## 📝 应用商店配置

### App Store Connect
在 App Store Connect → App Information 中填写:
- **Privacy Policy URL**: `https://your-site.netlify.app/privacy-policy`
- **Support URL**: `https://your-site.netlify.app/about`

### Google Play Console
在 Play Console → Store presence → Privacy Policy 中填写:
- **Privacy Policy**: `https://your-site.netlify.app/privacy-policy`

## 🔄 更新文档流程

当你需要更新合规文档时:

1. **编辑Markdown文件**:
   ```bash
   code assets/docs/privacy_policy.md
   code assets/docs/terms_of_service.md
   code assets/docs/about.md
   ```

2. **测试本地效果**:
   ```bash
   flutter run -d chrome
   # 导航到Profile → 点击相应文档链接查看
   ```

3. **重新构建Web**:
   ```bash
   flutter build web --release --wasm
   ```

4. **部署到Netlify** (按上述步骤2)

5. **验证线上版本** (访问上述URL)

## ⏰ 部署时机

建议在以下情况部署:

- ✅ 初次上架前 (必须)
- ✅ 文档内容更新后
- ✅ 添加新功能涉及隐私/条款变更
- ✅ 法律要求变更
- ✅ 联系信息变更

## 💡 提示

- Netlify免费版每月有300次构建分钟
- 手动拖拽部署不计入构建分钟
- 只有内容更新才需要重新部署
- Web版本体积: ~20MB (压缩后)

## 🆘 常见问题

### Q: 部署后文档显示404?
A: 确保 `web/_redirects` 文件存在且内容正确:
```
/*    /index.html   200
```

### Q: 文档内容没有更新?
A: 清除浏览器缓存或使用隐私模式访问

### Q: 想测试但不想消耗部署次数?
A: 使用本地预览:
```bash
flutter build web --release
cd build/web
python3 -m http.server 8000
# 访问 http://localhost:8000/privacy-policy
```

---

**最后更新**: 2024-12-11
