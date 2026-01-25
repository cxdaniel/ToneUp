import 'dart:collection';

/// LRU (Least Recently Used) 缓存实现
///
/// 固定大小的缓存，当缓存满时自动删除最近最少使用的项
/// Web和移动端通用，但Web刷新后会丢失
class LRUCache<K, V> {
  final int maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap();

  LRUCache({required this.maxSize}) : assert(maxSize > 0);

  /// 获取缓存值
  V? get(K key) {
    if (!_cache.containsKey(key)) return null;

    // 移动到最新位置（更新访问时间）
    final value = _cache.remove(key) as V;
    _cache[key] = value;
    return value;
  }

  /// 设置缓存值
  void put(K key, V value) {
    // 如果已存在，先删除旧值
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    }

    // 添加新值
    _cache[key] = value;

    // 如果超出大小限制，删除最旧的项（第一个）
    if (_cache.length > maxSize) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// 检查是否包含某个key
  bool containsKey(K key) => _cache.containsKey(key);

  /// 清空缓存
  void clear() => _cache.clear();

  /// 获取当前缓存大小
  int get length => _cache.length;

  /// 获取最大容量
  int get capacity => maxSize;

  /// 获取缓存命中率统计（需要额外计数器）
  Map<String, dynamic> getStats() {
    return {
      'current_size': _cache.length,
      'max_size': maxSize,
      'usage_rate': _cache.length / maxSize,
    };
  }
}
