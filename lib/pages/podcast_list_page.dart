import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toneup_app/components/components.dart';
import 'package:toneup_app/models/media_content_model.dart';
import 'package:toneup_app/services/media_service.dart';
import 'package:toneup_app/router_config.dart';

/// 播客列表页面
class PodcastListPage extends StatefulWidget {
  const PodcastListPage({super.key});

  @override
  State<PodcastListPage> createState() => _PodcastListPageState();
}

class _PodcastListPageState extends State<PodcastListPage> {
  final MediaService _mediaService = MediaService();
  List<MediaContentModel> _podcasts = [];
  bool _isLoading = true;
  String? _errorMessage;
  late ThemeData theme;

  // 筛选条件
  int? _selectedHskLevel;
  String? _selectedTopic;

  @override
  void initState() {
    super.initState();
    _loadPodcasts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  /// 加载播客列表
  Future<void> _loadPodcasts() async {
    if (mounted) {
      LoadingOverlay.show(context, label: 'Loading podcasts...');
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final podcasts = await _mediaService.getApprovedMedia(
        hskLevel: _selectedHskLevel,
        topicTag: _selectedTopic,
        limit: 50,
      );

      // 只保留音频类型的内容
      final audioPodcasts = podcasts
          .where((media) => media.contentType == 'audio')
          .toList();

      setState(() {
        _podcasts = audioPodcasts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载播客列表失败: $e';
        _isLoading = false;
      });
    } finally {
      if (mounted) {
        LoadingOverlay.hide();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody());
  }

  /// 构建主体内容
  Widget _buildBody() {
    // 错误状态
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
              size: 50.0,
            ),
            const SizedBox(height: 20),
            Text(
              '加载失败，请重试',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _loadPodcasts,
              child: Text(
                'Retry',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 空状态
    if (_podcasts.isEmpty && !_isLoading) {
      final viewPadding = MediaQuery.of(context).viewPadding;
      return Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          viewPadding.top + 60,
          24,
          viewPadding.bottom + 90,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.podcasts,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无播客内容',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    // 正常数据状态
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom,
      ),
      child: RefreshIndicator(
        edgeOffset: MediaQuery.of(context).viewPadding.top,
        onRefresh: _loadPodcasts,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).viewPadding.top + 60,
                left: 24,
                right: 24,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      'Podcasts',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _showFilterDialog,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final podcast = _podcasts[index];
                  return _buildPodcastCard(podcast);
                }, childCount: _podcasts.length),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(top: 20, bottom: 100),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: Text(
                    'All podcasts have been loaded.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建播客卡片
  Widget _buildPodcastCard(MediaContentModel podcast) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToPlayer(podcast),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 播客封面
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.podcasts,
                  size: 40,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),

              const SizedBox(width: 16),

              // 播客信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      podcast.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // 描述
                    Text(
                      podcast.description ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // 标签和时长
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // HSK等级标签
                        _buildChip(
                          'HSK ${podcast.hskLevel}',
                          Theme.of(context).colorScheme.primary,
                        ),

                        // 话题标签
                        if (podcast.topicTag != null)
                          _buildChip(
                            podcast.topicTag!,
                            Theme.of(context).colorScheme.secondary,
                          ),

                        // 时长
                        if (podcast.durationSeconds != null)
                          _buildChip(
                            _formatDuration(podcast.durationSeconds!),
                            Theme.of(context).colorScheme.tertiary,
                          ),

                        // 观看次数
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${podcast.viewCount}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 播放按钮
              IconButton(
                icon: const Icon(Icons.play_circle_filled),
                iconSize: 40,
                color: Theme.of(context).colorScheme.primary,
                onPressed: () => _navigateToPlayer(podcast),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建标签芯片
  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 格式化时长
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '${minutes}分${remainingSeconds}秒';
    }
    return '${remainingSeconds}秒';
  }

  /// 导航到播客详情页面
  void _navigateToPlayer(MediaContentModel podcast) {
    context.push(AppRouter.PODCAST_DETAIL, extra: podcast);
  }

  /// 显示筛选对话框
  Future<void> _showFilterDialog() async {
    int? tempHskLevel = _selectedHskLevel;
    String? tempTopic = _selectedTopic;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('筛选播客'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HSK等级筛选
                  const Text(
                    'HSK等级:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('全部'),
                        selected: tempHskLevel == null,
                        onSelected: (selected) {
                          setDialogState(() {
                            tempHskLevel = null;
                          });
                        },
                      ),
                      ...List.generate(6, (index) {
                        final level = index + 1;
                        return FilterChip(
                          label: Text('HSK $level'),
                          selected: tempHskLevel == level,
                          onSelected: (selected) {
                            setDialogState(() {
                              tempHskLevel = selected ? level : null;
                            });
                          },
                        );
                      }),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 话题筛选
                  const Text(
                    '话题:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('全部'),
                        selected: tempTopic == null,
                        onSelected: (selected) {
                          setDialogState(() {
                            tempTopic = null;
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('中国建筑'),
                        selected: tempTopic == 'Chinese Architecture',
                        onSelected: (selected) {
                          setDialogState(() {
                            tempTopic = selected
                                ? 'Chinese Architecture'
                                : null;
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('中国美食'),
                        selected: tempTopic == 'Chinese Cuisine',
                        onSelected: (selected) {
                          setDialogState(() {
                            tempTopic = selected ? 'Chinese Cuisine' : null;
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('中国节日'),
                        selected: tempTopic == 'Chinese Festivals',
                        onSelected: (selected) {
                          setDialogState(() {
                            tempTopic = selected ? 'Chinese Festivals' : null;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedHskLevel = tempHskLevel;
                      _selectedTopic = tempTopic;
                    });
                    Navigator.of(context).pop();
                    _loadPodcasts();
                  },
                  child: const Text('应用'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
