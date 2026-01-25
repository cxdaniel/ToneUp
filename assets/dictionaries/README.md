# MDX 词典占位文件

此目录用于存放 MDX 格式的离线**汉英词典**文件。

**⚠️ 重要**：ToneUp 是中文学习APP，需要下载**汉英词典**（Chinese→English），不是英汉词典！

## 快速开始

1. **下载推荐词典**（任选其一）：
   - **CC-CEDICT**（~8MB）：免费开源，适合快速测试
     - 下载：https://freemdict.com/ 搜索 "CC-CEDICT"
   
   - **新时代汉英大词典**（~150MB）：专业推荐
     - 下载：https://www.pdawiki.com/forum/ 搜索 "汉英"

2. 将 `.mdx` 文件放入此目录

3. 重新运行应用：`flutter run`

## 测试查询

下载词典后，可以测试：
- 查询"你好" → 应返回 "hello; hi"
- 查询"学习" → 应返回 "to study; to learn"

## 详细指南

查看完整文档：[docs/MDX_DICTIONARY_GUIDE.md](../../docs/MDX_DICTIONARY_GUIDE.md)

## 词典资源

- **FreeMDict**: https://freemdict.com/ (搜索 "Chinese English")
- **掌上百科**: https://www.pdawiki.com/forum/ (搜索 "汉英")

---

**注意**：词典文件较大，已在 `.gitignore` 中排除，不会提交到代码仓库。
