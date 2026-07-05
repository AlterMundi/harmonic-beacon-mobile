import 'package:flutter_test/flutter_test.dart';
import 'package:harmonic_beacon/models/meditation.dart';

void main() {
  group('Tag.fromJson', () {
    test('parses valid tag', () {
      final tag = Tag.fromJson({
        'id': 't1',
        'name': 'Calm',
        'slug': 'calm',
        'category': 'MOOD',
      });
      expect(tag.id, 't1');
      expect(tag.name, 'Calm');
      expect(tag.slug, 'calm');
      expect(tag.category, TagCategory.MOOD);
    });

    test('handles unknown category gracefully', () {
      final tag = Tag.fromJson({
        'id': 't2',
        'name': 'Other',
        'slug': 'other',
        'category': 'UNKNOWN',
      });
      expect(tag.category, TagCategory.MOOD); // default
    });

    test('parses all category types', () {
      for (final cat in ['MOOD', 'TECHNIQUE', 'DURATION', 'LANGUAGE']) {
        final tag = Tag.fromJson({
          'id': 'x',
          'name': 'x',
          'slug': 'x',
          'category': cat,
        });
        expect(tag.category.name, cat);
      }
    });
  });

  group('MeditationProvider.fromJson', () {
    test('parses name and avatarUrl', () {
      final p = MeditationProvider.fromJson({
        'name': 'Alice',
        'avatarUrl': 'https://example.com/alice.jpg',
      });
      expect(p.name, 'Alice');
      expect(p.avatarUrl, 'https://example.com/alice.jpg');
    });

    test('handles null fields', () {
      final p = MeditationProvider.fromJson({});
      expect(p.name, isNull);
      expect(p.avatarUrl, isNull);
    });
  });

  group('Meditation.fromJson', () {
    test('parses full meditation', () {
      final m = Meditation.fromJson({
        'id': 'm1',
        'title': 'Morning Calm',
        'description': 'A gentle start',
        'durationSeconds': 300,
        'streamName': 'morning-calm',
        'fileName': 'morning_calm.m4a',
        'isFeatured': true,
        'defaultMix': 0.7,
        'provider': {'name': 'Bob', 'avatarUrl': null},
        'tags': [
          {'id': 't1', 'name': 'Calm', 'slug': 'calm', 'category': 'MOOD'},
        ],
      });

      expect(m.id, 'm1');
      expect(m.title, 'Morning Calm');
      expect(m.description, 'A gentle start');
      expect(m.durationSeconds, 300);
      expect(m.isFeatured, true);
      expect(m.defaultMix, 0.7);
      expect(m.provider?.name, 'Bob');
      expect(m.tags.length, 1);
      expect(m.tags.first.name, 'Calm');
    });

    test('handles minimal json with defaults', () {
      final m = Meditation.fromJson({
        'id': 'm2',
        'title': 'Simple',
      });

      expect(m.id, 'm2');
      expect(m.title, 'Simple');
      expect(m.description, isNull);
      expect(m.durationSeconds, 0);
      expect(m.isFeatured, false);
      expect(m.defaultMix, 0.5);
      expect(m.provider, isNull);
      expect(m.tags, isEmpty);
    });

    test('formattedDuration works', () {
      final m = Meditation.fromJson({
        'id': 'x',
        'title': 'x',
        'durationSeconds': 125,
      });
      expect(m.formattedDuration, '2:05');
    });
  });
}
