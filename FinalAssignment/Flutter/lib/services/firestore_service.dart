import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirestoreService {
  // Tham chiếu đến các collection trên Cloud Firestore
  final CollectionReference _journalsCollection = FirebaseFirestore.instance
      .collection('journals');

  final CollectionReference _activeUsersCollection = FirebaseFirestore.instance
      .collection('active_users');

  final CollectionReference _notificationsCollection =
      FirebaseFirestore.instance.collection('notifications');

  // 1. Thêm một bản ghi nhật ký mới lên Firestore với userId của người dùng hiện tại
  Future<void> addJournalEntry(String title, String content) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await _journalsCollection.add({
        'title': title,
        'content': content,
        'userId': user?.uid, // Liên kết bản ghi với tài khoản đang đăng nhập
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Lỗi thêm nhật ký vào Firestore: $e');
      rethrow;
    }
  }

  // 1b. Cập nhật một bản ghi nhật ký trên Firestore
  Future<void> updateJournalEntry(
    String docId,
    String title,
    String content,
  ) async {
    try {
      await _journalsCollection.doc(docId).update({
        'title': title,
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Lỗi cập nhật nhật ký trên Firestore: $e');
      rethrow;
    }
  }

  // 1c. Xóa một bản ghi nhật ký trên Firestore
  Future<void> deleteJournalEntry(String docId) async {
    try {
      await _journalsCollection.doc(docId).delete();
    } catch (e) {
      print('Lỗi xóa nhật ký trên Firestore: $e');
      rethrow;
    }
  }

  // 2. Lấy Stream danh sách nhật ký chỉ thuộc về user đang đăng nhập
  Stream<List<QueryDocumentSnapshot>> getJournalEntriesStream() {
    final user = FirebaseAuth.instance.currentUser;
    return _journalsCollection
        .where('userId', isEqualTo: user?.uid)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs;
          // Sắp xếp giảm dần theo thời gian tạo (createdAt)
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>? ?? {};
            final bData = b.data() as Map<String, dynamic>? ?? {};

            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;

            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime); // b so với a để xếp giảm dần
          });
          return docs;
        });
  }

  // 3. Ghi nhận hoạt động hàng ngày (DAU - Daily Active User) của người dùng hiện tại
  Future<void> logDailyActivity() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      // Định dạng ngày: YYYY-MM-DD để làm mã định danh duy nhất trong ngày của user đó
      final dateStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final docId = "${user.uid}_$dateStr";

      await _activeUsersCollection.doc(docId).set({
        'userId': user.uid,
        'email': user.email,
        'date': dateStr,
        'dayOfWeek': now.weekday, // 1 (Thứ 2) -> 7 (Chủ Nhật)
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Firestore: Đã ghi nhận hoạt động DAU thành công cho $dateStr');
    } catch (e) {
      print('Lỗi ghi nhận hoạt động DAU: $e');
    }
  }

  // 4. Lấy Stream danh sách hoạt động của tất cả người dùng để vẽ biểu đồ hoạt động thực tế
  Stream<QuerySnapshot> getWeeklyActiveUsersStream() {
    return _activeUsersCollection.snapshots();
  }

  // 5. Collection ghi nhận lịch sử tìm kiếm từ khóa
  final CollectionReference _searchHistoryCollection = FirebaseFirestore
      .instance
      .collection('search_history');

  // Ghi nhận tìm kiếm của người dùng
  Future<void> logSearchQuery(String query) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final trimmedQuery = query.trim().toLowerCase();
      if (trimmedQuery.isEmpty) return;

      await _searchHistoryCollection.add({
        'query': trimmedQuery,
        'userId': user?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Firestore: Đã ghi nhận tìm kiếm "$trimmedQuery" thành công');
    } catch (e) {
      print('Lỗi ghi nhận tìm kiếm: $e');
    }
  }

  // Lấy Stream 5 từ khóa tìm kiếm nhiều nhất trong 7 ngày gần nhất (kèm fallback để tránh trống giao diện)
  Stream<List<Map<String, dynamic>>> getTopSearchedKeywordsStream() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _searchHistoryCollection
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo),
        )
        .snapshots()
        .map((snapshot) {
          final Map<String, int> counts = {};
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final q = data['query'] as String?;
            if (q != null && q.isNotEmpty) {
              final formatted = q
                  .split(' ')
                  .map((word) {
                    if (word.isEmpty) return '';
                    return '${word[0].toUpperCase()}${word.substring(1)}';
                  })
                  .join(' ');
              counts[formatted] = (counts[formatted] ?? 0) + 1;
            }
          }

          final sorted = counts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          if (sorted.isEmpty) {
            return const [];
          }

          return sorted
              .take(5)
              .map((entry) => {'keyword': entry.key, 'count': entry.value})
              .toList();
        });
  }

  // 6. Thêm thông báo mới nhận được vào Firestore
  Future<void> addNotification(String title, String body, {String? campaignId}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await _notificationsCollection.add({
        'title': title,
        'body': body,
        'userId': user.uid,
        'receivedAt': FieldValue.serverTimestamp(),
        'isRead': false, // Mặc định là chưa đọc
        if (campaignId != null) 'campaignId': campaignId,
      });
      print('Firestore: Đã lưu thông báo mới nhận được vào db.');
    } catch (e) {
      print('Lỗi lưu thông báo vào Firestore: $e');
    }
  }

  // Đánh dấu một thông báo đã đọc và gửi xác nhận tăng open count cho Campaign
  Future<void> markNotificationAsRead(String docId) async {
    try {
      final docRef = _notificationsCollection.doc(docId);
      final doc = await docRef.get();
      if (!doc.exists) return;
      
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final isAlreadyRead = data['isRead'] as bool? ?? false;

      // Chỉ xử lý nếu thông báo chưa đọc
      if (!isAlreadyRead) {
        await docRef.update({'isRead': true});
        print('Firestore: Đã đánh dấu thông báo $docId là ĐÃ ĐỌC.');

        final campaignId = data['campaignId'] as String?;
        if (campaignId != null && campaignId.isNotEmpty) {
          await FirebaseFirestore.instance.collection('campaigns').doc(campaignId).update({
            'openedCount': FieldValue.increment(1),
          });
          print('FCM Tracker: Đã tăng openedCount của campaign $campaignId sau khi user đọc.');
        }
      }
    } catch (e) {
      print('Lỗi đánh dấu đã đọc thông báo: $e');
    }
  }

  // 7. Lấy Stream danh sách thông báo của user hiện tại
  Stream<List<QueryDocumentSnapshot>> getNotificationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    return _notificationsCollection
        .where('userId', isEqualTo: user?.uid)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs;
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>? ?? {};
            final bData = b.data() as Map<String, dynamic>? ?? {};
            final aTime = aData['receivedAt'] as Timestamp?;
            final bTime = bData['receivedAt'] as Timestamp?;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });
          return docs;
        });
  }

  // 8. Xóa một thông báo
  Future<void> deleteNotification(String docId) async {
    try {
      await _notificationsCollection.doc(docId).delete();
    } catch (e) {
      print('Lỗi xóa thông báo: $e');
      rethrow;
    }
  }

  // 9. Xóa tất cả thông báo của user hiện tại
  Future<void> clearAllNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: user.uid)
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      print('Firestore: Đã xóa tất cả thông báo của user.');
    } catch (e) {
      print('Lỗi xóa tất cả thông báo: $e');
      rethrow;
    }
  }

  // 10. Lưu thông tin báo cáo PDF đã xuất
  final CollectionReference _pdfReportsCollection = FirebaseFirestore.instance
      .collection('pdf_reports');

  Future<void> savePdfReportInfo({
    required String topic,
    required String url,
    required String fileName,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await _pdfReportsCollection.add({
        'userId': user.uid,
        'topic': topic,
        'pdfUrl': url,
        'fileName': fileName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Firestore: Đã lưu thông tin báo cáo PDF vào Firestore.');
    } catch (e) {
      print('Lỗi lưu thông tin báo cáo PDF vào Firestore: $e');
      rethrow;
    }
  }

  // 11. Lấy Stream danh sách báo cáo PDF của user hiện tại
  Stream<List<QueryDocumentSnapshot>> getPdfReportsStream() {
    final user = FirebaseAuth.instance.currentUser;
    return _pdfReportsCollection
        .where('userId', isEqualTo: user?.uid)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs;
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>? ?? {};
            final bData = b.data() as Map<String, dynamic>? ?? {};
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });
          return docs;
        });
  }

  // 12. Xóa báo cáo PDF khỏi Firestore và Firebase Storage
  Future<void> deletePdfReport(String docId, String url) async {
    try {
      // 1. Xóa khỏi Firestore
      await _pdfReportsCollection.doc(docId).delete();
      print('Firestore: Đã xóa bản ghi báo cáo PDF khỏi Firestore.');

      // 2. Xóa khỏi Firebase Storage
      try {
        final storageRef = FirebaseStorage.instance.refFromURL(url);
        await storageRef.delete();
        print('Firebase Storage: Đã xóa file báo cáo PDF thành công.');
      } catch (storageError) {
        print('Lỗi khi xóa file trên Firebase Storage: $storageError');
      }
    } catch (e) {
      print('Lỗi xóa báo cáo PDF: $e');
      rethrow;
    }
  }

  // 13. Gửi báo cáo lỗi (Bug Report) từ người dùng lên Firestore
  final CollectionReference _bugsCollection = FirebaseFirestore.instance.collection('bugs');

  Future<void> reportBug({
    required String title,
    required String description,
    required String deviceInfo,
    String type = 'User Report',
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await _bugsCollection.add({
        'userId': user?.uid ?? 'anonymous',
        'userEmail': user?.email ?? 'anonymous',
        'title': title,
        'description': description,
        'deviceInfo': deviceInfo,
        'type': type,
        'status': 'Mới',
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Firestore: Đã lưu báo cáo bug thành công.');
    } catch (e) {
      print('Lỗi lưu báo cáo bug lên Firestore: $e');
      rethrow;
    }
  }
}
