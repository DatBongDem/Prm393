import 'package:flutter/material.dart';
import 'package:fe/src/feature/grade_ui/domain/grade_models.dart';

class GradeDetailDialog {
  static void show(BuildContext context, StudentGrade s) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(context, s),
                  const Divider(height: 24),
                  Expanded(child: _content(s)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ================= HEADER =================
  static Widget _header(BuildContext context, StudentGrade s) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.fullName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(s.rollNumber, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  // ================= CONTENT =================
  static Widget _content(StudentGrade s) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _scoreTile("Final", s.finalExam),
          _scoreTile("Final Resit", s.finalResit),
          _scoreTile("Practical", s.practical),

          const SizedBox(height: 8),

          _commentTile("Final Comment", s.finalComment),

          const Divider(),

          _scoreTile("PT1", s.pt1),
          _commentTile("PT1 Comment", s.pt1Comment),

          _scoreTile("PT2", s.pt2),
          _commentTile("PT2 Comment", s.pt2Comment),

          _scoreTile("PT3", s.pt3),
          _commentTile("PT3 Comment", s.pt3Comment),

          const Divider(),

          _scoreTile("Project", s.project),
          _commentTile("Project Comment", s.projectComment),

          const Divider(),

          _scoreTile("Total", s.total),

          const SizedBox(height: 10),

          _resultBox(s),
        ],
      ),
    );
  }

  // ================= UI HELPERS =================
  static Widget _scoreTile(String label, double value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static Widget _commentTile(String label, String value) {
    if (value.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Expanded(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  static Widget _resultBox(StudentGrade s) {
    final isPass = s.isPass;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPass ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Result", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            s.result,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPass ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
