# 词典系统快速配置指南

## ⚡️ 5分钟快速启动

### 步骤1: 配置DeepL API (2分钟)

1. **注册DeepL**:
   - 访问: https://www.deepl.com/pro-api
   - 点击 "Sign up for free"
   - 选择 **DeepL API Free** 计划

2. **获取API密钥**:
   - 登录后进入: https://www.deepl.com/account/summary
   - 复制API密钥（格式: `xxxxx-xxxx-xxxx-xxxx-xxxx:fx`）

3. **配置到项目**:
   ```dart
   // 编辑: lib/services/dictionary_api_service.dart (第16行)
   static const String _deepLApiKey = 'your-api-key-here:fx';
   ```

4. **验证配置**:
   ```bash
   flutter run
   # 点击任意播客生词查看翻译
   # 查看日志: ✅ DeepL翻译成功
   ```

### 步骤2: 导入CC-CEDICT词典 (3分钟)

1. **安装Python依赖**:
   ```bash
   pip install requests python-dotenv supabase
   ```

2. **配置Supabase密钥**:
   ```bash
   # 创建 .env 文件
   echo "SUPABASE_URL=https://kixonwnuivnjqlraydmz.supabase.co" > .env
   echo "SUPABASE_SERVICE_KEY=your_service_role_key" >> .env
   ```
   
   **获取Service Key**: 
   - Supabase Dashboard → Settings → API → `service_role` key

3. **运行导入脚本**:
   ```bash
   python scripts/import_cedict.py
   ```
   
   **等待完成**（约2-3分钟）:
   ```
   🎉 导入完成! 共导入 60,000+ 个词条
   ```

4. **验证数据**:
   ```sql
   -- Supabase SQL Editor
   SELECT COUNT(*) FROM dictionary WHERE source = 'cc-cedict';
   -- 应返回: 60000+
   ```

### 完成! 🎉

现在你的词典系统已启用：
- ✅ **英文用户**: 使用60,000+专业CC-CEDICT词条
- ✅ **其他语言**: 使用DeepL高质量翻译（500k字符/月免费）
- ✅ **自动缓存**: 所有查询结果保存到Supabase，逐步建立多语言词库

---

## 📊 监控使用情况

### DeepL配额查询
```bash
curl -X GET "https://api-free.deepl.com/v2/usage" \
  -H "Authorization: DeepL-Auth-Key YOUR_API_KEY"
```

### Supabase词库统计
```sql
-- 总词条数
SELECT COUNT(*) FROM dictionary;

-- 按来源统计
SELECT source, COUNT(*) 
FROM dictionary 
GROUP BY source;

-- 高频词Top 20
SELECT word, frequency, translations->'en'->>'summary' 
FROM dictionary 
ORDER BY frequency DESC 
LIMIT 20;
```

---

## ⚠️ 常见问题

**Q: DeepL返回403错误?**
A: 检查API密钥是否包含`:fx`后缀，确认使用Free API端点

**Q: 英文词条显示空白?**
A: 运行CC-CEDICT导入脚本，确保Supabase有数据

**Q: 配额用完怎么办?**
A: 免费版500k字符/月≈16000次查询，足够初期使用。用完后自动降级到MyMemory API

**Q: 需要升级付费吗?**
A: DeepL Pro仅€5.99/月无限量，用户量大时推荐升级

---

## 📚 详细文档

完整维护指南: [DICTIONARY_MAINTENANCE.md](./DICTIONARY_MAINTENANCE.md)
