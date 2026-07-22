class AuthorInfo {
  final String? id;
  final String name;

  const AuthorInfo({
    required this.id,
    required this.name,
  });

  bool get hasOpenAlexId => id != null && id!.isNotEmpty;

  factory AuthorInfo.fromAuthorshipJson(Map<String, dynamic> json) {
    final author = json['author'];
    final name = author?['display_name']?.toString().trim() ?? '';

    return AuthorInfo(
      id: _normalizeOpenAlexAuthorId(author?['id']?.toString()),
      name: name,
    );
  }

  static String? _normalizeOpenAlexAuthorId(String? rawId) {
    if (rawId == null || rawId.isEmpty) {
      return null;
    }

    final segments = Uri.tryParse(rawId)?.pathSegments ?? const <String>[];
    if (segments.isNotEmpty) {
      return segments.last;
    }

    return rawId;
  }
}

class AuthorDetail {
  final String id;
  final String displayName;
  final String? orcid;
  final int worksCount;
  final int citedByCount;
  final String? lastKnownInstitutionName;
  final int? hIndex;
  final int? i10Index;

  const AuthorDetail({
    required this.id,
    required this.displayName,
    this.orcid,
    required this.worksCount,
    required this.citedByCount,
    this.lastKnownInstitutionName,
    this.hIndex,
    this.i10Index,
  });

  factory AuthorDetail.fromJson(Map<String, dynamic> json) {
    final summaryStats = json['summary_stats'] as Map<String, dynamic>?;
    final lastKnownInstitution =
        json['last_known_institutions'] is List && (json['last_known_institutions'] as List).isNotEmpty
            ? (json['last_known_institutions'] as List).first as Map<String, dynamic>?
            : null;

    return AuthorDetail(
      id: AuthorInfo._normalizeOpenAlexAuthorId(json['id']?.toString()) ?? '',
      displayName: json['display_name']?.toString() ?? 'Unknown Author',
      orcid: _normalizeOrcid(json['orcid']?.toString()),
      worksCount: json['works_count'] is int ? json['works_count'] as int : 0,
      citedByCount: json['cited_by_count'] is int ? json['cited_by_count'] as int : 0,
      lastKnownInstitutionName: lastKnownInstitution?['display_name']?.toString(),
      hIndex: summaryStats?['h_index'] is int ? summaryStats!['h_index'] as int : null,
      i10Index: summaryStats?['i10_index'] is int ? summaryStats!['i10_index'] as int : null,
    );
  }

  static String? _normalizeOrcid(String? rawOrcid) {
    if (rawOrcid == null || rawOrcid.isEmpty) {
      return null;
    }

    final segments = Uri.tryParse(rawOrcid)?.pathSegments ?? const <String>[];
    if (segments.isNotEmpty) {
      return segments.last;
    }

    return rawOrcid;
  }
}

class TopAuthorStat {
  final String? authorId;
  final String displayName;
  final int publicationCount;

  const TopAuthorStat({
    required this.authorId,
    required this.displayName,
    required this.publicationCount,
  });

  bool get hasStableProfile => authorId != null && authorId!.isNotEmpty;
}
