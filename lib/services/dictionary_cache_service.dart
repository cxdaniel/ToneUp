import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:toneup_app/models/word_detail_model.dart';

/// 词典本地缓存服务 (SQLite)
/// 三级缓存架构的L2层：本地数据库缓存
class DictionaryCacheService {
  static final DictionaryCacheService _instance =
      DictionaryCacheService._internal();
  factory DictionaryCacheService() => _instance;
  DictionaryCacheService._internal();

  Database? _database;

  /// 初始化数据库
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 创建数据库和表
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'dictionary_cache.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE dictionary_cache (
            word TEXT PRIMARY KEY,
            language TEXT NOT NULL,
            pinyin TEXT NOT NULL,
            summary TEXT,
            entries TEXT NOT NULL,
            hsk_level INTEGER,
            cached_at INTEGER NOT NULL,
            access_count INTEGER DEFAULT 1
          )
        ''');

        // 创建索引
        await db.execute(
          'CREATE INDEX idx_cache_language ON dictionary_cache(language)',
        );
        await db.execute(
          'CREATE INDEX idx_cache_access ON dictionary_cache(access_count DESC)',
        );

        debugPrint('✅ 词典缓存数据库创建成功');
      },
    );
  }

  /// 查询缓存的词条
  /// [word] - 汉字词语
  /// [language] - 语言代码 (en, zh, ja等)
  Future<WordDetailModel?> getWord(String word, String language) async {
    try {
      final db = await database;
      final results = await db.query(
        'dictionary_cache',
        where: 'word = ? AND language = ?',
        whereArgs: [word, language],
      );

      if (results.isEmpty) return null;

      final data = results.first;

      // 更新访问计数
      await db.update(
        'dictionary_cache',
        {'access_count': (data['access_count'] as int) + 1},
        where: 'word = ? AND language = ?',
        whereArgs: [word, language],
      );

      // 解析 entries JSON
      final entriesJson = jsonDecode(data['entries'] as String) as List;
      final entries = entriesJson
          .map((e) => WordEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      return WordDetailModel(
        word: data['word'] as String,
        pinyin: data['pinyin'] as String,
        summary: data['summary'] as String?,
        entries: entries,
        hskLevel: data['hsk_level'] as int?,
      );
    } catch (e) {
      debugPrint('❌ 查询缓存失败: $e');
      return null;
    }
  }

  /// 清空所有缓存数据
  Future<void> clearAllCache() async {
    try {
      final db = await database;
      await db.delete('dictionary_cache');
      debugPrint('✅ SQLite词典缓存已清空');
    } catch (e) {
      debugPrint('❌ 清空SQLite缓存失败: $e');
    }
  }

  /// 保存词条到缓存
  Future<void> saveWord(WordDetailModel word, String language) async {
    try {
      final db = await database;

      // 序列化 entries
      final entriesJson = jsonEncode(
        word.entries.map((e) => e.toJson()).toList(),
      );

      await db.insert('dictionary_cache', {
        'word': word.word,
        'language': language,
        'pinyin': word.pinyin,
        'summary': word.summary,
        'entries': entriesJson,
        'hsk_level': word.hskLevel,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
        'access_count': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      debugPrint('✅ 词条已缓存: ${word.word} ($language)');
    } catch (e) {
      debugPrint('❌ 保存缓存失败: $e');
    }
  }

  /// 清理旧缓存（保留最常用的500个词）
  Future<void> cleanOldCache() async {
    try {
      final db = await database;

      // 查询总数
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM dictionary_cache'),
      );

      if (count != null && count > 500) {
        // 删除访问次数最少的词条
        await db.execute('''
          DELETE FROM dictionary_cache
          WHERE word IN (
            SELECT word FROM dictionary_cache
            ORDER BY access_count ASC
            LIMIT ${count - 500}
          )
        ''');

        debugPrint('✅ 清理缓存，删除 ${count - 500} 个低频词条');
      }
    } catch (e) {
      debugPrint('❌ 清理缓存失败: $e');
    }
  }

  /// 获取缓存统计
  Future<Map<String, int>> getCacheStats() async {
    try {
      final db = await database;
      final count =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM dictionary_cache'),
          ) ??
          0;

      final languages = await db.rawQuery('''
        SELECT language, COUNT(*) as count
        FROM dictionary_cache
        GROUP BY language
      ''');

      return {
        'total': count,
        for (var lang in languages)
          lang['language'] as String: lang['count'] as int,
      };
    } catch (e) {
      debugPrint('❌ 获取缓存统计失败: $e');
      return {'total': 0};
    }
  }

  /// 清空所有缓存
  Future<void> clearAll() async {
    try {
      final db = await database;
      await db.delete('dictionary_cache');
      debugPrint('✅ 已清空所有词典缓存');
    } catch (e) {
      debugPrint('❌ 清空缓存失败: $e');
    }
  }
}
