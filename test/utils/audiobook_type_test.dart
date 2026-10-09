import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/models/audiobook.dart';
import 'package:luobo/models/audiobook_chapter.dart';
import 'package:luobo/utils/audiobook_type.dart';

/// 端上类型判断单测（§7.4）：服务端字段优先 + 标题启发式兜底。
AudiobookChapter _ch(String title, {int order = 1}) =>
    AudiobookChapter(id: 'abe_$order', title: title, order: order);

void main() {
  group('classifyAudiobookType 标题启发式', () {
    test('编号型：章节标题带「第X章」前缀占比 ≥60%', () {
      final chapters = [for (var i = 1; i <= 10; i++) _ch('第$i章 风起', order: i)];

      expect(
        classifyAudiobookType(
          book: Audiobook(id: 'abk_1', title: '三体'),
          chapters: chapters,
        ),
        AudiobookContentType.numbered,
      );
    });

    test('编号型：英文 Chapter N 前缀', () {
      final chapters = [
        for (var i = 1; i <= 6; i++) _ch('Chapter $i 面壁者', order: i)
      ];

      expect(
        classifyAudiobookType(
          book: Audiobook(id: 'abk_2', title: 'Novel'),
          chapters: chapters,
        ),
        AudiobookContentType.numbered,
      );
    });

    test('编号型：数字编号前缀（三体实测「001/002」格式）', () {
      final chapters = [
        _ch('001 风起'),
        _ch('002 科学边界'),
        _ch('003 射手和农场主'),
        _ch('004 三体问题'),
        _ch('005 古筝行动'),
      ];

      expect(
        classifyAudiobookType(
          book: Audiobook(id: 'abk_2b', title: '三体'),
          chapters: chapters,
        ),
        AudiobookContentType.numbered,
      );
    });

    test('编号型：「卷一」格式（无"第"前缀）', () {
      final chapters = [
        _ch('卷一 蒋兴哥重会珍珠衫'),
        _ch('卷二 陈御史巧勘金钗钿'),
        _ch('卷三 滕大尹鬼断家私'),
      ];

      expect(
        classifyAudiobookType(
          book: Audiobook(id: 'abk_2c', title: '今古奇观'),
          chapters: chapters,
        ),
        AudiobookContentType.numbered,
      );
    });

    test('合集型：相声标题无编号前缀', () {
      final chapters = [_ch('我要幸福'), _ch('西征梦'), _ch('夜行记'), _ch('学电台')];

      expect(
        classifyAudiobookType(
          book: Audiobook(id: 'abk_3', title: '郭德纲相声'),
          chapters: chapters,
        ),
        AudiobookContentType.collection,
      );
    });

    test('混合时按占比判定（7/10 编号 → 编号型）', () {
      final chapters = [
        for (var i = 1; i <= 7; i++) _ch('第$i章 正文', order: i),
        _ch('番外一'),
        _ch('创作手记'),
        _ch('访谈'),
      ];

      expect(
        classifyAudiobookType(
          book: Audiobook(id: 'abk_4', title: '混合'),
          chapters: chapters,
        ),
        AudiobookContentType.numbered,
      );
    });

    test('章节为空时默认编号型', () {
      expect(
        classifyAudiobookType(
          book: Audiobook(id: 'abk_5', title: '空书'),
          chapters: const [],
        ),
        AudiobookContentType.numbered,
      );
    });
  });

  group('classifyAudiobookType 服务端字段优先', () {
    test('categories 含「相声」→ 合集型（即使标题全编号）', () {
      final chapters = [for (var i = 1; i <= 10; i++) _ch('第$i章 段子', order: i)];

      expect(
        classifyAudiobookType(
          book: Audiobook(id: 'abk_6', title: '相声', categories: ['相声']),
          chapters: chapters,
        ),
        AudiobookContentType.collection,
      );
    });

    test('tags 含「评书」→ 合集型', () {
      final chapters = [_ch('第一回 珍珠衫'), _ch('第二回 错斩崔宁')];

      expect(
        classifyAudiobookType(
          book: Audiobook(id: 'abk_7', title: '评书', tags: ['评书']),
          chapters: chapters,
        ),
        AudiobookContentType.collection,
      );
    });

    test('categories/tags 为空 → 退回标题启发式', () {
      final chapters = [for (var i = 1; i <= 5; i++) _ch('第$i章 正文', order: i)];

      expect(
        classifyAudiobookType(
          book: Audiobook(id: 'abk_8', title: '无标签书', tags: const []),
          chapters: chapters,
        ),
        AudiobookContentType.numbered,
      );
    });
  });
}
