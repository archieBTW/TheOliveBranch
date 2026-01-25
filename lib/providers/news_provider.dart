
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/news_item.dart';
import '../services/news_service.dart';
import '../services/metadata_service.dart';

class NewsProvider with ChangeNotifier {
  final NewsService _newsService = NewsService();
  final MetadataService _metadataService = MetadataService();
  
  NewsProvider() {
    loadUserData();
  }

  List<NewsItem> _allNews = []; // Raw items from RSS
  List<NewsItem> _allMusic = []; // Raw items from RSS
  
  List<NewsItem> _displayedNews = [];
  List<NewsItem> _displayedMusic = [];
  
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  int _newsLimit = 0;
  int _musicLimit = 0;
  static const int _batchSize = 10;

  List<NewsItem> get newsItems => _displayedNews;
  List<NewsItem> get musicItems => _displayedMusic;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;

  bool _isNewsLoading = false;
  bool _isMusicLoading = false;
  
  bool get isNewsLoading => _isNewsLoading;
  bool get isMusicLoading => _isMusicLoading;
  // Backwards compatibility for now, though FeedView will be updated
  bool get isLoading => _isNewsLoading || _isMusicLoading;

  Future<void> loadNewsInitial() async {
    if (_allNews.isNotEmpty) return; // Prevent reload if already loaded? Or allow refresh?
                                     // For refresh, we usually clear and reload.
                                     // But initial load should check emptiness to identify "first load".
                                     // Actually refresh calls this too? No, refresh calls loadAllData normally.
                                     // Let's make this strictly "Initial/Refresh" logic for News.
    
    _isNewsLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allNews = await _newsService.fetchNews();
      
      _displayedNews = [];
      _newsLimit = 0;

      await _loadMoreNewsBatch();

    } catch (e) {
      _error = e.toString();
    } finally {
      _isNewsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMusicInitial() async {
    if (_allMusic.isNotEmpty) return; // Lazy load optimization: don't reload if we have data
    
    _isMusicLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allMusic = await _newsService.fetchMusic();
      
      _displayedMusic = [];
      _musicLimit = 0;

      await _loadMoreMusicBatch();

    } catch (e) {
      _error = e.toString();
    } finally {
      _isMusicLoading = false;
      notifyListeners();
    }
  }

  // Keep loadAllData for RefreshIndicator if needed, or update RefreshIndicator to call specific
  Future<void> reloadAll() async {
     _allNews = [];
     _allMusic = []; // Force reload both?
     // Actually refresh usually refreshes the CURRENT view.
     // But let's keep a method to refresh everything if needed, or just refresh individually.
     
     // Simplify: refresh clears the specific list and calls loadInitial again.
     return loadNewsInitial(); 
  }
  
  // Helper to force refresh news
  Future<void> refreshNews() async {
    _allNews = [];
    await loadNewsInitial();
  }

  // Helper to force refresh music
  Future<void> refreshMusic() async {
    _allMusic = [];
    await loadMusicInitial();
  }

  Future<void> loadMoreNews() async {
    if (_isLoadingMore || _displayedNews.length >= _allNews.length) return;
    _isLoadingMore = true;
    notifyListeners();

    await _loadMoreNewsBatch();

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> loadMoreMusic() async {
     if (_isLoadingMore || _displayedMusic.length >= _allMusic.length) return;
    _isLoadingMore = true;
    notifyListeners();

    await _loadMoreMusicBatch();

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> _loadMoreNewsBatch() async {
    if (_newsLimit >= _allNews.length) return;

    // Determine the date range for the next batch
    // Start from the date of the last loaded item, or now if none loaded
    final lastDate = _displayedNews.isNotEmpty 
        ? _displayedNews.last.pubDate 
        : DateTime.now();
    
    final targetDate = lastDate.subtract(const Duration(hours: 24));

    // Find items in the next 1-day window, starting from current limit
    int nextLimit = _newsLimit;
    while (nextLimit < _allNews.length && 
           _allNews[nextLimit].pubDate.isAfter(targetDate)) {
      nextLimit++;
    }
    
    // Fallback: If the window yielded < 15 items, just grab the next batch of 15 to ensure the UI updates/doesn't stall.
    if ((nextLimit - _newsLimit) < 15 && nextLimit < _allNews.length) {
       nextLimit = (_newsLimit + 15).clamp(0, _allNews.length);
    }

    final batch = _allNews.sublist(_newsLimit, nextLimit);
    
    // OPTIMIZATION: Show text immediately!
    _displayedNews.addAll(batch);
    _newsLimit = nextLimit;
    notifyListeners();

    // Fetch metadata in background and update items individually
    _updateMetadataForBatch(batch, isNews: true);
  }

  Future<void> _loadMoreMusicBatch() async {
    if (_musicLimit >= _allMusic.length) return;

    final lastDate = _displayedMusic.isNotEmpty 
        ? _displayedMusic.last.pubDate 
        : DateTime.now();
    
    final targetDate = lastDate.subtract(const Duration(hours: 24));

    int nextLimit = _musicLimit;
    while (nextLimit < _allMusic.length && 
           _allMusic[nextLimit].pubDate.isAfter(targetDate)) {
      nextLimit++;
    }

    if ((nextLimit - _musicLimit) < 15 && nextLimit < _allMusic.length) {
       nextLimit = (_musicLimit + 15).clamp(0, _allMusic.length);
    }
    
    final batch = _allMusic.sublist(_musicLimit, nextLimit);
    
    // OPTIMIZATION: Show text immediately!
    _displayedMusic.addAll(batch);
    _musicLimit = nextLimit;
    notifyListeners();

    // Fetch metadata in background
    _updateMetadataForBatch(batch, isNews: false);
  }

  Future<void> _updateMetadataForBatch(List<NewsItem> batch, {required bool isNews}) async {
    // Process metadata in parallel but update UI as they finish? 
    // Or just let them finish individually.
    // Iterating with Future.wait is fine, but we want individual updates.
    
    // We start all requests, and when each one completes, we update the UI.
    final futures = batch.map((item) async {
      if (item.imageUrl != null) return; // Already has image

      try {
        final image = await _metadataService.extractImage(item.link);
        if (image != null) {
          final newItem = item.copyWith(imageUrl: image);
          
          // Find and replace in the main list
          final list = isNews ? _displayedNews : _displayedMusic;
          final index = list.indexOf(item);
          
          if (index != -1) {
            list[index] = newItem;
            notifyListeners();
          }
        }
      } catch (e) {
        // debugPrint('Error processing metadata for ${item.title}: $e');
      }
    });

    // We don't await this function itself because the caller doesn't need to wait.
    // However, if we don't await, any subsequent "loadMore" calls might race?
    // No, loadMore adds to the END of the list. These updates are in-place for existing items.
    // It is safe to fire and forget.
    await Future.wait(futures);
  }

  // State for Bookmarks and Read items
  List<NewsItem> _bookmarks = [];
  Set<String> _readLinks = {};
  
  List<NewsItem> get bookmarks => _bookmarks;
  
  bool isBookmarked(String link) {
    return _bookmarks.any((item) => item.link == link);
  }

  bool isRead(String link) {
    return _readLinks.contains(link);
  }

  Future<void> toggleBookmark(NewsItem item) async {
    if (isBookmarked(item.link)) {
      _bookmarks.removeWhere((i) => i.link == item.link);
    } else {
      _bookmarks.add(item);
    }
    notifyListeners();
    await _saveBookmarks();
  }

  Future<void> markAsRead(String link) async {
    if (!_readLinks.contains(link)) {
      _readLinks.add(link);
      notifyListeners();
      await _saveReadLinks();
    }
  }

  // Persistence
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Bookmarks
    final bookmarksJson = prefs.getString('bookmarks_data');
    if (bookmarksJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(bookmarksJson);
        _bookmarks = decoded.map((e) => NewsItem.fromJson(e)).toList();
      } catch (e) {
        debugPrint('Error loading bookmarks: $e');
      }
    }

    // Load Read Links
    final readList = prefs.getStringList('read_links');
    if (readList != null) {
      _readLinks = readList.toSet();
    }
    notifyListeners();
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_bookmarks.map((e) => e.toJson()).toList());
    await prefs.setString('bookmarks_data', encoded);
  }

  Future<void> _saveReadLinks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('read_links', _readLinks.toList());
  }

  // Dynamic Filtering Logic
  Future<void> ensureFilteredNewsCount({
    required List<String> activeSources,
    required String searchQuery,
    int minCount = 15,
  }) async {
    await _ensureFilteredCountGeneric(
      allList: _allNews,
      displayedList: _displayedNews,
      limit: _newsLimit,
      loadMoreAction: _loadMoreNewsBatch,
      activeSources: activeSources,
      searchQuery: searchQuery,
      minCount: minCount,
    );
  }

  Future<void> ensureFilteredMusicCount({
    required List<String> activeSources,
    required String searchQuery,
    int minCount = 15,
  }) async {
    await _ensureFilteredCountGeneric(
      allList: _allMusic,
      displayedList: _displayedMusic,
      limit: _musicLimit,
      loadMoreAction: _loadMoreMusicBatch,
      activeSources: activeSources,
      searchQuery: searchQuery,
      minCount: minCount,
    );
  }

  Future<void> _ensureFilteredCountGeneric({
    required List<NewsItem> allList,
    required List<NewsItem> displayedList,
    required int limit,
    required Future<void> Function() loadMoreAction,
    required List<String> activeSources,
    required String searchQuery,
    required int minCount,
  }) async {
      int safetyCounter = 0;
      const int maxBatches = 5;

      while (safetyCounter < maxBatches) {
        // Check current visible count
        final visibleCount = displayedList.where((item) {
           final matchesSource = activeSources.contains(item.source);
           final matchesQuery = searchQuery.isEmpty || 
                                item.title.toLowerCase().contains(searchQuery) || 
                                item.source.toLowerCase().contains(searchQuery);
           return matchesSource && matchesQuery;
        }).length;

        // Note: limit is just a snapshot here, we need to check if we can actually load more.
        // We can check if the displayedList length is less than allList length?
        // Actually loadMoreAction checks `_limit >= _allList.length`.
         // Ideally we check if we exhausted the list.
         // Let's rely on the lists provided.
         // Since `displayedList` matches `limit` roughly (it is a sublist), 
         // we can check if `displayedList.length < allList.length`.
         
        if (visibleCount >= minCount) break; 
        if (displayedList.length >= allList.length) break; 

        // Load next batch
        // We must suppress the loading indicator if we want this to be seamless? 
        // Or show it. The prompt implies it should just "pull in at least 15 items".
        // It's presumably instant if data is in memory, but here we are paginating from memory.
        await loadMoreAction();
        
        safetyCounter++;
      }
  }
}
