import 'package:flutter/material.dart';
import 'package:toneup_app/services/simple_dictionary_service.dart';

/// API词典调试页面
/// 用于测试百度词典版API、清理缓存、执行测试查询
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
        title: const Text('API词典调试'),
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

    final lruData = _cacheStats!['lru'] as Map<String, dynamic>;
    final baiduData = _cacheStats!['baidu_api'] as Map<String, dynamic>;
    final apiConfigured = baiduData['configured'] as bool;

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

            // L1 LRU内存缓存
            _buildStatRow(
              'L1 LRU内存缓存',
              '${lruData['current_size']}/${lruData['max_size']} 条',
            ),

            // L2 SQLite缓存
            _buildStatRow(
              'L2 SQLite缓存',
              '${_cacheStats!['sqlite']['total_entries']} 条',
            ),

            // L4 百度词典版API
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  apiConfigured ? Icons.check_circle : Icons.error,
                  color: apiConfigured ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('L4 百度词典版API', style: theme.textTheme.bodyLarge),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    apiConfigured
                        ? 'API已配置 (仅支持中英互查)'
                        : '⚠️ API未配置（需设置API_KEY和SECRET_KEY）',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: apiConfigured ? Colors.green : Colors.orange,
                      fontWeight: apiConfigured ? FontWeight.bold : null,
                    ),
                  ),
                  if (apiConfigured) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Token缓存: ${baiduData['token_cached'] == true ? "✅ 已缓存" : "⚪ 未缓存"}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (baiduData['token_expires'] != 'N/A')
                      Text(
                        'Token过期: ${baiduData['token_expires']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    Text(
                      '支持语言: ${(baiduData['supported_languages'] as List).join(", ")}',
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
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.speed,
                            size: 12,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'QPS限制: 10次/秒 (建议间隔≥100ms)',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange.shade700,
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
              '清理缓存后，下次查询将直接使用百度词典版API',
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
    final queryTimeMs = _testResult!['query_time_ms'] as int;

    return Card(
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  success ? '✅ API词典工作正常' : '❌ API词典查询失败',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: success ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildResultRow('查询词语', _testResult!['word']),
            _buildResultRow('拼音', _testResult!['pinyin']),
            _buildResultRow('释义', _testResult!['summary']),
            _buildResultRow('词条数', '${_testResult!['entries_count']}'),
            _buildResultRow('查询耗时', '${queryTimeMs}ms'),

            // 显示词条详情
            if (_testResult!.containsKey('entries') &&
                (_testResult!['entries'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              Text(
                '📖 词条详情',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._buildEntriesDetail(theme),
            ],

            if (_testResult!.containsKey('api_configured')) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _testResult!['api_configured'] as bool
                        ? Icons.check_circle_outline
                        : Icons.warning,
                    size: 16,
                    color: _testResult!['api_configured'] as bool
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _testResult!['api_configured'] as bool
                        ? 'API已配置'
                        : 'API未配置',
                    style: TextStyle(
                      fontSize: 12,
                      color: _testResult!['api_configured'] as bool
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
            ],

            if (_testResult!.containsKey('error')) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.shade100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '错误: ${_testResult!['error']}',
                      style: const TextStyle(color: Colors.red),
                    ),
                    if (_testResult!.containsKey('suggestion'))
                      Text(
                        '建议: ${_testResult!['suggestion']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// 构建词条详情列表
  List<Widget> _buildEntriesDetail(ThemeData theme) {
    final entries = _testResult!['entries'] as List;
    final widgets = <Widget>[];

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i] as Map<String, dynamic>;
      final pos = entry['pos'] as String? ?? '';
      final definitions = (entry['definitions'] as List?)?.cast<String>() ?? [];
      final examples = (entry['examples'] as List?)?.cast<String>() ?? [];

      widgets.add(
        Container(
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
              // 词条标题
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '词条 ${i + 1}',
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

              // 定义
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

              // 例句
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
        ),
      );
    }

    return widgets;
  }

  @override
  void dispose() {
    _testWordController.dispose();
    super.dispose();
  }
}
