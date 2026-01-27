import 'package:flutter/material.dart';
import 'package:toneup_app/services/simple_dictionary_service.dart';

/// 词典系统调试页面
/// 用于测试 Coze AI 词典（Edge Function）、清理缓存、执行测试查询
class DictionaryDebugPage extends StatefulWidget {
  const DictionaryDebugPage({super.key});

  @override
  State<DictionaryDebugPage> createState() => _DictionaryDebugPageState();
}

class _DictionaryDebugPageState extends State<DictionaryDebugPage> {
  final _dictionaryService = SimpleDictionaryService();
  final _testWordController = TextEditingController(text: '你好');

  Map<String, dynamic>? _cacheStats;
  Map<String, dynamic>? _testResult;
  bool _isLoading = false;
  String _selectedLanguage = 'en'; // 默认英语

  @override
  void initState() {
    super.initState();
    _loadCacheStats();
  }

  /// 加载缓存统计
  Future<void> _loadCacheStats() async {
    setState(() => _isLoading = true);
    final stats = await _dictionaryService.getCacheStats();
    setState(() {
      _cacheStats = stats;
      _isLoading = false;
    });
  }

  /// 清理缓存
  Future<void> _clearCache({bool clearSupabase = false}) async {
    setState(() => _isLoading = true);
    await _dictionaryService.clearAllCache(clearSupabase: clearSupabase);
    await _loadCacheStats();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(clearSupabase ? '所有缓存已清空（包括云端）' : '本地缓存已清空'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// 测试API词典
  Future<void> _testDictionary() async {
    setState(() {
      _isLoading = true;
      _testResult = null;
    });

    final result = await _dictionaryService.testApiDictionary(
      testWord: _testWordController.text.trim(),
      language: _selectedLanguage,
    );

    setState(() {
      _testResult = result;
      _isLoading = false;
    });

    await _loadCacheStats();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('词典系统调试'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 缓存状态卡片
                  _buildCacheStatsCard(theme),
                  const SizedBox(height: 16),

                  // 清理缓存按钮
                  _buildClearCacheSection(theme),
                  const SizedBox(height: 16),

                  // 测试查询
                  _buildTestQuerySection(theme),
                  const SizedBox(height: 16),

                  // 测试结果
                  if (_testResult != null) _buildTestResultCard(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildCacheStatsCard(ThemeData theme) {
    if (_cacheStats == null) {
      return const Card(
        child: Padding(padding: EdgeInsets.all(16), child: Text('正在加载缓存统计...')),
      );
    }

    final lruData = _cacheStats!['lru'] as Map<String, dynamic>? ?? {};
    final sqliteData = _cacheStats!['sqlite'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('缓存状态', style: theme.textTheme.titleLarge),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // 架构说明
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(77),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.architecture,
                        size: 16,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '四级缓存架构',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'L1 → L2 → L3 (Supabase + Coze AI) → L4 (拼音降级)',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onPrimaryContainer.withAlpha(
                        204,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // L1 LRU内存缓存
            _buildStatRow(
              'L1 LRU内存缓存',
              '${lruData['current_size']}/${lruData['max_size']} 条',
            ),

            // L2 SQLite缓存
            _buildStatRow('L2 SQLite缓存', '${sqliteData['total_entries']} 条'),

            const SizedBox(height: 8),

            // L3 Edge Function + Coze AI
            Row(
              children: [
                Icon(Icons.cloud, color: theme.colorScheme.tertiary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'L3 Supabase + Edge Function',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ 已启用 Coze AI 词典工作流',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Edge Function: translate-word',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '支持语言: en, zh, ja, ko, es, fr, de',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.smart_toy,
                          size: 12,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'AI生成 + 自动缓存到云端数据库',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // L4 拼音降级
            Row(
              children: [
                Icon(Icons.text_fields, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text('L4 拼音降级方案', style: theme.textTheme.bodyLarge),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 4),
              child: Text(
                '所有查询失败时的兜底方案',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildClearCacheSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cleaning_services, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Text('清理缓存', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '清理缓存后，下次查询将通过 Edge Function 调用 Coze AI 生成',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _clearCache(clearSupabase: false),
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('清空本地缓存'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.errorContainer,
                      foregroundColor: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _clearCache(clearSupabase: true),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('含云端'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestQuerySection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.search, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('测试查询', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _testWordController,
              decoration: const InputDecoration(
                labelText: '输入测试词语',
                hintText: '例如: 你好, 学习, 中国',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: '目标语言',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.language),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'en',
                      child: Text('🇺🇸 English (英语)'),
                    ),
                    DropdownMenuItem(value: 'zh', child: Text('🇨🇳 简体中文')),
                    DropdownMenuItem(value: 'ja', child: Text('🇯🇵 日本語 (日语)')),
                    DropdownMenuItem(value: 'ko', child: Text('🇰🇷 한국어 (韩语)')),
                    DropdownMenuItem(
                      value: 'es',
                      child: Text('🇪🇸 Español (西班牙语)'),
                    ),
                    DropdownMenuItem(
                      value: 'fr',
                      child: Text('🇫🇷 Français (法语)'),
                    ),
                    DropdownMenuItem(
                      value: 'de',
                      child: Text('🇩🇪 Deutsch (德语)'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedLanguage = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _testDictionary,
                icon: const Icon(Icons.play_arrow),
                label: const Text('执行测试'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultCard(ThemeData theme) {
    final success = _testResult!['success'] as bool;
    final queryTimeMs = _testResult!['query_time_ms'] as int? ?? 0;
    final entries = _testResult!['entries'] as List? ?? [];

    return Card(
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  success ? '✅ 词典系统工作正常' : '❌ 词典查询失败',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: success ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),

            // 基础信息卡片
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 词语 + 拼音
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _testResult!['word'],
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _testResult!['pinyin'],
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer.withAlpha(
                            204,
                          ),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 概要释义
                  if (_testResult!['summary'] != null &&
                      _testResult!['summary'].toString().isNotEmpty)
                    Text(
                      _testResult!['summary'],
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),

                  const SizedBox(height: 12),

                  // 元数据行
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      // HSK等级
                      if (_testResult!['hsk_level'] != null)
                        _buildMetaChip(
                          theme,
                          Icons.school,
                          'HSK ${_testResult!['hsk_level']}',
                          Colors.purple,
                        ),
                      // 词条数
                      _buildMetaChip(
                        theme,
                        Icons.article,
                        '${entries.length} 词条',
                        Colors.blue,
                      ),
                      // 查询耗时
                      _buildMetaChip(
                        theme,
                        Icons.timer,
                        '${queryTimeMs}ms',
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 词条详情列表
            if (entries.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '词条详情',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...entries.asMap().entries.map((mapEntry) {
                final index = mapEntry.key;
                final entry = mapEntry.value as Map<String, dynamic>;
                return _buildEntryCard(theme, entry, index + 1);
              }),
            ],

            // 数据源标识
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_done, size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Text(
                    '数据源: Edge Function (Coze AI)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // 错误信息
            if (_testResult!.containsKey('error')) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '错误详情',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _testResult!['error'],
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 12,
                      ),
                    ),
                    if (_testResult!.containsKey('suggestion')) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.orange.shade700,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _testResult!['suggestion'],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建元数据芯片
  Widget _buildMetaChip(
    ThemeData theme,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(102)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个词条卡片
  Widget _buildEntryCard(
    ThemeData theme,
    Map<String, dynamic> entry,
    int index,
  ) {
    final pos = entry['pos'] as String? ?? '';
    final definitions = (entry['definitions'] as List?)?.cast<String>() ?? [];
    final examples = (entry['examples'] as List?)?.cast<String>() ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 词条标题（序号 + 词性）
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '词条 $index',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              if (pos.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    pos,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // 释义列表
          if (definitions.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...definitions.asMap().entries.map((defEntry) {
              return Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${defEntry.key + 1}. ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        defEntry.value,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // 例句列表
          if (examples.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer.withAlpha(77),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.format_quote,
                        size: 14,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '例句',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...examples.map((example) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '• $example',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _testWordController.dispose();
    super.dispose();
  }
}
