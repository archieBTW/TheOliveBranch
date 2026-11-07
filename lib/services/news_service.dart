
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/news_item.dart';

class NewsService {
  Future<List<NewsItem>> fetchNews() async {
    final sources = [
      {'url': 'http://feeds.sojo.net/sojourners/blog', 'name': 'Sojo'},
      {'url': 'https://www.redletterchristians.org/feed/', 'name': 'Red Letter'},
      {'url': 'https://baptistnews.com/feed/', 'name': 'BNG'},
      {'url': 'https://www.christiancentury.org/rss.xml', 'name': 'Christian Century'},
      {'url': 'https://goodfaithmedia.org/feed/', 'name': 'Good Faith Media'},
      {'url': 'https://religionnews.com/feed/', 'name': 'RNS'},
      {'url': 'http://ncronline.org/rss.xml', 'name': 'NCR'},
    ];

    return _fetchAndMerge(sources, 'News');
  }

  Future<List<NewsItem>> fetchMusic() async {
    final sources = [
      {'url': 'https://www.indievisionmusic.com/feed/', 'name': 'IVM'},
      {'url': 'https://hmmagazine.com/feed/', 'name': 'HM Mag'},
      {'url': 'https://relevantmagazine.com/feed/', 'name': 'Relevant'},
    ];

    return _fetchAndMerge(sources, 'Tunes');
  }

  Future<List<NewsItem>> _fetchAndMerge(
      List<Map<String, String>> sources, String category) async {
    final List<Future<List<NewsItem>>> futures = [];

    for (var source in sources) {
      futures.add(_fetchFeed(source['url']!, source['name']!, category));
      // Stagger requests slightly to avoid triggering rate limiters (429)
      // especially when using shared proxies or sensitive servers.
      if (kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    final results = await Future.wait(futures);
    final allItems = results.expand((element) => element).toList();
    
    // 1. Shuffle all items first. 
    // This allows items with IDENTICAL timestamps (e.g. "Just now" or "Yesterday") 
    // to be randomized relative to each other, instead of grouped by source.
    allItems.shuffle();
    
    // 2. Sort by date descending.
    // Dart's sort is stable, so shuffled order is preserved for equal timestamps.
    // This satisfies "Sorted by timestamp mainly" but "shuffled within that timestamp".
    allItems.sort((a, b) => b.pubDate.compareTo(a.pubDate));
    
    return allItems;
  }

  Future<List<NewsItem>> _fetchFeed(
      String url, String sourceName, String category, {int retryCount = 0}) async {
    try {
      final uri = Uri.parse(url);
      final effectiveUrl = kIsWeb 
          ? Uri.parse('/proxy/?url=$url') 
          : uri;

      final response = await http.get(
        effectiveUrl,
        headers: {
          'Accept': 'application/rss+xml, application/xml, text/xml; q=0.1',
        },
      );
      
      if (response.statusCode == 200) {
        // Strict XML check
        final body = response.body.trim();
        // Fix: Don't check for .contains('<html') blindly as RSS feeds contain embedded HTML in descriptions.
        // Only check if it STARTS with HTML tags.
        if (!body.startsWith('<') || 
            body.toLowerCase().startsWith('<!doctype html') || 
            body.toLowerCase().startsWith('<html')) {
           debugPrint('Feed $url returned HTML or invalid content');
           return [];
        }

        try {
          // Use compute to run parsing in a separate isolate
          return await compute(_parseFeedIsolate, {
            'body': response.body,
            'sourceName': sourceName,
            'category': category,
            'url': url,
          });
        } catch (e) {
           debugPrint('Error parsing XML for $url: $e');
           return [];
        }
      } else if (response.statusCode == 429 && retryCount < 2) {
        // Rate limited. Wait and retry.
        debugPrint('Rate limited for $url. Retrying in 2s...');
        await Future.delayed(const Duration(seconds: 2));
        return _fetchFeed(url, sourceName, category, retryCount: retryCount + 1);
      } else {
        debugPrint('Failed to load feed $url: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching $url: $e');
      return [];
    }
  }
}

// Top-level function for isolate
List<NewsItem> _parseFeedIsolate(Map<String, dynamic> data) {
  final body = data['body'] as String;
  final sourceName = data['sourceName'] as String;
  final category = data['category'] as String;
  // final url = data['url'] as String; // Unused but passed for context if needed

  final document = XmlDocument.parse(body);
  final items = document.findAllElements('item');

  return items.map((node) {
    final title = node.findElements('title').single.innerText;
    final link = node.findElements('link').single.innerText;
    final pubDateString = node.findElements('pubDate').single.innerText;
    final imageUrl = _extractImageUrl(node);
    
    DateTime pubDate = _parseDate(pubDateString);

    return NewsItem(
      title: title,
      link: link,
      pubDate: pubDate,
      source: sourceName,
      category: category,
      imageUrl: imageUrl,
    );
  }).toList();
}

String? _extractImageUrl(XmlElement node) {
  // 1. Check <enclosure>
  final enclosure = node.findElements('enclosure').firstOrNull;
  if (enclosure != null) {
    final type = enclosure.getAttribute('type');
    if (type != null && type.startsWith('image/')) {
      return enclosure.getAttribute('url');
    }
  }

  // 2. Check namespaced elements safely by iterating
  for (var child in node.children.whereType<XmlElement>()) {
    final name = child.name.qualified; // e.g. "media:content"
    
    if (name == 'media:content' || name == 'media:thumbnail') {
       final url = child.getAttribute('url');
       if (url != null && url.isNotEmpty) return url;
    }
  }

  // 3. Fallback: Parse HTML content for <img src="...">
  String? contentHtml;
  // content:encoded, content, or description
  for (var child in node.children.whereType<XmlElement>()) {
     if (child.name.qualified == 'content:encoded' || child.name.qualified == 'content') {
       contentHtml = child.innerText;
       break;
     }
  }
  contentHtml ??= node.findElements('description').firstOrNull?.innerText;

  if (contentHtml != null) {
    // Allow single or double quotes, match src attribute
    final RegExp imgRegex = RegExp(r'<img[^>]+src=["\x27]([^"\x27]+)["\x27]');
    final match = imgRegex.firstMatch(contentHtml);
    if (match != null) {
      return match.group(1);
    }
  }

  return null;
}

DateTime _parseDate(String dateString) {
  // Try multiple formats
  final formats = [
    DateFormat("EEE, dd MMM yyyy HH:mm:ss Z"), // RFC 1123
    DateFormat("EEE, dd MMM yyyy HH:mm:ss z"),
    DateFormat("yyyy-MM-ddTHH:mm:ssZ"), // ISO 8601
    DateFormat("yyyy-MM-dd HH:mm:ss"),
  ];

  for (var format in formats) {
    try {
      return format.parse(dateString);
    } catch (_) {}
  }

  try {
    return DateTime.parse(dateString);
  } catch (_) {}

  // Fallback: Random jitter to prevent strict shuffling order stability if multiple fail
  return DateTime.now().subtract(Duration(minutes: DateTime.now().millisecond));
}
