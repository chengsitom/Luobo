/// 歌词缓存的「来源标记 + 会话级复查」公共 helper。
///
/// 背景（`docs/歌词源优先级修复技术方案.md` §2.4）：兜底（LRCLIB/网易云）命中的
/// 歌词会写进本地离线歌词缓存，而缓存读取排在服务器查询之前；旧缓存**不带来源
/// 标记** ⇒ 一首歌被兜底占位后**永不再问服务器**，形成永久占位。
///
/// 本文件解决三件事：
///   1. 缓存文件顶层加 `v` / `source`（对旧代码无害：旧代码只读 `lyricsList` /
///      `lyrics`，未知键被忽略 → 回退安全）；
///   2. 服务器来源的缓存直接用（零网络）；
///   3. 兜底来源 / 无标记的旧缓存 → **每进程每首最多复查一次**服务器，命中则
///      覆盖缓存并改用服务器歌词；复查无果**不删缓存**（离线与「服务器确实无
///      歌词」两种情形都安全退回缓存，无需区分网络错误与空结果）。
library;

import 'package:flutter/foundation.dart';

/// 缓存顶层键名。
const String kLyricsCacheVersionKey = 'v';
const String kLyricsCacheSourceKey = 'source';

/// 当前缓存结构版本。
const int kLyricsCacheVersion = 2;

/// 歌词来源。
enum LyricsCacheSource {
  /// 道理鱼自研歌词接口。
  daoliyu('daoliyu'),

  /// 其它服务器的歌词接口（Subsonic `getLyricsBySongId` / `getLyrics`）。
  server('server'),

  /// LRCLIB 外部兜底。
  lrclib('lrclib'),

  /// 网易云外部兜底。
  netease('netease');

  const LyricsCacheSource(this.wireName);

  /// 写入缓存时使用的字符串值。
  final String wireName;

  /// 外部兜底来源 —— 缓存可信度低，需要复查服务器。
  bool get isFallback => this == lrclib || this == netease;

  /// 服务器来源 —— 可直接使用，无需复查。
  bool get isServerSide => this == daoliyu || this == server;

  /// 解析缓存里记录的来源；无法识别（旧缓存 / 脏数据）返回 null。
  static LyricsCacheSource? fromWire(Object? value) {
    if (value is! String) return null;
    for (final source in LyricsCacheSource.values) {
      if (source.wireName == value) return source;
    }
    return null;
  }
}

/// 给待写入的歌词缓存 payload 补上版本与来源标记（返回新 Map，不改原对象）。
Map<String, dynamic> withLyricsCacheMeta(
  Map<String, dynamic> payload,
  LyricsCacheSource source,
) {
  return <String, dynamic>{
    ...payload,
    kLyricsCacheVersionKey: kLyricsCacheVersion,
    kLyricsCacheSourceKey: source.wireName,
  };
}

/// 读取缓存记录的来源；旧缓存（无 `v`/`source`）或无法识别时返回 null，
/// 调用方应视其为「来源可疑」并触发一次服务器复查。
LyricsCacheSource? readLyricsCacheSource(Map<String, dynamic>? cached) {
  if (cached == null) return null;
  return LyricsCacheSource.fromWire(cached[kLyricsCacheSourceKey]);
}

/// 会话级复查记录（每进程每首最多一次，重启即生效）。
final Set<String> _sessionRechecked = <String>{};

/// 该歌是否还应复查一次服务器。**调用即消耗本次机会**。
///
/// 用会话级 Set 而非 TTL：用户在服务器侧补了歌词后，**重启 App 即生效**，
/// 不需要清缓存、也不需要等一个不可控的过期时间。
bool shouldRecheckServer(String songId) {
  if (_sessionRechecked.contains(songId)) return false;
  _sessionRechecked.add(songId);
  return true;
}

/// 仅供测试：清空会话级复查记录。
@visibleForTesting
void resetLyricsRecheckState() => _sessionRechecked.clear();

/// 缓存阶段的结果。
class LyricsCacheOutcome {
  const LyricsCacheOutcome({required this.payload, required this.source});

  /// 可直接使用的缓存 payload（含 `lyricsList` / `lyrics` 键）。
  /// null 表示「无可用缓存」——调用方按自己的取源链继续（服务器 → 兜底）。
  final Map<String, dynamic>? payload;

  /// [payload] 的来源；payload 为 null 时为 null。
  final LyricsCacheSource? source;

  /// 是否可用（无需再查服务器）。
  bool get usable => payload != null;
}

/// 缓存阶段的统一处理（`docs/歌词源优先级修复技术方案.md` §5.3 的三分支）。
///
/// ```
/// 无缓存                              → 返回 null，调用方走取源链
/// 缓存来源 ∈ {daoliyu, server}        → 直接用（零网络）
/// 缓存来源是兜底 / 无标记（旧缓存）
///   ├ 本会话已复查过                  → 用缓存
///   └ 本会话首次复查 → 查服务器
///       ├ 服务器有歌词 → 覆盖缓存并返回服务器结果
///       └ 服务器无歌词 → **不删缓存**，返回缓存
/// ```
///
/// [fetchServerLyrics] 只在需要复查时调用一次；[saveCache] 用于把复查命中的
/// 服务器歌词写回缓存（带 `source` 标记）。两者都由调用方提供，以便复用各入口
/// 已有的服务实例。
Future<LyricsCacheOutcome> resolveLyricsCache({
  required String songId,
  required Map<String, dynamic>? cached,
  required Future<Map<String, dynamic>?> Function() fetchServerLyrics,
  required Future<void> Function(Map<String, dynamic> payload) saveCache,
  required LyricsCacheSource serverSource,
}) async {
  if (cached == null) {
    return const LyricsCacheOutcome(payload: null, source: null);
  }

  final source = readLyricsCacheSource(cached);

  // 服务器来源 → 直接信任，零网络。
  if (source != null && source.isServerSide) {
    return LyricsCacheOutcome(payload: cached, source: source);
  }

  // 兜底来源 / 旧缓存无标记 → 会话内首次复查服务器。
  if (!shouldRecheckServer(songId)) {
    return LyricsCacheOutcome(payload: cached, source: source);
  }

  try {
    final fromServer = await fetchServerLyrics();
    if (fromServer != null && fromServer.isNotEmpty) {
      final payload = withLyricsCacheMeta(
        toLyricsCacheShell(fromServer),
        serverSource,
      );
      await saveCache(payload);
      return LyricsCacheOutcome(payload: payload, source: serverSource);
    }
  } catch (e) {
    // 复查失败（离线 / 网络错误）→ 安全退回缓存，不删缓存、不抛给调用方。
    debugPrint('[LyricsCache] Server recheck failed for $songId: $e');
  }

  return LyricsCacheOutcome(payload: cached, source: source);
}

/// 把「服务器原始响应」规范成**缓存外壳**形状（顶层 `lyricsList` / `lyrics`），
/// 与各入口和兜底写入时的形状保持一致。
///
/// 为什么必须做这一步：缓存里的 `lyrics` 键有两种合法形态 —— 外壳里的 **Map**
/// （`{'lyrics': {'value': '<文本>'}}`）与服务器原始响应里的 **String**
/// （`{'lyrics': '<LRC 文本>'}`）。各入口读缓存时写的是
/// `outcome.payload?['lyrics'] as Map<String, dynamic>?`，若把原始响应直接塞进
/// 缓存外壳的位置，`as Map` 会命中 String 抛 `TypeError`，被入口的 catch 吞掉后
/// 歌词与兜底链一起失效（2026-10-08 code-review P1：C1/C2/C3 + R2）。
///
/// 归一化规则（与消费端读取键对齐）：
///   • 有 `structuredLyrics` → 同时产出 `lyricsList`（结构化分支）与 `lyrics`
///     （纯文本分支）两个键，避免入口读不到再打一次网络；
///   • 顶层 `lyrics` 是字符串 → 规范成 `{'value': <该文本>}`；
///   • 顶层 `value` 是字符串 → 原样放进 `lyrics`。
Map<String, dynamic> toLyricsCacheShell(Map<String, dynamic> serverPayload) {
  final shell = <String, dynamic>{};

  final structured = serverPayload['structuredLyrics'];
  if (structured is List && structured.isNotEmpty) {
    shell['lyricsList'] = serverPayload;
  }

  final value = serverPayload['value'];
  final lyrics = serverPayload['lyrics'];
  if (value is String && value.isNotEmpty) {
    shell['lyrics'] = serverPayload;
  } else if (lyrics is String && lyrics.isNotEmpty) {
    shell['lyrics'] = <String, dynamic>{'value': lyrics};
  }

  // 形状无法识别（既无 structuredLyrics 也无可用文本）时保持原样，
  // 由入口的 `?? 网络` 分支接管 —— 不能返回空 Map，否则缓存会被写成空壳。
  return shell.isEmpty ? <String, dynamic>{'lyrics': serverPayload} : shell;
}
