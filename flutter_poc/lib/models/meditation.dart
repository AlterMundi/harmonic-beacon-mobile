enum TagCategory { MOOD, TECHNIQUE, DURATION, LANGUAGE }

TagCategory _parseTagCategory(String value) {
  switch (value.toUpperCase()) {
    case 'MOOD':
      return TagCategory.MOOD;
    case 'TECHNIQUE':
      return TagCategory.TECHNIQUE;
    case 'DURATION':
      return TagCategory.DURATION;
    case 'LANGUAGE':
      return TagCategory.LANGUAGE;
    default:
      return TagCategory.MOOD;
  }
}

class Tag {
  final String id;
  final String name;
  final String slug;
  final TagCategory category;

  const Tag({
    required this.id,
    required this.name,
    required this.slug,
    required this.category,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      category: _parseTagCategory(json['category'] as String? ?? 'MOOD'),
    );
  }
}

class MeditationProvider {
  final String? name;
  final String? avatarUrl;

  const MeditationProvider({this.name, this.avatarUrl});

  factory MeditationProvider.fromJson(Map<String, dynamic> json) {
    return MeditationProvider(
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class Meditation {
  final String id;
  final String title;
  final String? description;
  final int durationSeconds;
  final String streamName;
  final String fileName;
  final bool isFeatured;
  final double defaultMix;
  final MeditationProvider? provider;
  final List<Tag> tags;

  const Meditation({
    required this.id,
    required this.title,
    this.description,
    required this.durationSeconds,
    required this.streamName,
    required this.fileName,
    this.isFeatured = false,
    this.defaultMix = 0.5,
    this.provider,
    this.tags = const [],
  });

  String get formattedDuration {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  factory Meditation.fromJson(Map<String, dynamic> json) {
    return Meditation(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      streamName: json['streamName'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      isFeatured: json['isFeatured'] as bool? ?? false,
      defaultMix: (json['defaultMix'] as num?)?.toDouble() ?? 0.5,
      provider: json['provider'] != null
          ? MeditationProvider.fromJson(json['provider'] as Map<String, dynamic>)
          : null,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((t) => Tag.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
