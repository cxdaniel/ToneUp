import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

/// 文档查看器页面
/// 用于显示Markdown格式的合规文档(隐私政策、服务条款等)
class DocumentViewerPage extends StatefulWidget {
  final String title;
  final String assetPath;

  const DocumentViewerPage({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  State<DocumentViewerPage> createState() => _DocumentViewerPageState();
}

class _DocumentViewerPageState extends State<DocumentViewerPage> {
  String? _markdownContent;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMarkdownContent();
  }

  Future<void> _loadMarkdownContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final content = await rootBundle.loadString(widget.assetPath);
      setState(() {
        _markdownContent = content;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ 加载文档失败: $e');
      setState(() {
        _errorMessage = '无法加载文档内容';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLinkTap(String text, String? href, String title) async {
    if (href == null) return;

    // 处理内部文档链接
    if (href == 'privacy_policy' ||
        href == 'terms_of_service' ||
        href == 'about' ||
        href == 'licenses') {
      final assetPath = 'assets/docs/$href.md';
      final pageTitle = _getDocumentTitle(href);

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                DocumentViewerPage(title: pageTitle, assetPath: assetPath),
          ),
        );
      }
      return;
    }

    // 处理外部链接
    if (href.startsWith('http://') || href.startsWith('https://')) {
      final uri = Uri.parse(href);
      try {
        final canLaunch = await canLaunchUrl(uri);
        if (canLaunch) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showSnackBar('无法打开链接: $href');
        }
      } catch (e) {
        _showSnackBar('无法打开链接: $href');
      }
      return;
    }

    // 处理邮件链接
    if (href.startsWith('mailto:')) {
      final uri = Uri.parse(href);
      try {
        final canLaunch = await canLaunchUrl(uri);
        if (canLaunch) {
          await launchUrl(uri);
        }
      } catch (e) {
        _showSnackBar('无法打开邮件链接');
      }
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _getDocumentTitle(String docKey) {
    switch (docKey) {
      case 'privacy_policy':
        return '隐私政策';
      case 'terms_of_service':
        return '服务条款';
      case 'about':
        return '关于ToneUp';
      case 'licenses':
        return '开源许可';
      default:
        return docKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title), elevation: 0),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: theme.textTheme.titleMedium),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadMarkdownContent,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_markdownContent == null) {
      return const Center(child: Text('暂无内容'));
    }

    return Markdown(
      data: _markdownContent!,
      selectable: true,
      onTapLink: _handleLinkTap,
      styleSheet: MarkdownStyleSheet(
        // 标题样式
        h1: theme.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
        h2: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
        h3: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
        h4: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
        h5: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
        h6: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),

        // 正文样式
        p: theme.textTheme.bodyMedium?.copyWith(
          height: 1.6,
          color: theme.colorScheme.onSurface,
        ),

        // 链接样式
        a: TextStyle(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        ),

        // 列表样式
        listBullet: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),

        // 代码块样式
        code: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          color: theme.colorScheme.onSurface,
        ),
        codeblockDecoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),

        // 引用样式
        blockquote: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: theme.colorScheme.primary, width: 4),
          ),
        ),

        // 水平分割线
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
          ),
        ),

        // 表格样式
        tableBorder: TableBorder.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
        tableHead: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        tableBody: theme.textTheme.bodyMedium,

        // 内边距
        blockSpacing: 16,
        listIndent: 24,
        blockquotePadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        codeblockPadding: const EdgeInsets.all(16),
      ),
      padding: const EdgeInsets.all(16),
    );
  }
}
