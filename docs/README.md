# ToneUp App - 文档索引

> **项目**: ToneUp - 中文学习应用  
> **文档更新**: 2026年1月11日  
> **维护**: 项目负责人

---

## 📚 完整文档清单

### 核心架构文档

#### 1. [PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md)
**用途**: 项目全局架构与业务逻辑完整参考  
**适合人群**: 新开发者、AI助手、项目管理者

**包含内容**:
- ✅ 项目概述（技术栈、平台支持）
- ✅ HSK学习系统与15维能力指标
- ✅ Provider状态管理架构
- ✅ 数据库表结构概览
- ✅ 订阅系统流程（RevenueCat + Supabase）
- ✅ 用户体验流程与导航结构
- ✅ 商业化策略（Freemium模型）
- ✅ 开发路线图

**快速查找**:
- 技术栈版本 → "项目概述"
- 能力指标分类 → "核心产品定位"
- Provider职责 → "技术架构 - Provider状态管理"
- 订阅流程 → "核心业务模型 - 订阅系统流程"

---

#### 2. [DATA_MODELS.md](./DATA_MODELS.md)
**用途**: 所有数据模型、枚举类型、数据表结构快速查找手册  
**适合人群**: 后端开发、数据库管理、前端数据绑定

**包含内容**:
- ✅ 15种枚举类型详解（IndicatorCategory, MaterialContentType等）
- ✅ 核心数据模型（ProfileModel, SubscriptionModel, UserWeeklyPlanModel等）
- ✅ 数据库表结构（字段、索引、约束）
- ✅ 表关系图与外键约束
- ✅ 视图与RPC函数定义
- ✅ 数据查询示例代码

**快速查找**:
- 枚举定义 → "枚举类型 (Enums)"
- 模型字段 → "核心数据模型 (Models)"
- 表结构 → "数据库表结构 (Database Tables)"
- RPC函数 → "视图与RPC函数"

---

#### 2.1. [DICTIONARY_DATA_STRUCTURE.md](./DICTIONARY_DATA_STRUCTURE.md) ⭐新增
**用途**: 词典数据结构标准规范（扣子工作流返回格式）  
**适合人群**: AI工作流配置、后端开发、数据验证

**包含内容**:
- ✅ WordDetailModel完整字段说明
- ✅ 扣子工作流标准输出格式
- ✅ 词性标注规范速查表
- ✅ 多语种支持示例
- ✅ Supabase存储格式
- ✅ 推荐的AI Prompt模板
- ✅ 数据验证规则

**快速查找**:
- JSON格式 → "核心数据模型 - WordDetailModel"
- 词性缩写 → "词性标注规范"
- Prompt模板 → "扣子工作流Prompt模板"
- 快速参考 → 见 [COZE_DICTIONARY_QUICK_REF.md](./COZE_DICTIONARY_QUICK_REF.md)

---

#### 3. [API_REFERENCE.md](./API_REFERENCE.md)
**用途**: Supabase、RevenueCat、TTS等所有API完整调用指南  
**适合人群**: 前端开发、集成测试、API调试

**包含内容**:
- ✅ DataService所有方法详解（参数、返回值、示例）
- ✅ Supabase Edge Functions（create-plan, check_for_upgrade等）
- ✅ Supabase RPC函数（activate_plan, increment_practice_count等）
- ✅ RevenueCat订阅API（购买、查询、同步）
- ✅ 火山引擎TTS API
- ✅ 第三方认证API（Apple, Google）
- ✅ 错误处理与速率限制

**快速查找**:
- 数据库查询 → "Supabase 数据库 API"
- 计划生成 → "Supabase Edge Functions - create-plan"
- 订阅购买 → "RevenueCat API - purchasePackage"
- TTS合成 → "火山引擎 TTS API"

---

### 功能设计文档

#### 4. [PODCAST_FEATURE_DESIGN.md](./PODCAST_FEATURE_DESIGN.md)
**用途**: Podcast学习功能完整设计方案（待实施）  
**适合人群**: 产品经理、功能开发、AI内容生产

**包含内容**:
- ✅ 产品定位与竞品分析
- ✅ 数据库表设计（media_content, user_media_progress等）
- ✅ 内容生产策略（管理员+UGC+AIGC三阶段）
- ✅ 版权合规方案（Safe Harbor, Fair Use）
- ✅ AIGC自动化流水线（7步流程，成本分析）
- ✅ UI/UX设计（页面结构、交互流程）
- ✅ 技术实现方案（Provider架构、音频播放器）
- ✅ 实施路线图（Phase 1-3）

**快速查找**:
- 数据库设计 → "数据库设计"
- AIGC流程 → "AIGC 自动化流水线"
- 成本分析 → "AIGC 自动化流水线 - 成本分析"
- 实施时间表 → "实施路线图"

---

### 开发指南文档

#### 5. [THIRD_PARTY_AUTH.md](./THIRD_PARTY_AUTH.md)
**用途**: Apple/Google第三方登录实现细节  
**适合人群**: 认证功能开发、Bug修复

**包含内容**:
- ✅ Apple Sign In配置与实现
- ✅ Google Sign In配置（含nonce问题解决）
- ✅ 账号绑定流程（移动端原生 vs Web OAuth）
- ✅ Deep Link处理
- ✅ 错误处理与调试

**快速查找**:
- Apple登录 → "Apple Sign In"
- Google配置 → "Google Sign In - Supabase配置"
- 账号绑定 → "Account Linking Strategy"

---

#### 6. [TESTING_GUIDE.md](./TESTING_GUIDE.md)
**用途**: 测试策略与用例  
**适合人群**: QA测试、持续集成

**包含内容**:
- ✅ 单元测试用例
- ✅ Widget测试示例
- ✅ 集成测试流程
- ✅ 订阅测试（沙盒环境）

**快速查找**:
- 订阅测试 → "订阅功能测试"
- 测试命令 → "运行测试"

---

#### 7. [WEB_DEPLOYMENT.md](./WEB_DEPLOYMENT.md)
**用途**: Web平台部署指南（Netlify）  
**适合人群**: DevOps、Web发布

**包含内容**:
- ✅ Netlify配置
- ✅ 构建命令
- ✅ 路由重定向规则
- ✅ 环境变量设置

**快速查找**:
- 部署步骤 → "部署流程"
- 路由配置 → "重定向规则"

---

### 运维与规范文档

#### 8. [.github/copilot-instructions.md](../.github/copilot-instructions.md)
**用途**: AI编程助手工作流规范  
**适合人群**: GitHub Copilot用户、AI协作开发

**包含内容**:
- ✅ 项目概述与技术栈
- ✅ 架构模式（Provider + Service）
- ✅ 平台适配规范
- ✅ 订阅系统流程
- ✅ 配置管理
- ✅ 常见问题排查
- ✅ 代码规范

**快速查找**:
- 平台检测 → "Platform-Specific Design"
- 订阅流程 → "Subscription Flow Architecture"
- 错误排查 → "Common Pitfalls & Solutions"

---

#### 9. [COMPLIANCE_DOCS_GUIDE.md](./COMPLIANCE_DOCS_GUIDE.md)
**用途**: 隐私政策、用户协议等合规文档管理  
**适合人群**: 法务、产品发布

**包含内容**:
- ✅ 隐私政策模板
- ✅ 服务条款
- ✅ 关于页面

**快速查找**:
- 文档位置 → "文档结构"
- 更新流程 → "维护规范"

---

#### 10. [PASSWORD_RESET_GUIDE.md](./PASSWORD_RESET_GUIDE.md)
**用途**: 密码重置功能实现指南  
**适合人群**: 认证功能开发

**包含内容**:
- ✅ 邮件发送流程
- ✅ Deep Link配置
- ✅ 回调页面处理

---

## 🗂️ 文档分类索引

### 按角色查找

**产品经理**:
- [PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md) - 产品定位与业务逻辑
- [PODCAST_FEATURE_DESIGN.md](./PODCAST_FEATURE_DESIGN.md) - 新功能设计

**前端开发**:
- [PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md) - Provider架构
- [DATA_MODELS.md](./DATA_MODELS.md) - 数据模型绑定
- [API_REFERENCE.md](./API_REFERENCE.md) - API调用

**后端开发**:
- [DATA_MODELS.md](./DATA_MODELS.md) - 数据库设计
- [API_REFERENCE.md](./API_REFERENCE.md) - RPC函数、Edge Functions

**DevOps**:
- [WEB_DEPLOYMENT.md](./WEB_DEPLOYMENT.md) - Web部署
- [TESTING_GUIDE.md](./TESTING_GUIDE.md) - CI/CD集成

**QA测试**:
- [TESTING_GUIDE.md](./TESTING_GUIDE.md) - 测试用例
- [API_REFERENCE.md](./API_REFERENCE.md) - API调试

**AI助手/新开发者**:
- [PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md) - **首选阅读**
- [.github/copilot-instructions.md](../.github/copilot-instructions.md) - 工作流规范

---

### 按主题查找

**认证与授权**:
- [THIRD_PARTY_AUTH.md](./THIRD_PARTY_AUTH.md) - 第三方登录
- [PASSWORD_RESET_GUIDE.md](./PASSWORD_RESET_GUIDE.md) - 密码重置
- [API_REFERENCE.md](./API_REFERENCE.md) → "第三方认证 API"

**订阅系统**:
- [PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md) → "商业化策略"
- [API_REFERENCE.md](./API_REFERENCE.md) → "RevenueCat API"
- [.github/copilot-instructions.md](../.github/copilot-instructions.md) → "Subscription Flow"

**数据库**:
- [DATA_MODELS.md](./DATA_MODELS.md) - **完整参考**
- [PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md) → "数据库结构"

**Podcast功能**:
- [PODCAST_FEATURE_DESIGN.md](./PODCAST_FEATURE_DESIGN.md) - **完整设计**

**部署发布**:
- [WEB_DEPLOYMENT.md](./WEB_DEPLOYMENT.md) - Web
- [TESTING_GUIDE.md](./TESTING_GUIDE.md) - 测试
- [COMPLIANCE_DOCS_GUIDE.md](./COMPLIANCE_DOCS_GUIDE.md) - 合规

---

## 🔧 文档使用建议

### 第一次接触项目？
**推荐阅读顺序**:
1. [PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md) - 理解全局架构（30分钟）
2. [.github/copilot-instructions.md](../.github/copilot-instructions.md) - 开发规范（15分钟）
3. [DATA_MODELS.md](./DATA_MODELS.md) - 数据结构（20分钟）
4. [API_REFERENCE.md](./API_REFERENCE.md) - API使用（按需查阅）

### 开发特定功能？
- **用户认证**: THIRD_PARTY_AUTH.md + API_REFERENCE.md
- **学习计划**: PROJECT_OVERVIEW.md + DATA_MODELS.md + API_REFERENCE.md
- **订阅购买**: PROJECT_OVERVIEW.md + API_REFERENCE.md (RevenueCat部分)
- **Podcast**: PODCAST_FEATURE_DESIGN.md（完整指南）

### 遇到问题？
1. **错误排查**: .github/copilot-instructions.md → "Common Pitfalls"
2. **API错误**: API_REFERENCE.md → "API错误处理"
3. **数据查询**: DATA_MODELS.md → "数据查询示例"

---

## 📝 文档维护规范

### 更新频率
- **PROJECT_OVERVIEW.md**: 每月审核，重大变更立即更新
- **DATA_MODELS.md**: 数据库迁移后同步更新
- **API_REFERENCE.md**: 新增API后7天内补充
- **PODCAST_FEATURE_DESIGN.md**: 设计变更时更新

### 版本控制
- 所有文档纳入Git版本管理
- 重大更新需在文档头部记录版本号和日期
- 使用语义化版本号: v1.0, v1.1, v2.0

### 责任人
- **核心架构文档**: 项目技术负责人
- **功能设计文档**: 产品经理 + 技术负责人
- **开发指南**: 相关功能开发者

---

## 🚀 快速链接

- **GitHub仓库**: [ToneUp App](https://github.com/your-repo/toneup_app)
- **Supabase Dashboard**: https://supabase.com/dashboard
- **RevenueCat Dashboard**: https://app.revenuecat.com
- **Figma设计稿**: [待添加链接]
- **Netlify部署**: https://toneup.netlify.app

---

**最后更新**: 2026年1月11日  
**文档总数**: 10份  
**覆盖范围**: 架构设计、数据模型、API参考、功能设计、开发指南、运维规范

**📌 提示**: 本索引文件应始终保持最新。添加新文档后，请同步更新此索引。
