
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/news_item.dart';
import '../../providers/news_provider.dart';

class NewsCard extends StatelessWidget {
  final NewsItem item;
  NewsCard({super.key, required this.item});

  Future<void> _launchUrl() async {
    final Uri url = Uri.parse(item.link);
    if (!await launchUrl(
      url,
      mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.inAppBrowserView,
    )) {
      debugPrint('Could not launch ${item.link}');
    }
  }

  Color _getSourceColor(String source, BuildContext context) {
    switch (source) {
      case 'Sojo':
        return Colors.green.shade800;
      case 'Red Letter':
        return Colors.red.shade800;
      case 'BNG':
        return Colors.blue.shade800;
      case 'HM Mag':
        return Colors.black;
      case 'IVM':
        return Colors.orange.shade800;
      case 'Christian Century':
        return Colors.blueGrey.shade800;
      case 'Good Faith Media':
        return Colors.teal.shade800;
      case 'RNS':
        return Colors.indigo.shade800;
      case 'NCR':
        return Colors.amber.shade900;
      case 'Relevant':
        return Colors.deepOrange.shade800;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes for THIS item specifically? 
    // We need to rebuild when bookmark/read status changes. 
    // Is it better to just Consumer around the pieces or the whole card? 
    // The parent list rebuilds often, but let's use Consumer to be safe and reactive.
    
    return Consumer<NewsProvider>(
      builder: (context, provider, child) {
        final isRead = provider.isRead(item.link);
        final isBookmarked = provider.isBookmarked(item.link);

        return Opacity(
          opacity: isRead ? 0.6 : 1.0,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () {
                provider.markAsRead(item.link);
                _launchUrl();
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getSourceColor(item.source, context),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            item.source,
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              item.formattedDate,
                              style: GoogleFonts.lato(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(width: 4), 
                          // Bookmark Button - Large touch target that consumes taps
                          // We use GestureDetector to ensure we catch 'missed' taps that would otherwise open the card.
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => provider.toggleBookmark(item),
                            child: Container(
                              padding: const EdgeInsets.all(12), // significantly increase touch area
                              // Visual debug: color: Colors.blue.withOpacity(0.2), 
                              child: Icon(
                                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                size: 28, 
                                color: isBookmarked 
                                  ? Theme.of(context).colorScheme.primary 
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: GoogleFonts.merriweather(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildImage(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildImage(BuildContext context) {
    // Images are now pre-fetched by the provider.
    // If we have an image URL, show it. Otherwise, show placeholder.
    if (item.imageUrl != null) {
      return Image.network(
        _getEffectiveImageUrl(item.imageUrl!),
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
      );
    }
    
    return _buildPlaceholder(context);
  }


  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      color: Theme.of(context).colorScheme.surfaceContainerHighest, // Fix for older SDK? verify
      child: Icon(
        Icons.newspaper,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 30,
      ),
    );
  }

  String _getEffectiveImageUrl(String url) {
    if (kIsWeb) {
      // Always proxy images on web to bypass hotlink protection
      return 'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(url)}';
    }
    return url;
  }
}
