import 'package:flutter/material.dart';

class GradeHeaderCard extends StatelessWidget {
  const GradeHeaderCard({
    super.key,
    required this.onImportPressed,
    required this.onExportPressed,
    required this.classOptions,
    required this.selectedClass,
    required this.onClassChanged,
    required this.isImporting,
  });
  final VoidCallback onImportPressed;
  final VoidCallback? onExportPressed;
  final List<String> classOptions;
  final String? selectedClass;
  final ValueChanged<String?> onClassChanged;
  final bool isImporting;
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
                  onPressed: isImporting ? null : onImportPressed,
                  icon: isImporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_outlined),
                  label: Text(isImporting ? 'Uploading...' : 'Import File'),
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
                  child: DropdownButtonFormField<String>(
                    value: selectedClass,
                    menuMaxHeight: 260,
                    decoration: const InputDecoration(
                      labelText: 'Choose Class',
                      hintText: 'Import a file first',
                    ),
                    items: classOptions
                        .map(
                          (className) => DropdownMenuItem<String>(
                            value: className,
                            child: Text(className),
                          ),
                        )
                        .toList(),
                    onChanged: classOptions.isEmpty ? null : onClassChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
