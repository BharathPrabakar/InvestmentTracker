import 'dart:convert';
import 'package:http/http.dart' as http;

class YahooStockSearchResult {
  final String symbol;
  final String shortname;
  final String longname;
  final String exchange;
  final String quoteType;

  const YahooStockSearchResult({
    required this.symbol,
    required this.shortname,
    required this.longname,
    required this.exchange,
    required this.quoteType,
  });

  String get displayName =>
      longname.isNotEmpty ? longname : (shortname.isNotEmpty ? shortname : symbol);

  factory YahooStockSearchResult.fromJson(Map<String, dynamic> json) {
    return YahooStockSearchResult(
      symbol: json['symbol'] ?? '',
      shortname: json['shortname'] ?? '',
      longname: json['longname'] ?? '',
      exchange: json['exchange'] ?? '',
      quoteType: json['quoteType'] ?? '',
    );
  }
}

class YahooFinanceService {
  static const String _baseUrl = 'https://query2.finance.yahoo.com/v1/finance/search';

  /// Searches stocks exclusively via Yahoo Finance autocomplete search
  static Future<List<YahooStockSearchResult>> searchStocks(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl?q=${Uri.encodeComponent(cleanQuery)}&quotesCount=15&newsCount=0');
      final response = await http.get(
        uri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final quotes = data['quotes'] as List<dynamic>? ?? [];

        final results = quotes
            .map((q) => YahooStockSearchResult.fromJson(q as Map<String, dynamic>))
            .where((item) =>
                item.symbol.isNotEmpty &&
                (item.quoteType == 'EQUITY' ||
                    item.quoteType == 'ETF' ||
                    item.quoteType.isEmpty))
            .toList();

        // Prioritize Indian stock market equities (NSE / BSE) first
        results.sort((a, b) {
          final aIsIndian = a.symbol.endsWith('.NS') ||
              a.symbol.endsWith('.BO') ||
              a.exchange == 'NSI' ||
              a.exchange == 'BSE';
          final bIsIndian = b.symbol.endsWith('.NS') ||
              b.symbol.endsWith('.BO') ||
              b.exchange == 'NSI' ||
              b.exchange == 'BSE';
          if (aIsIndian && !bIsIndian) return -1;
          if (!aIsIndian && bIsIndian) return 1;
          return 0;
        });

        return results;
      }
    } catch (_) {
      // In case of network timeout or error, return empty list gracefully
    }
    return [];
  }
}
