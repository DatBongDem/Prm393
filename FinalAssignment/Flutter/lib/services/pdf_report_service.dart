import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/publication.dart';

class PdfReportService {
  static Future<Map<String, String>> generateAndUploadReport({
    required String topic,
    required List<Publication> publications,
  }) async {
    final pdf = pw.Document();
    
    // Tính toán số liệu thống kê
    final totalPublications = publications.length;
    final totalCitations = publications.fold<int>(0, (sum, item) => sum + item.citedByCount);
    final avgCitations = totalPublications > 0 ? totalCitations / totalPublications : 0.0;
    
    // Tìm tạp chí đóng góp nhiều nhất
    final Map<String, int> journalCounts = {};
    for (final pub in publications) {
      journalCounts[pub.journalName] = (journalCounts[pub.journalName] ?? 0) + 1;
    }
    String topJournal = 'N/A';
    int maxJournalCount = 0;
    journalCounts.forEach((name, count) {
      if (count > maxJournalCount) {
        maxJournalCount = count;
        topJournal = name;
      }
    });

    // Tạo nội dung trang PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'RESEARCH TOPIC ANALYSIS REPORT',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Topic: $topic', style: const pw.TextStyle(fontSize: 16)),
          pw.Text('Date Generated: ${DateTime.now().toLocal().toString()}', style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 20),
          
          pw.Text('Summary Statistics', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
          pw.Divider(),
          pw.Bullet(text: 'Total Publications: $totalPublications'),
          pw.Bullet(text: 'Total Citations: $totalCitations'),
          pw.Bullet(text: 'Average Citations: ${avgCitations.toStringAsFixed(2)}'),
          pw.Bullet(text: 'Top Contributing Journal: $topJournal ($maxJournalCount papers)'),
          pw.SizedBox(height: 20),
          
          pw.Text('Top Publications (by Citation Count)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
          pw.Divider(),
          ...publications.take(10).map((pub) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    pub.title,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                  ),
                  pw.Text(
                    'Year: ${pub.publicationYear} | Citations: ${pub.citedByCount} | Journal: ${pub.journalName}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );

    // Lưu file dưới bộ nhớ tạm local
    final tempDir = await getTemporaryDirectory();
    final String fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final File file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    // Lấy id người dùng
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'anonymous';

    // Tải lên Firebase Storage
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('reports')
        .child(userId)
        .child(fileName);

    // Timeout để tránh treo UI vô thời hạn nếu Storage chưa được khởi tạo
    // hoặc thiết bị mất kết nối mạng.
    final uploadTask = await storageRef
        .putFile(file)
        .timeout(const Duration(seconds: 30));
    final downloadUrl = await uploadTask.ref
        .getDownloadURL()
        .timeout(const Duration(seconds: 15));

    return {
      'url': downloadUrl,
      'fileName': fileName,
    };
  }
}
