import 'package:flutter/material.dart';

class GradeHeaderCard extends StatelessWidget {
  const GradeHeaderCard({
    super.key,
    required this.showTable,
    required this.onToggle,
    required this.onImportPressed,
    required this.onExportPressed,
    required this.classOptions,
    required this.selectedClass,
    required this.onClassChanged,
  });
  final bool showTable;
  final ValueChanged<bool> onToggle;
  final VoidCallback onImportPressed;
  final VoidCallback? onExportPressed;
  final List<String> classOptions;
  final String? selectedClass;
  final ValueChanged<String?> onClassChanged;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.assessment_rounded, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Student Grade Management",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                ),

                ElevatedButton.icon(
                  onPressed: onImportPressed,
                  icon: const Icon(Icons.upload_outlined),
                  label: const Text("Import File"),
                ),
                const SizedBox(width: 8),

                FilledButton.icon(
                  onPressed: onExportPressed,
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text("Export File"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return DropdownMenu<String>(
                        // Cho ô chọn rộng đúng bằng phần Expanded
                        width: constraints.maxWidth,

                        // Giá trị đang chọn
                        initialSelection: selectedClass,

                        label: const Text('Choose Class'),
                        hintText: 'Select a class',

                        // Giới hạn chiều cao menu để không che cả màn hình
                        menuHeight: 220,

                        // Ép menu mở từ cạnh dưới của ô chọn
                        menuStyle: const MenuStyle(
                          alignment: AlignmentDirectional.bottomStart,
                        ),

                        // Dịch xuống 1 chút cho dễ nhìn (optional)
                        alignmentOffset: const Offset(0, 4),

                        requestFocusOnTap: false,
                        onSelected: onClassChanged,

                        dropdownMenuEntries: classOptions
                            .map(
                              (e) =>
                                  DropdownMenuEntry<String>(value: e, label: e),
                            )
                            .toList(),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                //đây chỉ là nút ví dụ để mở bảng thôi về sau là khi import thành công 1 file sẽ tự động mở bảng và hiển thị đúng dữ liệu
                Row(
                  children: [
                    const Text("Demo Table"),
                    Switch(value: showTable, onChanged: onToggle),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
