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
  final String? type; // 'text' veya 'category'
  final String? categoryId; // Kategori ID'si (sadece kategori türü için)

  SearchHistoryItem({
    required this.search,
    required this.searchCount,
    required this.lastSearched,
    required this.formattedDate,
    this.type,
    this.categoryId,
  });

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    // Alternatif alan adları için esnek parse
    final String searchText =
        (json['search'] ??
                json['searchText'] ??
                json['query'] ??
                json['text'] ??
                '')
            .toString();

    final int count =
        int.tryParse(
          (json['searchCount'] ?? json['count'] ?? json['times'])?.toString() ??
              '0',
        ) ??
        0;

    final String last =
        (json['lastSearched'] ??
                json['lastSearch'] ??
                json['lastSearchedAt'] ??
                json['date'] ??
                json['createdAt'] ??
                '')
            .toString();

    final String formatted =
        (json['formattedDate'] ??
                json['formatted'] ??
                json['lastSearchedHumanized'] ??
                '')
            .toString();

    final String? itemType = json['type']?.toString();
    final String? catId = json['categoryId']?.toString();

    return SearchHistoryItem(
      search: searchText,
      searchCount: count,
      lastSearched: last,
      formattedDate: formatted,
      type: itemType,
      categoryId: catId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'search': search,
      'searchCount': searchCount,
      'lastSearched': lastSearched,
      'formattedDate': formattedDate,
      'type': type,
      'categoryId': categoryId,
    };
  }
}

class SearchHistoryResponse {
  final List<SearchHistoryItem> items;
  final int totalItems;

  SearchHistoryResponse({required this.items, required this.totalItems});

  factory SearchHistoryResponse.fromJson(dynamic json) {
    try {
      Map<String, dynamic> root = {};
      if (json is Map<String, dynamic>) root = json;

      // data alanını yakala (yoksa root'u kullan)
      final dynamic dataDyn = root['data'] ?? root;
      final Map<String, dynamic> data = dataDyn is Map<String, dynamic>
          ? dataDyn
          : <String, dynamic>{};

      // Liste farklı anahtarlar altında gelebilir
      List<dynamic> raw = [];
      if (data['searchHistory'] is List) {
        raw = data['searchHistory'] as List<dynamic>;
      } else if (data['history'] is List) {
        raw = data['history'] as List<dynamic>;
      } else if (data['items'] is List) {
        raw = data['items'] as List<dynamic>;
      } else if (root['searchHistory'] is List) {
        raw = root['searchHistory'] as List<dynamic>;
      } else if (root['data'] is List) {
        raw = root['data'] as List<dynamic>;
      }

      final items = raw
          .where((e) => e != null)
          .map(
            (e) => SearchHistoryItem.fromJson(
              (e is Map<String, dynamic>) ? e : <String, dynamic>{},
            ),
          )
          .where((e) => e.search.isNotEmpty)
          .toList();

      final int total =
          int.tryParse(
            (data['totalItems'] ?? data['total'] ?? items.length).toString(),
          ) ??
          items.length;

      return SearchHistoryResponse(items: items, totalItems: total);
    } catch (e) {
      Logger.error('❌ SearchHistoryResponse.fromJson error: $e');
      return SearchHistoryResponse(items: const [], totalItems: 0);
    }
  }
}
