
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import 'widgets/news_card.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bookmarks',
          style: GoogleFonts.merriweather(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<NewsProvider>(
        builder: (context, provider, child) {
          final bookmarks = provider.bookmarks;

          if (bookmarks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.bookmark_border, size: 60, color: Theme.of(context).colorScheme.outline),
                   const SizedBox(height: 16),
                   Text(
                    'No bookmarks yet',
                    style: GoogleFonts.lato(
                      fontSize: 18, 
                      color: Theme.of(context).colorScheme.onSurfaceVariant
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              // Show bookmarks in reverse order (newest added on top) usually preferred, 
              // or just as is. Let's do reversed.
              final item = bookmarks[bookmarks.length - 1 - index];
              return NewsCard(item: item);
            },
          );
        },
      ),
    );
  }
}
