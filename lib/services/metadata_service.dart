
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser; // Need to add html package
import 'package:flutter/foundation.dart';

class MetadataService {
  final Map<String, String?> _cache = {};

  Future<String?> extractImage(String url) async {
    if (_cache.containsKey(url)) {
      return _cache[url];
    }

    try {
      final uri = Uri.parse(url);
      final effectiveUrl = kIsWeb 
          ? Uri.parse('https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(url)}') 
          : uri;

      final response = await http.get(
        effectiveUrl,
        // Removed User-Agent as it's an unsafe header on Web and can cause blocks on iOS
      );

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        
        // 1. Check og:image
        var ogImage = document.querySelector('meta[property="og:image"]');
        if (ogImage != null) {
          final content = ogImage.attributes['content'];
          if (content != null && content.isNotEmpty) {
            _cache[url] = content;
            return content;
          }
        }
        
        // 2. Check twitter:image
        var twitterImage = document.querySelector('meta[name="twitter:image"]');
        if (twitterImage != null) {
          final content = twitterImage.attributes['content'];
          if (content != null && content.isNotEmpty) {
             _cache[url] = content;
             return content;
          }
        }
        
        // 3. Fallback: First image in body? (Risky, might get icons)
        // Let's stick to meta tags for "thumbnails" to be safe.
      }
    } catch (e) {
      debugPrint('Error scraping metadata for $url: $e');
    }

    _cache[url] = null; // Cache failure so we don't retry endlessly
    return null;
  }
}
