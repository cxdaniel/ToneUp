// LanguageType 枚举使用示例
// 注意：这是示例代码，不是完整的可运行文件
// 实际使用时需要根据具体场景添加必要的导入和上下文

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/models/enumerated_types.dart';
import 'package:toneup_app/models/profile_model.dart';
import 'package:toneup_app/providers/profile_provider.dart';
import 'package:toneup_app/services/data_service.dart';
import 'package:toneup_app/services/simple_dictionary_service.dart';

// ============================================
// 2. 在 UI 中显示语言选择器
// ============================================

class LanguageSelector extends StatelessWidget {
  final LanguageType selectedLanguage;
  final ValueChanged<LanguageType> onChanged;

  const LanguageSelector({
    super.key,
    required this.selectedLanguage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<LanguageType>(
      value: selectedLanguage,
      items: LanguageType.values.map((lang) {
        return DropdownMenuItem(
          value: lang,
          child: Row(
            children: [
              Text(lang.displayName),
              const SizedBox(width: 8),
              Text('(${lang.code})', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

// ============================================
// 3. 从 Profile 获取语言并使用
// ============================================

class DictionaryExample {
  Future<void> lookupWord(BuildContext context) async {
    // 方式1：推荐 - 使用枚举
    final profile = context.read<ProfileProvider>().profile;
    final languageType = LanguageType.fromCode(profile?.nativeLanguage ?? 'en');

    await SimpleDictionaryService().getWordDetail(
      word: '你好',
      language: languageType.code,
    );

    // 显示语言名称给用户
    debugPrint('正在查询 ${languageType.displayName} 翻译...');
  }

  Future<void> lookupWordSimple(BuildContext context) async {
    // 方式2：简单 - 直接使用字符串
    final profile = context.read<ProfileProvider>().profile;
    final language = profile?.nativeLanguage ?? 'en';

    await SimpleDictionaryService().getWordDetail(
      word: '你好',
      language: language,
    );
  }
}

// ============================================
// 4. 保存语言设置到 Profile
// ============================================

class ProfileSettingsExample {
  Future<void> updateLanguage(
    BuildContext context,
    LanguageType newLanguage,
  ) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // ✅ 在异步操作前提取 Provider（避免跨异步间隙使用 context）
    final profileProvider = context.read<ProfileProvider>();

    // 保存语言代码到数据库
    await Supabase.instance.client
        .from('profiles')
        .update({'native_language': newLanguage.code})
        .eq('id', userId);

    // 更新本地 Provider
    await profileProvider.fetchProfile();

    // ✅ 显示提示前检查 mounted
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('语言已更改为 ${newLanguage.displayName}')),
      );
    }
  }
}

// ============================================
// 5. 生成练习题时使用
// ============================================

class PracticeExample {
  Future<void> generatePractice(BuildContext context) async {
    final profile = context.read<ProfileProvider>().profile;
    final languageType = LanguageType.fromCode(profile?.nativeLanguage ?? 'en');

    await for (final progress in DataService().generatePlanWithProgress(
      userId: profile!.id,
      inds: [1, 2, 3],
      dur: 60,
      nativeLanguage: languageType.code, // 使用枚举的代码
    )) {
      // 处理进度...
      debugPrint('生成进度: ${progress['progress']}%');
      debugPrint('目标语言: ${languageType.displayName}');
    }
  }
}

// ============================================
// 6. 语言列表展示
// ============================================

class LanguageListPage extends StatelessWidget {
  const LanguageListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: LanguageType.values.length,
      itemBuilder: (context, index) {
        final lang = LanguageType.values[index];
        final isDefault = lang == LanguageType.english;

        return ListTile(
          title: Text(lang.displayName),
          subtitle: Text('代码: ${lang.code}'),
          trailing: isDefault ? Chip(label: Text('默认')) : null,
          onTap: () {
            // 选择语言
            Navigator.pop(context, lang);
          },
        );
      },
    );
  }
}

// ============================================
// 7. 工具函数示例
// ============================================

class LanguageUtils {
  /// 获取用户当前语言枚举
  static LanguageType getCurrentLanguage(ProfileModel? profile) {
    return LanguageType.fromCode(profile?.nativeLanguage ?? 'en');
  }

  /// 获取用户当前语言代码
  static String getCurrentLanguageCode(ProfileModel? profile) {
    return getCurrentLanguage(profile).code;
  }

  /// 获取用户当前语言显示名称
  static String getCurrentLanguageName(ProfileModel? profile) {
    return getCurrentLanguage(profile).displayName;
  }

  /// 检查是否支持某个语言代码
  static bool isSupportedLanguage(String code) {
    try {
      LanguageType.fromCode(code);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取所有支持的语言代码列表
  static List<String> getAllLanguageCodes() {
    return LanguageType.values.map((e) => e.code).toList();
  }

  /// 获取所有支持的语言名称列表
  static List<String> getAllLanguageNames() {
    return LanguageType.values.map((e) => e.displayName).toList();
  }
}

// ============================================
// 8. 测试示例
// ============================================

void testLanguageType() {
  // 测试枚举转换
  assert(LanguageType.english.code == 'en');
  assert(LanguageType.japanese.displayName == '日本語');

  // 测试从字符串解析
  assert(LanguageType.fromCode('ja') == LanguageType.japanese);
  assert(LanguageType.fromCode('invalid') == LanguageType.english);

  // 测试所有语言
  for (final lang in LanguageType.values) {
    debugPrint('${lang.displayName}: ${lang.code}');
  }

  debugPrint('✅ LanguageType 测试通过');
}
