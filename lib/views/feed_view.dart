import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/news_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/news_item.dart';
import 'widgets/news_card.dart';

class FeedView extends StatefulWidget {
  final String category; // 'News' or 'Tunes'

  const FeedView({super.key, required this.category});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedSources = [];


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  
  // Available sources per category (Could move to a constant or provider)
  List<String> get _availableSources {
    if (widget.category == 'News') {
      return ['Sojo', 'Red Letter', 'BNG', 'Christian Century', 'Good Faith Media', 'RNS', 'NCR'];
    } else {
      return ['IVM', 'HM Mag', 'Relevant'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<NewsProvider, SettingsProvider>(
      builder: (context, newsProvider, settingsProvider, child) {
        bool isSpecificLoading = widget.category == 'News' ? newsProvider.isNewsLoading : newsProvider.isMusicLoading;
        List<NewsItem> items = widget.category == 'News' ? newsProvider.newsItems : newsProvider.musicItems;

        if (isSpecificLoading && items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (newsProvider.error != null && newsProvider.newsItems.isEmpty && newsProvider.musicItems.isEmpty) {
          return Center(child: Text('Error: ${newsProvider.error}'));
        }


        
        // 1. Filter by Enabled Sources (Global Settings)
        var filteredItems = items.where((item) {
          return settingsProvider.isSourceEnabled(item.source);
        }).toList();

        // 2. Filter by Local Selection (Chips)
        // If _selectedSources is empty, show all (that are enabled globally)
        if (_selectedSources.isNotEmpty) {
           filteredItems = filteredItems.where((item) => _selectedSources.contains(item.source)).toList();
        }

        // 3. Filter by Search Query
        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          filteredItems = filteredItems.where((item) {
            return item.title.toLowerCase().contains(query) || 
                   item.source.toLowerCase().contains(query);
          }).toList();
        }

        return Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            
            // Collapsible Filter Menu
            ExpansionTile(
              title: Text(
                'Filter Sources',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              leading: const Icon(Icons.filter_list),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              children: [
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _availableSources.map((source) {
                    if (!settingsProvider.isSourceEnabled(source)) return const SizedBox.shrink();

                    final isSelected = _selectedSources.contains(source);
                    return FilterChip(
                      label: Text(source),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedSources.add(source);
                          } else {
                            _selectedSources.remove(source);
                          }
                        });
                        
                        // Dynamic Fetch Logic
                        // If we just selected a filter, ensure we have enough items
                        if (selected) {
                           // Construct the active sources list
                           // If selectedSources is empty, it means ALL available (enabled) sources.
                           // But here we just added one, so it is NOT empty.
                           // So we pass _selectedSources.
                           // BUT wait, we must also intersect with settings? 
                           // The UI loop does: if (!settingsProvider.isSourceEnabled(source)) continue;
                           // So _selectedSources should only contain enabled sources if we manage it right.
                           // But for safety, let's just pass _selectedSources.
                           
                           final activeList = _selectedSources.toList();
                           final query = _searchController.text.toLowerCase();

                           if (widget.category == 'News') {
                             newsProvider.ensureFilteredNewsCount(
                               activeSources: activeList,
                               searchQuery: query,
                             );
                           } else {
                             newsProvider.ensureFilteredMusicCount(
                               activeSources: activeList,
                               searchQuery: query,
                             );
                           }
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),

            Expanded(
              child: filteredItems.isEmpty && !isSpecificLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No articles found.'),
                      if (_selectedSources.isNotEmpty) 
                        TextButton(
                           onPressed: () {
                             // Retry logic? or just show "Try loading more"
                             if (widget.category == 'News') {
                               newsProvider.loadMoreNews();
                             } else {
                               newsProvider.loadMoreMusic();
                             }
                           },
                           child: const Text('Load from history'),
                        )
                    ],
                  ),
                )
              : RefreshIndicator(
                onRefresh: () async {
                   if (widget.category == 'News') {
                     await newsProvider.refreshNews();
                   } else {
                     await newsProvider.refreshMusic();
                   }
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.9 &&
                        !newsProvider.isLoadingMore) {
                      if (widget.category == 'News') {
                        newsProvider.loadMoreNews();
                      } else {
                        newsProvider.loadMoreMusic();
                      }
                    }
                    return false;
                  },
                  child: ListView.builder(
                    itemCount: filteredItems.length + (newsProvider.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filteredItems.length) {
                         return const Padding(
                           padding: EdgeInsets.all(16.0),
                           child: Center(child: CircularProgressIndicator()),
                         );
                      }
                      return NewsCard(item: filteredItems[index]);
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
