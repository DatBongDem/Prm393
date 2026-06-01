import 'package:flutter/material.dart';

class GradeHeaderCard extends StatelessWidget {
  const GradeHeaderCard({
    super.key,
    required this.onImportPressed,
    required this.onCreatePressed,
    required this.onExportPressed,
    required this.classOptions,
    required this.selectedClass,
    required this.onClassChanged,
    required this.isImporting,
  });

  final VoidCallback onImportPressed;
  final VoidCallback? onCreatePressed;
  final VoidCallback? onExportPressed;
  final List<String> classOptions;
  final String? selectedClass;
  final ValueChanged<String?> onClassChanged;
  final bool isImporting;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 900;
          final title = Row(
            children: [
              const Icon(Icons.assessment_rounded, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Student Grade Management",
                  style: TextStyle(
                    fontSize: isCompact ? 22 : 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
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
              FilledButton.icon(
                onPressed: onExportPressed,
                style: FilledButton.styleFrom(backgroundColor: Colors.green),
                icon: const Icon(Icons.download_outlined),
                label: const Text("Export File"),
              ),
              FilledButton.icon(
                onPressed: onCreatePressed,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text("Add Student"),
              ),
            ],
          );

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (isCompact) ...[
                  title,
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerLeft, child: actions),
                ] else
                  Row(
                    children: [
                      Expanded(child: title),
                      const SizedBox(width: 12),
                      actions,
                    ],
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedClass,
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
              ],
            ),
          );
        },
      ),
    );
  }
}
