import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:lab_2/main.dart';
import 'package:lab_2/models/author.dart';
import 'package:lab_2/models/publication.dart';
import 'package:lab_2/screens/author_detail_screen.dart';
import 'package:lab_2/screens/detail_screen.dart';
import 'package:lab_2/screens/search_screen.dart';
import 'package:lab_2/screens/trend_screen.dart';
import 'package:lab_2/services/openalex_service.dart';
import 'package:lab_2/state/analytics_provider.dart';

class _FakeOpenAlexService extends OpenAlexService {
  String? requestedAuthorId;
  String? requestedAuthorName;

  static const authorDetail = AuthorDetail(
    id: 'A-test',
    displayName: 'Ada Lovelace',
    orcid: '0000-0001-2345-6789',
    worksCount: 256,
    citedByCount: 4096,
    lastKnownInstitutionName: 'Analytical Engine Institute',
    hIndex: 64,
    i10Index: 120,
  );

  final generalPaper = Publication(
    id: 'W-general',
    title: 'General research paper',
    publicationYear: 2025,
    publicationDate: '2025-06-01',
    citedByCount: 120,
    journalName: 'General Journal',
    authors: const [AuthorInfo(id: 'A-general', name: 'General Author')],
  );

  final searchPaper = Publication(
    id: 'W-search',
    title: 'Quantum Computing result',
    publicationYear: 2024,
    publicationDate: '2024-03-10',
    citedByCount: 42,
    journalName: 'Quantum Journal',
    authors: const [AuthorInfo(id: 'A-search', name: 'Search Author')],
  );

  @override
  Future<OpenAlexSearchResult> fetchGeneralPublications() async {
    return OpenAlexSearchResult(
      publications: [generalPaper],
      totalResults: 1000,
      pageSize: OpenAlexService.defaultPageSize,
    );
  }

  @override
  Future<OpenAlexSearchResult> fetchLatestPublications() async {
    return OpenAlexSearchResult(
      publications: [generalPaper],
      totalResults: 100,
      pageSize: OpenAlexService.latestPageSize,
    );
  }

  @override
  Future<OpenAlexSearchResult> fetchPublications(String query) async {
    return OpenAlexSearchResult(
      publications: [searchPaper],
      totalResults: 12,
      pageSize: OpenAlexService.defaultPageSize,
    );
  }

  @override
  Future<AuthorDetail> resolveAuthorDetail({
    String? authorId,
    required String authorName,
  }) async {
    requestedAuthorId = authorId;
    requestedAuthorName = authorName;
    return authorDetail;
  }
}

void main() {
  test('normalizes OpenAlex author IDs from authorship data', () {
    final author = AuthorInfo.fromAuthorshipJson({
      'author': {
        'id': 'https://openalex.org/A123456789',
        'display_name': 'Ada Lovelace',
      },
    });

    expect(author.id, 'A123456789');
    expect(author.name, 'Ada Lovelace');
    expect(author.hasOpenAlexId, isTrue);
  });

  testWidgets('shows four main tabs and static profile', (tester) async {
    await tester.pumpWidget(const MyApp(autoLoadHotTopic: false));

    expect(find.byKey(const ValueKey('nav_Home')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav_Search')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav_Phân tích')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav_Profile')), findsOneWidget);
    expect(find.text('Khám phá nghiên cứu nổi bật'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav_Profile')));
    await tester.pumpAndSettle();

    expect(find.text('About us'), findsOneWidget);
    expect(find.text('PRM393 • Lab 2'), findsOneWidget);
  });

  testWidgets('search keeps and clears keyword history', (tester) async {
    final provider = AnalyticsProvider(apiService: _FakeOpenAlexService());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: SearchScreen()),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('search_topic_input')),
      'Quantum Computing',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Lịch sử tìm kiếm'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('recent_search_Quantum Computing')),
      findsOneWidget,
    );
    expect(find.text('Quantum Computing result'), findsOneWidget);

    await tester.tap(find.byKey(const Key('clear_search_history')));
    await tester.pump();

    expect(find.text('Lịch sử tìm kiếm'), findsNothing);
  });

  testWidgets('analysis switches from general to keyword rankings', (
    tester,
  ) async {
    final provider = AnalyticsProvider(apiService: _FakeOpenAlexService());
    await provider.loadGeneralData();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: TrendScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Xếp hạng chung'), findsOneWidget);

    await provider.searchTopic('Quantum Computing');
    await tester.pumpAndSettle();

    expect(find.text('Xếp hạng theo từ khóa'), findsOneWidget);
    expect(find.textContaining('Quantum Computing'), findsOneWidget);
  });

  testWidgets('author detail loads a complete academic profile', (
    tester,
  ) async {
    final service = _FakeOpenAlexService();

    await tester.pumpWidget(
      MaterialApp(
        home: AuthorDetailScreen(
          authorId: 'A123456789',
          authorName: 'Ada Lovelace',
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chi tiết tác giả'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('Analytical Engine Institute'), findsOneWidget);
    expect(find.text('256'), findsOneWidget);
    expect(find.text('4096'), findsOneWidget);
    expect(find.text('64'), findsOneWidget);
    expect(service.requestedAuthorId, 'A123456789');
    expect(service.requestedAuthorName, 'Ada Lovelace');
  });

  testWidgets('paper detail opens the selected author profile', (tester) async {
    final service = _FakeOpenAlexService();
    final publication = Publication(
      id: 'W-feature',
      title: 'Feature navigation paper',
      publicationYear: 2025,
      publicationDate: '2025-01-01',
      citedByCount: 88,
      journalName: 'Feature Journal',
      authors: const [AuthorInfo(id: 'A123456789', name: 'Ada Lovelace')],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(publication: publication, authorService: service),
      ),
    );

    await tester.tap(find.text('Ada Lovelace'));
    await tester.pumpAndSettle();

    expect(find.byType(AuthorDetailScreen), findsOneWidget);
    expect(find.text('Chi tiết tác giả'), findsOneWidget);
    expect(service.requestedAuthorId, 'A123456789');
  });

  testWidgets('top author ranking opens the author profile', (tester) async {
    final service = _FakeOpenAlexService();
    final provider = AnalyticsProvider(apiService: service);
    await provider.loadGeneralData();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(home: TrendScreen(authorService: service)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Top Tác giả'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('General Author'));
    await tester.pumpAndSettle();

    expect(find.byType(AuthorDetailScreen), findsOneWidget);
    expect(service.requestedAuthorId, 'A-general');
    expect(service.requestedAuthorName, 'General Author');
  });
}
