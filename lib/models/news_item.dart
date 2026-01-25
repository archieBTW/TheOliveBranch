


class NewsItem {
  final String title;
  final String link;
  final DateTime pubDate;
  final String source;
  final String category; // 'News' or 'Tunes'
  final String? imageUrl;

  NewsItem({
    required this.title,
    required this.link,
    required this.pubDate,
    required this.source,
    required this.category,
    this.imageUrl,
  });

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(pubDate);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  NewsItem copyWith({
    String? title,
    String? link,
    DateTime? pubDate,
    String? source,
    String? category,
    String? imageUrl,
  }) {
    return NewsItem(
      title: title ?? this.title,
      link: link ?? this.link,
      pubDate: pubDate ?? this.pubDate,
      source: source ?? this.source,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'link': link,
      'pubDate': pubDate.toIso8601String(),
      'source': source,
      'category': category,
      'imageUrl': imageUrl,
    };
  }

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      title: json['title'],
      link: json['link'],
      pubDate: DateTime.parse(json['pubDate']),
      source: json['source'],
      category: json['category'],
      imageUrl: json['imageUrl'],
    );
  }
}

