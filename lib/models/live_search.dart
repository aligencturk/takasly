import 'package:takasly/utils/logger.dart';

class LiveSearchItem {
  final String type;
  final int id;
  final String title;
  final String subtitle;
  final String icon;

  LiveSearchItem({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  factory LiveSearchItem.fromJson(Map<String, dynamic> json) {
    try {
      return LiveSearchItem(
        type: (json['type'] ?? '').toString(),
        id: json['id'] is int
            ? json['id'] as int
            : int.tryParse(json['id']?.toString() ?? '') ?? 0,
        title: (json['title'] ?? '').toString(),
        subtitle: (json['subtitle'] ?? '').toString(),
        icon: (json['icon'] ?? '').toString(),
      );
    } catch (e) {
      Logger.error('❌ LiveSearchItem.fromJson error: $e');
      return LiveSearchItem(type: '', id: 0, title: '', subtitle: '', icon: '');
    }
  }
}

class LiveSearchData {
  final String searchText;
  final List<LiveSearchItem> results;
  final bool hasResults;

  LiveSearchData({
    required this.searchText,
    required this.results,
    required this.hasResults,
  });

  factory LiveSearchData.fromJson(Map<String, dynamic> json) {
    try {
      final List<dynamic> rawResults = (json['results'] as List?) ?? [];
      final items = rawResults
          .where((e) => e != null)
          .map((e) => LiveSearchItem.fromJson(e as Map<String, dynamic>))
          .where((e) => e.id != 0)
          .toList();
      return LiveSearchData(
        searchText: (json['searchText'] ?? '').toString(),
        results: items,
        hasResults: json['hasResults'] == true || items.isNotEmpty,
      );
    } catch (e) {
      Logger.error('❌ LiveSearchData.fromJson error: $e');
      return LiveSearchData(
        searchText: '',
        results: const [],
        hasResults: false,
      );
    }
  }
}

class LiveSearchResponse {
  final bool error;
  final bool success;
  final LiveSearchData data;

  LiveSearchResponse({
    required this.error,
    required this.success,
    required this.data,
  });

  factory LiveSearchResponse.fromJson(dynamic json) {
    try {
      if (json is Map<String, dynamic>) {
        return LiveSearchResponse(
          error: json['error'] == true,
          success: json['success'] == true,
          data: LiveSearchData.fromJson(
            (json['data'] as Map<String, dynamic>?) ?? {},
          ),
        );
      }
      return LiveSearchResponse(
        error: false,
        success: true,
        data: LiveSearchData(
          searchText: '',
          results: const [],
          hasResults: false,
        ),
      );
    } catch (e) {
      Logger.error('❌ LiveSearchResponse.fromJson error: $e');
      return LiveSearchResponse(
        error: true,
        success: false,
        data: LiveSearchData(
          searchText: '',
          results: const [],
          hasResults: false,
        ),
      );
    }
  }

  factory LiveSearchResponse.empty(String searchText) {
    return LiveSearchResponse(
      error: false,
      success: true,
      data: LiveSearchData(
        searchText: searchText,
        results: const [],
        hasResults: false,
      ),
    );
  }
}

class SearchHistoryItem {
  final String search;
  final int searchCount;
  final String lastSearched;
  final String formattedDate;

  SearchHistoryItem({
    required this.search,
    required this.searchCount,
    required this.lastSearched,
    required this.formattedDate,
  });

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      search: (json['search'] ?? '').toString(),
      searchCount: int.tryParse(json['searchCount']?.toString() ?? '0') ?? 0,
      lastSearched: (json['lastSearched'] ?? '').toString(),
      formattedDate: (json['formattedDate'] ?? '').toString(),
    );
  }
}

class SearchHistoryResponse {
  final List<SearchHistoryItem> items;
  final int totalItems;

  SearchHistoryResponse({required this.items, required this.totalItems});

  factory SearchHistoryResponse.fromJson(dynamic json) {
    try {
      final data = (json is Map<String, dynamic>) ? (json['data'] ?? {}) : {};
      final List<dynamic> raw = (data['searchHistory'] as List?) ?? [];
      final items = raw
          .where((e) => e != null)
          .map((e) => SearchHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final total = int.tryParse(data['totalItems']?.toString() ?? '0') ?? 0;
      return SearchHistoryResponse(items: items, totalItems: total);
    } catch (e) {
      Logger.error('❌ SearchHistoryResponse.fromJson error: $e');
      return SearchHistoryResponse(items: const [], totalItems: 0);
    }
  }
}
