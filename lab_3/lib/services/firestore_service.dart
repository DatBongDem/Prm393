import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  // Tham chiếu đến các collection trên Cloud Firestore
  final CollectionReference _journalsCollection =
      FirebaseFirestore.instance.collection('journals');
      
  final CollectionReference _activeUsersCollection =
      FirebaseFirestore.instance.collection('active_users');

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
  Future<void> updateJournalEntry(String docId, String title, String content) async {
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
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
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
}
