class Publication {
  final String id;
  final String title;
  final int publicationYear;
  final String publicationDate;
  final String? doi;
  final int citedByCount;
  final String journalName;
  final List<String> authors;
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
    // Parse authors
    List<String> parsedAuthors = [];
    if (json['authorships'] != null) {
      for (var authorObj in json['authorships']) {
        var author = authorObj['author'];
        if (author != null && author['display_name'] != null) {
          parsedAuthors.add(author['display_name'].toString());
        }
      }
    }

    // Parse journal name
    String journal = 'Unknown Journal';
    if (json['primary_location'] != null && json['primary_location']['source'] != null) {
      journal = json['primary_location']['source']['display_name'] ?? 'Unknown Journal';
    } else if (json['best_oa_location'] != null && json['best_oa_location']['source'] != null) {
      journal = json['best_oa_location']['source']['display_name'] ?? 'Unknown Journal';
    } else if (json['locations'] != null && (json['locations'] as List).isNotEmpty) {
      for (var loc in json['locations']) {
        if (loc['source'] != null && loc['source']['display_name'] != null) {
          journal = loc['source']['display_name'];
          break;
        }
      }
    }

    // Reconstruct abstract from inverted index
    String? reconstructedAbstract;
    var invertedIndex = json['abstract_inverted_index'];
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

    int maxIndex = -1;
    invertedIndex.forEach((word, indices) {
      if (indices is List) {
        for (var idx in indices) {
          if (idx is int && idx > maxIndex) {
            maxIndex = idx;
          }
        }
      }
    });

    if (maxIndex == -1) return null;

    List<String?> wordsList = List.filled(maxIndex + 1, null);
    invertedIndex.forEach((word, indices) {
      if (indices is List) {
        for (var idx in indices) {
          if (idx is int && idx >= 0 && idx < wordsList.length) {
            wordsList[idx] = word;
          }
        }
      }
    });

    return wordsList.map((w) => w ?? "").join(" ").trim();
  }
}
