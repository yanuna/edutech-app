import 'package:edutech_app/core/models/article.dart';
import 'package:flutter_test/flutter_test.dart';

/// Locks the app↔backend contract for the Article system: the JSON shapes below
/// mirror exactly what `Api\ArticleController@show` / `@index` return.
void main() {
  test('ArticleCard.fromJson parses a list card', () {
    final card = ArticleCard.fromJson({
      'id': 1,
      'slug': 'article-356-presidents-rule',
      'title': "President's Rule under Article 356",
      'summary': 'How the Union takes over a state.',
      'hero_image': 'https://cdn/x.jpg',
      'reading_time': 4,
      'difficulty': 'medium',
      'gs_paper': ['GS2'],
      'is_featured': true,
      'subject': {'id': 1, 'name': 'Polity'},
      'topic': {'id': 2, 'name': 'Emergencies'},
      'published_at': '2026-07-03T00:00:00+00:00',
    });

    expect(card.slug, 'article-356-presidents-rule');
    expect(card.readingTime, 4);
    expect(card.gsPaper, ['GS2']);
    expect(card.isFeatured, isTrue);
    expect(card.subjectName, 'Polity');
    expect(card.topicName, 'Emergencies');
  });

  test('Article.fromResponse parses body blocks, tags and related graph', () {
    final article = Article.fromResponse({
      'article': {
        'id': 1,
        'slug': 'x',
        'title': 'X',
        'difficulty': 'hard',
        'body': [
          {'type': 'rich_text', 'data': {'html': '<p>Hi</p>'}},
          {'type': 'revision_box', 'data': {'points': [{'text': 'Art 356'}]}},
        ],
        'keywords': ['Article 356'],
        'mains_relevance': 'Centre-State relations',
        'tags': [{'id': 5, 'slug': 'federalism', 'name': 'Federalism', 'type': 'general'}],
      },
      'related': {
        'articles': [{'id': 2, 'slug': 'y', 'title': 'Y', 'reading_time': 3}],
        'mcqs': [{'id': 9, 'question': 'Which article?'}],
      },
      'language': 'en',
    });

    expect(article.body.length, 2);
    expect(article.body.first.type, 'rich_text');
    expect(article.body.first.string0, '<p>Hi</p>');
    expect(article.body[1].type, 'revision_box');
    expect(article.keywords, ['Article 356']);
    expect(article.mainsRelevance, 'Centre-State relations');
    expect(article.tags.single.name, 'Federalism');

    expect(article.related['articles']!.single.slug, 'y');
    expect(article.related['mcqs']!.single.title, 'Which article?');
  });

  test('gracefully handles missing/empty optional fields', () {
    final article = Article.fromResponse({
      'article': {'id': 1, 'slug': 'x', 'title': 'X'},
    });
    expect(article.body, isEmpty);
    expect(article.tags, isEmpty);
    expect(article.related, isEmpty);
    expect(article.card.difficulty, 'medium');
  });
}
