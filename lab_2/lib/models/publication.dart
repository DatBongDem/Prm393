import 'author.dart';

class Publication {
  final String id;
  final String title;
  final int publicationYear;
  final String publicationDate;
  final String? doi;
  final int citedByCount;
  final String journalName;
  final List<AuthorInfo> authors;
  final String? abstractText;

  Publication({
    required this.id,
    required this.title,
    required this.publicationYear,
    required this.publicationDate,
    this.doi,
    required this.citedByCount,
    required this.journalName,
    required this.authors,
    this.abstractText,
  });

  factory Publication.fromJson(Map<String, dynamic> json) {
    final List<AuthorInfo> parsedAuthors = [];
    if (json['authorships'] is List) {
      for (final authorObj in json['authorships']) {
        if (authorObj is Map<String, dynamic>) {
          final parsedAuthor = AuthorInfo.fromAuthorshipJson(authorObj);
          if (parsedAuthor.name.isNotEmpty) {
            parsedAuthors.add(parsedAuthor);
          }
        }
      }
    }

    String journal = 'Unknown Journal';
    if (json['primary_location'] != null && json['primary_location']['source'] != null) {
      journal = json['primary_location']['source']['display_name'] ?? 'Unknown Journal';
    } else if (json['best_oa_location'] != null && json['best_oa_location']['source'] != null) {
      journal = json['best_oa_location']['source']['display_name'] ?? 'Unknown Journal';
    } else if (json['locations'] != null && (json['locations'] as List).isNotEmpty) {
      for (final loc in json['locations']) {
        if (loc['source'] != null && loc['source']['display_name'] != null) {
          journal = loc['source']['display_name'];
          break;
        }
      }
    }

    String? reconstructedAbstract;
    final invertedIndex = json['abstract_inverted_index'];
    if (invertedIndex != null && invertedIndex is Map<String, dynamic>) {
      reconstructedAbstract = _reconstructAbstract(invertedIndex);
    }

    return Publication(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled',
      publicationYear: json['publication_year'] ?? 0,
      publicationDate: json['publication_date'] ?? '',
      doi: json['doi'],
      citedByCount: json['cited_by_count'] ?? 0,
      journalName: journal,
      authors: parsedAuthors,
      abstractText: reconstructedAbstract,
    );
  }

  static String? _reconstructAbstract(Map<String, dynamic> invertedIndex) {
    if (invertedIndex.isEmpty) return null;

    var maxIndex = -1;
    invertedIndex.forEach((word, indices) {
      if (indices is List) {
        for (final idx in indices) {
          if (idx is int && idx > maxIndex) {
            maxIndex = idx;
          }
        }
      }
    });

    if (maxIndex == -1) return null;

    final wordsList = List<String?>.filled(maxIndex + 1, null);
    invertedIndex.forEach((word, indices) {
      if (indices is List) {
        for (final idx in indices) {
          if (idx is int && idx >= 0 && idx < wordsList.length) {
            wordsList[idx] = word;
          }
        }
      }
    });

    return wordsList.map((w) => w ?? '').join(' ').trim();
  }
}
