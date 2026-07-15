import 'package:flutter_test/flutter_test.dart';
import 'package:lab_3/models/publication.dart';

void main() {
  test('Publication.fromJson parses OpenAlex work data', () {
    final publication = Publication.fromJson({
      'id': 'https://openalex.org/W123',
      'title': 'Research Trend Analysis',
      'publication_year': 2026,
      'publication_date': '2026-07-15',
      'doi': 'https://doi.org/10.1234/example',
      'cited_by_count': 42,
      'primary_location': {
        'source': {'display_name': 'Journal of Research Analytics'},
      },
      'authorships': [
        {
          'author': {
            'id': 'https://openalex.org/A456',
            'display_name': 'Nguyen Van A',
          },
        },
      ],
      'abstract_inverted_index': {
        'OpenAlex': [0],
        'data': [1],
        'powers': [2],
        'analytics.': [3],
      },
      'concepts': [
        {'display_name': 'Data Science'},
        {'display_name': 'Scholarly Communication'},
      ],
    });

    expect(publication.title, 'Research Trend Analysis');
    expect(publication.journalName, 'Journal of Research Analytics');
    expect(publication.authors.single.name, 'Nguyen Van A');
    expect(publication.abstractText, 'OpenAlex data powers analytics.');
    expect(publication.concepts, contains('Data Science'));
  });
}
