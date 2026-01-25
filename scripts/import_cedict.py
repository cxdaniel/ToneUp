#!/usr/bin/env python3
"""
CC-CEDICT 词典批量导入 Supabase 脚本（无需额外依赖版本）

用途：
1. 下载最新的 CC-CEDICT 数据（60,000+ 中英词条）
2. 解析 CEDICT 格式
3. 批量导入到 Supabase dictionary 表

使用方法（无需安装依赖）：
1. 配置环境变量（见下方）
2. 运行: python3 scripts/import_cedict.py

CC-CEDICT 数据来源: https://www.mdbg.net/chinese/dictionary?page=cc-cedict
授权: Creative Commons Attribution-ShareAlike 4.0
"""

import re
import json
import gzip
import os
from urllib.request import urlopen, Request
from urllib.error import HTTPError, URLError

# Supabase配置（请修改为你的配置）
SUPABASE_URL = os.getenv('SUPABASE_URL', 'https://kixonwnuivnjqlraydmz.supabase.co')
SUPABASE_SERVICE_KEY = os.getenv('SUPABASE_SERVICE_KEY', '')  # 必须设置！

# CC-CEDICT 数据URL
CEDICT_URL = 'https://www.mdbg.net/chinese/export/cedict/cedict_1_0_ts_utf-8_mdbg.txt.gz'

def download_cedict():
    """下载 CC-CEDICT 数据文件（支持重试和分块下载）"""
    print('📥 下载 CC-CEDICT 数据...')
    max_retries = 3
    
    for attempt in range(max_retries):
        try:
            if attempt > 0:
                print(f'⚠️ 重试下载 (第 {attempt + 1}/{max_retries} 次)...')
            
            # 分块下载，避免一次性读取过大数据导致超时
            response = urlopen(CEDICT_URL, timeout=120)
            chunks = []
            chunk_size = 1024 * 1024  # 1MB per chunk
            total_size = 0
            
            while True:
                chunk = response.read(chunk_size)
                if not chunk:
                    break
                chunks.append(chunk)
                total_size += len(chunk)
                print(f'   已下载: {total_size / 1024 / 1024:.1f} MB', end='\r')
            
            print()  # 换行
            compressed_data = b''.join(chunks)
            response.close()
            
            # 解压缩
            print('📦 解压缩数据...')
            data = gzip.decompress(compressed_data).decode('utf-8')
            
            print(f'✅ 下载完成! 数据大小: {len(data) / 1024 / 1024:.1f} MB')
            return data
            
        except (HTTPError, URLError, TimeoutError) as e:
            if attempt < max_retries - 1:
                print(f'❌ 下载失败: {e}')
                print(f'⏳ 等待 5 秒后重试...')
                import time
                time.sleep(5)
            else:
                print(f'❌ 下载失败，已重试 {max_retries} 次')
                print('请检查网络连接或手动下载: ' + CEDICT_URL)
                return None
    
    return None

def parse_cedict_line(line):
    """
    解析 CEDICT 格式行
    格式: 繁体 简体 [pin1 yin1] /definition1/definition2/
    例: 你好 你好 [ni3 hao3] /hello/hi/
    """
    # 跳过注释和空行
    line = line.strip()
    if not line or line.startswith('#'):
        return None
    
    # CEDICT 格式: 繁体 简体 [拼音] /定义1/定义2/
    # 使用更宽松的正则表达式
    pattern = r'^(.+?)\s+(.+?)\s+\[([^\]]+)\]\s+/(.*)/$'
    match = re.match(pattern, line)
    
    if not match:
        return None
    
    traditional, simplified, pinyin, definitions = match.groups()
    defs = [d.strip() for d in definitions.split('/') if d.strip()]
    
    return {
        'traditional': traditional,
        'simplified': simplified,
        'pinyin': pinyin.lower(),
        'definitions': defs
    }

def build_translation_json(word_data):
    """构建 Supabase JSONB translations 字段"""
    summary = word_data['definitions'][0] if word_data['definitions'] else ''
    
    entry = {
        'pos': 'n./v.',
        'definitions': word_data['definitions'][:5],
        'examples': []
    }
    
    return {
        'en': {
            'summary': summary,
            'entries': [entry]
        }
    }

def supabase_request(endpoint, method='GET', data=None, upsert=False):
    """发送请求到 Supabase REST API"""
    url = f"{SUPABASE_URL}/rest/v1/{endpoint}"
    
    headers = {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal'
    }
    
    # 使用 upsert 来处理重复键
    if method == 'POST' and upsert:
        headers['Prefer'] = 'resolution=merge-duplicates,return=minimal'
    
    req = Request(url, headers=headers, method=method)
    
    if data:
        req.data = json.dumps(data).encode('utf-8')
    
    try:
        with urlopen(req, timeout=60) as response:
            return response.status, None
    except HTTPError as e:
        error_body = e.read().decode('utf-8') if e.fp else 'No error details'
        # 只在非409错误时打印详细信息（409是正常的重复键，会被upsert处理）
        if e.code != 409:
            print(f'❌ HTTP错误: {e.code} - {e.reason}')
            print(f'   详细信息: {error_body}')
            if e.code == 401:
                print('⚠️ 认证失败！请检查 SUPABASE_SERVICE_KEY 是否正确')
        return None, str(e)
    except URLError as e:
        print(f'❌ 网络错误: {e.reason}')
        return None, str(e)

def import_to_supabase(cedict_data, batch_size=100):
    """批量导入到 Supabase"""
    if not SUPABASE_SERVICE_KEY:
        print('❌ 错误: 未配置 SUPABASE_SERVICE_KEY')
        print('')
        print('请设置环境变量:')
        print('  export SUPABASE_SERVICE_KEY="your_service_role_key_here"')
        print('')
        print('或在脚本中直接修改 SUPABASE_SERVICE_KEY 变量')
        print('')
        print('获取Service Key:')
        print('  1. https://supabase.com/dashboard/project/kixonwnuivnjqlraydmz')
        print('  2. Settings → API → service_role key')
        return
    
    import time
    lines = cedict_data.split('\n')
    total = 0
    batch = []
    parsed_count = 0
    error_count = 0
    skipped_count = 0
    retry_count = 0
    max_retries = 3
    
    print(f'\n🚀 开始导入词条...')
    print(f'📊 总行数: {len(lines)}')
    print(f'📦 批次大小: {batch_size}')
    
    for i, line in enumerate(lines):
        parsed = parse_cedict_line(line)
        if not parsed:
            skipped_count += 1
            continue
        
        parsed_count += 1
        word = parsed['simplified']
        
        record = {
            'word': word,
            'pinyin': parsed['pinyin'],
            'translations': build_translation_json(parsed),
            'source': 'cc-cedict',
            'hsk_level': None
        }
        
        batch.append(record)
        
        if len(batch) >= batch_size:
            # 重试机制
            for attempt in range(max_retries):
                status, error = supabase_request('dictionary', 'POST', batch, upsert=True)
                if status in [200, 201, 204]:
                    total += len(batch)
                    print(f'✅ 已导入 {total} 个词条... (处理 {i+1}/{len(lines)} 行, 解析 {parsed_count}, 跳过 {skipped_count})')
                    batch = []
                    break
                else:
                    retry_count += 1
                    if attempt < max_retries - 1:
                        wait_time = (attempt + 1) * 2  # 递增等待: 2s, 4s, 6s
                        print(f'⚠️ 批次导入失败，{wait_time}秒后重试 (第{attempt+1}/{max_retries}次)...')
                        time.sleep(wait_time)
                    else:
                        print(f'❌ 批次导入失败（已重试{max_retries}次），跳过此批次')
                        if error:
                            print(f'   错误: {error[:100]}...')  # 只显示前100字符
                        error_count += 1
                        batch = []
            
            # 批次间短暂延迟，避免触发限流
            time.sleep(0.1)
    
    # 导入剩余词条
    if batch:
        print(f'\n📦 导入最后一批词条 ({len(batch)} 个)...')
        for attempt in range(max_retries):
            status, error = supabase_request('dictionary', 'POST', batch, upsert=True)
            if status in [200, 201, 204]:
                total += len(batch)
                print(f'✅ 成功导入最后一批')
                break
            else:
                if attempt < max_retries - 1:
                    wait_time = (attempt + 1) * 2
                    print(f'⚠️ 最后一批导入失败，{wait_time}秒后重试...')
                    import time
                    time.sleep(wait_time)
                else:
                    print(f'❌ 最后一批导入失败: {error}')
    
    print(f'\n🎉 导入完成!')
    print(f'   总行数: {len(lines)}')
    print(f'   跳过行数: {skipped_count} (注释/空行)')
    print(f'   解析词条: {parsed_count}')
    print(f'   成功导入: {total}')
    print(f'   失败批次: {error_count}')
    print(f'   总重试次数: {retry_count}')
    print(f'📊 数据库: {SUPABASE_URL}')

def main():
    print('=' * 60)
    print('CC-CEDICT 词典导入工具（无依赖版本）')
    print('=' * 60)
    
    cedict_data = download_cedict()
    
    if not cedict_data:
        print('\n❌ 导入失败！请检查网络连接后重试')
        return
    
    import_to_supabase(cedict_data)

if __name__ == '__main__':
    main()
