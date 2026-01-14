import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toneup_app/models/media_content_model.dart';
import 'package:toneup_app/router_config.dart';

/// 播客详情页面
/// 展示播客的详细信息、目标词汇、语法点等
class PodcastDetailPage extends StatefulWidget {
  final MediaContentModel media;

  const PodcastDetailPage({super.key, required this.media});

  @override
  State<PodcastDetailPage> createState() => _PodcastDetailPageState();
}

class _PodcastDetailPageState extends State<PodcastDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ThemeData theme;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 监听 tab 切换，触发 UI 更新
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.of(context).viewPadding;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 封面区域
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(24, viewPadding.top + 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 返回按钮
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 封面
                  Container(
                    width: double.infinity,
                    height: 240,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.podcasts,
                      size: 80,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 标题
                  Text(
                    widget.media.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // 标签
                  Wrap(
                    spacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      if (widget.media.hskLevel != null)
                        _buildTag(
                          'HSK ${widget.media.hskLevel}',
                          theme.colorScheme.primary,
                        ),
                      if (widget.media.topicTag != null)
                        _buildTag(
                          widget.media.topicTag!,
                          theme.colorScheme.secondary,
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Play 按钮
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _navigateToPlayer,
                      icon: const Icon(Icons.play_arrow, size: 32),
                      label: const Text(
                        'Play',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab导航
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Highlights'),
                  Tab(text: 'Summary'),
                ],
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: theme.colorScheme.primary,
              ),
              theme.colorScheme.surface,
            ),
          ),

          // Tab内容
          SliverToBoxAdapter(
            child: IndexedStack(
              index: _tabController.index,
              children: [_buildHighlightsTab(), _buildSummaryTab()],
            ),
          ),
        ],
      ),
    );
  }

  /// Highlights标签页
  Widget _buildHighlightsTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 目标词汇
          _buildSectionTitle('targets words'),
          const SizedBox(height: 12),
          _buildVocabularyChips(),
        ],
      ),
    );
  }

  /// Summary标签页
  Widget _buildSummaryTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.media.description ?? '暂无描述',
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  /// 构建标签
  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 构建章节标题
  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withAlpha(128),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  /// 构建词汇芯片
  Widget _buildVocabularyChips() {
    final vocabularyList = widget.media.vocabularyList ?? [];

    if (vocabularyList.isEmpty) {
      return Text(
        '暂无目标词汇',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: vocabularyList.map((word) {
        return Text('$word、', style: theme.textTheme.titleMedium);
      }).toList(),
    );
  }

  /// 导航到播放器页面
  void _navigateToPlayer() {
    context.push(AppRouter.PODCAST_PLAYER, extra: widget.media);
  }
}

/// TabBar委托类
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _TabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return false;
  }
}
