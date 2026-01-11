import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/models/indicator_result_model.dart';
import 'package:toneup_app/providers/profile_provider.dart';
import 'package:toneup_app/services/data_service.dart';
import 'package:toneup_app/theme_data.dart';

class LevelDetailPage extends StatefulWidget {
  const LevelDetailPage({super.key});

  @override
  State<LevelDetailPage> createState() => _LevelDetailPageState();
}

class _LevelDetailPageState extends State<LevelDetailPage> {
  late ThemeData theme;
  IndicatorResultModel? _upgradeCheck;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUpgradeCheck();
  }

  Future<void> _loadUpgradeCheck() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('用户未登录');
      }

      // 获取用户当前级别
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      final currentLevel = profileProvider.profile?.level ?? 1;

      final data = await DataService().getUserIndicatorResult(
        userId,
        currentLevel,
      );
      setState(() {
        _upgradeCheck = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      debugPrint('❌ 加载升级检查数据失败: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final currentLevel = profileProvider.profile?.level ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text('HSK $currentLevel Level Details')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _upgradeCheck == null
          ? _buildNoDataView()
          : _buildContentView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            SizedBox(height: 16),
            Text('Failed to load data', style: theme.textTheme.titleLarge),
            SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadUpgradeCheck,
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 64, color: theme.colorScheme.outline),
          SizedBox(height: 16),
          Text('No data available', style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }

  Widget _buildContentView() {
    final data = _upgradeCheck!;
    final viewPadding = MediaQuery.of(context).viewPadding;

    return RefreshIndicator(
      onRefresh: _loadUpgradeCheck,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 16, 24, viewPadding.bottom + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 24,
          children: [
            _buildOverallScoreCard(data),
            _buildUpgradeStatusCard(data),
            _buildCoverageCard(data),
            _buildRecentPracticeCard(data),
            _buildIndicatorsList(data),
          ],
        ),
      ),
    );
  }

  /// 总体分数卡片
  Widget _buildOverallScoreCard(IndicatorResultModel data) {
    final percentage = (data.score * 100).toInt();
    final color = data.score >= 0.8
        ? theme.extension<AppThemeExtensions>()?.statePass ?? Colors.green
        : theme.colorScheme.primary;

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withAlpha(25), color.withAlpha(5)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(75), width: 2),
      ),
      child: Column(
        children: [
          Text(
            'Overall Score',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: data.score,
                  strokeWidth: 12,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percentage%',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (data.consecutiveQualifiedCount > 0)
                    Text(
                      '${data.consecutiveQualifiedCount.toInt()} streaks',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 升级状态卡片
  Widget _buildUpgradeStatusCard(IndicatorResultModel data) {
    final isEligible = data.isEligibleForUpgrade;
    final bgColor = isEligible
        ? theme.extension<AppThemeExtensions>()?.statePassContainer ??
              Colors.green.shade100
        : theme.colorScheme.secondaryContainer;
    final textColor = isEligible
        ? theme.extension<AppThemeExtensions>()?.statePass ?? Colors.green
        : theme.colorScheme.onSecondaryContainer;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isEligible ? Icons.check_circle : Icons.hourglass_empty,
            size: 48,
            color: textColor,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEligible ? 'Ready to Upgrade!' : 'Keep Practicing',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  data.message,
                  style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                ),
                if (!isEligible && data.upgradeGap > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Need ${data.upgradeGap.toInt()} more practices',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: textColor.withAlpha(204),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 核心指标覆盖率卡片
  Widget _buildCoverageCard(IndicatorResultModel data) {
    final coverage = data.coreIndicatorCoverage.toInt();
    final progressColor = coverage >= 80
        ? theme.extension<AppThemeExtensions>()?.statePass ?? Colors.green
        : coverage >= 50
        ? Colors.orange
        : theme.extension<AppThemeExtensions>()?.stateFail ?? Colors.red;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Core Indicator Coverage',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$coverage%',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: progressColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: coverage / 100,
              minHeight: 12,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${data.coreIndicatorDetails.where((e) => e.isQualified).length} of ${data.coreIndicatorDetails.length} indicators qualified',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 最近练习情况卡片
  Widget _buildRecentPracticeCard(IndicatorResultModel data) {
    final practice = data.recentPractice;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Practice',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _buildPracticeStatItem(
                icon: Icons.calendar_today,
                label: 'Last 7 days',
                value: '${practice.practiceCount7d}',
              ),
              SizedBox(width: 24),
              _buildPracticeStatItem(
                icon: Icons.calendar_month,
                label: 'Last 30 days',
                value: '${practice.practiceCount30d}',
              ),
            ],
          ),
          if (practice.lastPracticeTime != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Last practice: ${_formatDate(practice.lastPracticeTime!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPracticeStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 核心指标详情列表
  Widget _buildIndicatorsList(IndicatorResultModel data) {
    if (data.coreIndicatorDetails.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Core Indicators',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          ...data.coreIndicatorDetails.map((indicator) {
            return _buildIndicatorItem(indicator);
          }),
        ],
      ),
    );
  }

  Widget _buildIndicatorItem(IndicatorCoreDetailModel indicator) {
    final progress = indicator.minimum > 0
        ? (indicator.practiceCount / indicator.minimum).clamp(0.0, 1.0)
        : 0.0;
    final avgScorePercent = (indicator.avgScore * 100).toInt();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  indicator.indicatorName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: [
                  if (indicator.isQualified)
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color:
                          theme.extension<AppThemeExtensions>()?.statePass ??
                          Colors.green,
                    )
                  else
                    Icon(
                      Icons.radio_button_unchecked,
                      size: 20,
                      color: theme.colorScheme.outline,
                    ),
                  SizedBox(width: 8),
                  Text(
                    '$avgScorePercent%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: indicator.isQualified
                          ? theme.extension<AppThemeExtensions>()?.statePass ??
                                Colors.green
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                indicator.isQualified
                    ? theme.extension<AppThemeExtensions>()?.statePass ??
                          Colors.green
                    : theme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${indicator.practiceCount} / ${indicator.minimum.toInt()} practices',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (indicator.practiceGap > 0)
                Text(
                  'Need ${indicator.practiceGap.toInt()} more',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.extension<AppThemeExtensions>()?.stateFail ??
                        Colors.red,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
}
