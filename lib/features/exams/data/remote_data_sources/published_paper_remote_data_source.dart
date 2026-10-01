import 'dart:convert';

import '../../../../core/network/network_client.dart';
import '../../domain/models/published_paper.dart';

/// Fetches and parses the published-paper catalog from
/// `GET {baseUrl}/api/published-papers`.
class PublishedPaperRemoteDataSource {
  PublishedPaperRemoteDataSource({
    required NetworkClient network,
    required String baseUrl,
  })  : _network = network,
        _baseUrl = baseUrl;

  final NetworkClient _network;
  final String _baseUrl;

  Future<List<PublishedPaper>> fetch({
    String? stream,
    String? subjectSlug,
    int? year,
  }) async {
    if (_baseUrl.isEmpty) {
      throw StateError(
        'API_BASE_URL is not configured. '
        'Run with --dart-define=API_BASE_URL=<backend base URL>.',
      );
    }

    final parameters = <String, String>{
      if (stream != null && stream.isNotEmpty) 'stream': stream,
      if (subjectSlug != null && subjectSlug.isNotEmpty) 'subject': subjectSlug,
      if (year != null) 'year': '$year',
    };
    final uri = Uri.parse('$_baseUrl/api/published-papers').replace(
      queryParameters: parameters.isEmpty ? null : parameters,
    );

    final body = await _network.getString(uri);
    return parseCatalogResponse(body);
  }

  /// Parses the catalog envelope `{ "papers": [ ... ] }`.
  ///
  /// Separated from [fetch] so tests can exercise parsing without a network.
  static List<PublishedPaper> parseCatalogResponse(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException catch (e) {
      throw FormatException('Catalog response is not valid JSON: ${e.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Catalog response must be a JSON object');
    }
    final papers = decoded['papers'];
    if (papers is! List) {
      throw const FormatException('Catalog response is missing "papers"');
    }
    return papers.map((raw) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Catalog entry must be a JSON object');
      }
      return PublishedPaper.fromJson(raw);
    }).toList(growable: false);
  }
}
