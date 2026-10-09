import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/services/knowledge_recommendation_engine.dart';

void main() {
  group('KnowledgeRecommendationEngine', () {
    test('rebuild 建立歌标签与倒排索引', () {
      final engine = KnowledgeRecommendationEngine();
      engine.rebuild({
        'a': '摇滚,深夜,治愈',
        'b': '摇滚,深夜,电子',
        'c': ' 流行 , 快乐 ',
      });

      expect(engine.hasIndex, isTrue);
      expect(engine.songCount, 3);
      expect(engine.tagCount, 6); // 摇滚/深夜/治愈/电子/流行/快乐
      expect(engine.tagsOf('a'), {'摇滚', '深夜', '治愈'});
      expect(engine.tagsOf('c'), {'流行', '快乐'}); // 空格被 trim
      expect(engine.tagsOf('missing'), isNull);
      expect(engine.songsWithTag('摇滚'), {'a', 'b'});
      expect(engine.songsWithTag('流行'), {'c'});
    });

    test('rebuild 忽略空标签歌', () {
      final engine = KnowledgeRecommendationEngine();
      engine.rebuild({'a': '', 'b': '  '});
      expect(engine.hasIndex, isFalse);
      expect(engine.songCount, 0);
    });

    test('jaccard 相似度', () {
      final engine = KnowledgeRecommendationEngine();
      expect(engine.jaccard({'a', 'b'}, {'a', 'b'}), 1.0);
      expect(engine.jaccard({'a'}, {'b'}), 0.0);
      expect(engine.jaccard({'a', 'b', 'c'}, {'a', 'b'}), 2 / 3);
      expect(engine.jaccard({}, {'a'}), 0.0);
    });

    test('findSimilar 一跳邻居：相似歌在前、排除自身与排除集合', () {
      final engine = KnowledgeRecommendationEngine();
      engine.rebuild({
        'a': '摇滚,深夜',
        'b': '摇滚,深夜,治愈',
        'c': '流行,快乐',
        'd': '摇滚',
      });

      final similar = engine.findSimilar('a', limit: 10, minSimilarity: 0.3);
      expect(similar, contains('b'));
      expect(similar, contains('d'));
      expect(similar, isNot(contains('a')));
      expect(similar, isNot(contains('c')));

      final excluded = engine.findSimilar(
        'a',
        limit: 10,
        minSimilarity: 0.3,
        exclude: {'b'},
      );
      expect(excluded, isNot(contains('b')));
    });

    test('userTagPref 累加并按最大值归一化', () {
      final engine = KnowledgeRecommendationEngine();
      engine.rebuild({'a': '摇滚,深夜', 'b': '摇滚,治愈', 'c': '流行'});
      engine.addUserPref('a', 2.0);
      engine.addUserPref('b', 1.0);

      final pref = engine.userTagPref;
      expect(pref['摇滚'], 1.0); // (2+1)/3
      expect(pref['深夜'], closeTo(2 / 3, 1e-9));
      expect(pref['治愈'], closeTo(1 / 3, 1e-9));
      expect(pref['流行'], isNull);
    });

    test('clearUserPref 清空偏好', () {
      final engine = KnowledgeRecommendationEngine();
      engine.rebuild({'a': '摇滚'});
      engine.addUserPref('a', 1.0);
      engine.clearUserPref();
      expect(engine.userTagPref, isEmpty);
      expect(engine.contentScore({'摇滚'}), 0.0);
    });

    test('contentScore：命中偏好标签的歌分更高，无命中为 0', () {
      final engine = KnowledgeRecommendationEngine();
      engine.rebuild({'a': '摇滚,深夜', 'b': '流行'});
      engine.addUserPref('a', 2.0);

      final scoreRock = engine.contentScore({'摇滚', '深夜'});
      final scorePop = engine.contentScore({'流行'});
      expect(scoreRock, greaterThan(scorePop));
      expect(scorePop, 0.0);
      expect(scoreRock, lessThanOrEqualTo(1.0));
    });

    test('topPrefTags 按偏好降序', () {
      final engine = KnowledgeRecommendationEngine();
      engine.rebuild({'a': '摇滚,深夜', 'b': '摇滚,治愈'});
      engine.addUserPref('a', 2.0);
      engine.addUserPref('b', 1.0);
      expect(engine.topPrefTags(2), ['摇滚', '深夜']);
    });

    test('representativeSongs：偏好标签的代表歌，跳过已排除', () {
      final engine = KnowledgeRecommendationEngine();
      engine.rebuild({
        'a': '摇滚,深夜',
        'b': '摇滚',
        'c': '治愈,深夜',
        'd': '流行',
      });
      // 偏好：深夜=3（最大）、摇滚=2、治愈=1 → top2 = [深夜, 摇滚]
      engine.addUserPref('a', 2.0);
      engine.addUserPref('c', 1.0);

      final rep = engine.representativeSongs(topTags: 2, perTag: 2);
      expect(rep, containsAll(['a', 'b', 'c']));
      expect(rep, isNot(contains('d')));

      final repExcluded = engine
          .representativeSongs(topTags: 2, perTag: 2, exclude: {'a', 'b'});
      expect(repExcluded, contains('c'));
      expect(repExcluded, isNot(contains('a')));
      expect(repExcluded, isNot(contains('b')));
    });

    test('无偏好时 representativeSongs 为空', () {
      final engine = KnowledgeRecommendationEngine();
      engine.rebuild({'a': '摇滚'});
      expect(engine.representativeSongs(), isEmpty);
    });
  });
}
