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
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 850),
            child: Column(
              children: [
                _header(context),
                Expanded(child: _content(s)),
                _actionButtons(context),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= HEADER =================
  static Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      alignment: Alignment.centerLeft,
      child: const Text(
        "Chi Tiết Sinh Viên",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ================= CONTENT =================
  static Widget _content(StudentGrade s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section("Thông Tin Cá Nhân", [
            _infoRow("Class", s.className, "Roll Number", s.rollNumber),
            _infoRow("Full Name", s.fullName, "Email", s.email.isEmpty ? "-" : s.email),
            _infoRow("Member Code", s.memberCode.isEmpty ? "-" : s.memberCode, "Exam Date", s.examDate.isEmpty ? "-" : s.examDate),
          ]),
          const SizedBox(height: 16),
          _section("Kỳ Thi Cuối Kỳ", [
            _twoColumnGrid([
              _scoreRowSingle("Final Exam", s.finalExam),
              _scoreRowSingle("Final Exam Resit", s.finalResit),
              _singleFieldRow("Final Exam Comment", s.finalComment),
              _singleFieldRow("Final Resit Comment", "-"), // Final Resit Comment field doesn't exist in FE model yet
            ]),
          ]),
          const SizedBox(height: 16),
          _section("Kỳ Thi Thực Hành", [
            _twoColumnGrid([
              _scoreRowSingle("Practical Exam", s.practical),
              _scoreRowSingle("Practical Exam Resit", s.practicalResit),
              _singleFieldRow("Practical Exam Comment", "-"),
              _singleFieldRow("Practical Exam Resit Comment", "-"),
            ]),
          ]),
          const SizedBox(height: 16),
          _section("Kiểm Tra Tiến Độ", [
            _twoColumnGrid([
              _scoreRow(
                "Progress Test 1",
                s.pt1,
                "Progress Test 1 Comment",
                s.pt1Comment,
              ),
              _scoreRow(
                "Progress Test 2",
                s.pt2,
                "Progress Test 2 Comment",
                s.pt2Comment,
              ),
              _scoreRow(
                "Progress Test 3",
                s.pt3,
                "Progress Test 3 Comment",
                s.pt3Comment,
              ),
              const SizedBox(),
            ]),
          ]),
          const SizedBox(height: 16),
          _section("Dự Án", [
            _twoColumnGrid([
              _scoreRow(
                "Project",
                s.project,
                "Project Comment",
                s.projectComment,
              ),
              const SizedBox(),
            ]),
          ]),
          const SizedBox(height: 16),
          _divider(),
          const SizedBox(height: 16),
          _section("Kết Quả Cuối Cùng", [
            _twoColumnGrid([
              _scoreRowSingle("Total", s.total),
              _singleFieldRow("Result", s.result),
              _singleFieldRow("Comment", s.comment),
              const SizedBox(),
            ]),
          ]),
        ],
      ),
    );
  }

  // ================= SECTION BUILDER =================
  static Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  static Widget _infoRow(
    String label1,
    String value1,
    String label2,
    String value2,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label1,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value1,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label2,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value2,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _scoreRow(
    String scoreLabel,
    double scoreValue,
    String commentLabel,
    String commentValue,
  ) {
    final hasComment = commentLabel.isNotEmpty && commentValue.isNotEmpty;

    if (hasComment) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scoreLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scoreValue == 0 ? "-" : scoreValue.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        commentLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        commentValue.isEmpty ? "-" : commentValue,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // If no comment label, just show the score
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scoreLabel,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              scoreValue == 0 ? "-" : scoreValue.toStringAsFixed(1),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }
  }

  static Widget _scoreRowSingle(String scoreLabel, double scoreValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            scoreLabel,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            scoreValue == 0 ? "-" : scoreValue.toStringAsFixed(1),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  static Widget _singleFieldRow(String label, String value) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  static Widget _twoColumnGrid(List<Widget> children) {
    return Column(
      children: [
        for (int i = 0; i < children.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: children[i]),
                if (i + 1 < children.length) ...[
                  const SizedBox(width: 16),
                  Expanded(child: children[i + 1]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  static Widget _divider() {
    return Container(height: 1, color: Colors.grey.shade300);
  }

  static String _formatResult(String result) {
    return result.isNotEmpty ? result : "-";
  }

  // ================= ACTION BUTTONS =================
  static Widget _actionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Đóng",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
