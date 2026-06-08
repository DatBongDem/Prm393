import 'package:fe/src/feature/grade_ui/domain/grade_models.dart';
import 'package:flutter/material.dart';

class GradeFormDialog extends StatefulWidget {
  const GradeFormDialog({
    super.key,
    this.student,
    required this.className,
  });

  final StudentGrade? student;
  final String className;

  static Future<StudentGradeRequest?> show(
    BuildContext context, {
    StudentGrade? student,
    required String className,
  }) {
    return showDialog<StudentGradeRequest>(
      context: context,
      builder: (context) => GradeFormDialog(
        student: student,
        className: className,
      ),
    );
  }

  @override
  State<GradeFormDialog> createState() => _GradeFormDialogState();
}

class _GradeFormDialogState extends State<GradeFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _rollNumberController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _memberCodeController;

  late final TextEditingController _finalExamController;
  late final TextEditingController _pt1Controller;
  late final TextEditingController _pt2Controller;
  late final TextEditingController _pt3Controller;
  late final TextEditingController _practicalController;
  late final TextEditingController _projectController;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _rollNumberController = TextEditingController(text: s?.rollNumber ?? '');
    _fullNameController = TextEditingController(text: s?.fullName ?? '');
    _emailController = TextEditingController(text: s?.email ?? '');
    _memberCodeController = TextEditingController(text: s?.memberCode ?? '');

    _finalExamController = TextEditingController(text: s?.finalExam.toString() ?? '0');
    _pt1Controller = TextEditingController(text: s?.pt1.toString() ?? '0');
    _pt2Controller = TextEditingController(text: s?.pt2.toString() ?? '0');
    _pt3Controller = TextEditingController(text: s?.pt3.toString() ?? '0');
    _practicalController = TextEditingController(text: s?.practical.toString() ?? '0');
    _projectController = TextEditingController(text: s?.project.toString() ?? '0');
  }

  @override
  void dispose() {
    _rollNumberController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _memberCodeController.dispose();
    _finalExamController.dispose();
    _pt1Controller.dispose();
    _pt2Controller.dispose();
    _pt3Controller.dispose();
    _practicalController.dispose();
    _projectController.dispose();
    super.dispose();
  }

  double _parse(String val) => double.tryParse(val) ?? 0;

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.student != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Student' : 'Add New Student'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(
                  _rollNumberController,
                  'Roll Number',
                  enabled: !isEdit,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please enter roll number';
                    if (val.length < 3) return 'Roll number is too short';
                    return null;
                  },
                ),
                _buildField(_fullNameController, 'Full Name'),
                _buildField(
                  _emailController,
                  'Email',
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please enter email';
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(val)) return 'Invalid email format';
                    return null;
                  },
                ),
                _buildField(_memberCodeController, 'Member Code'),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        _finalExamController,
                        'Final Exam',
                        isNumber: true,
                        validator: _scoreValidator,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildField(
                        _practicalController,
                        'Practical',
                        isNumber: true,
                        validator: _scoreValidator,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        _pt1Controller,
                        'PT 1',
                        isNumber: true,
                        validator: _scoreValidator,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildField(
                        _pt2Controller,
                        'PT 2',
                        isNumber: true,
                        validator: _scoreValidator,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildField(
                        _pt3Controller,
                        'PT 3',
                        isNumber: true,
                        validator: _scoreValidator,
                      ),
                    ),
                  ],
                ),
                _buildField(
                  _projectController,
                  'Project',
                  isNumber: true,
                  validator: _scoreValidator,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final request = StudentGradeRequest(
                className: widget.className,
                rollNumber: _rollNumberController.text.trim(),
                fullName: _fullNameController.text.trim(),
                email: _emailController.text.trim(),
                memberCode: _memberCodeController.text.trim(),
                finalExam: _parse(_finalExamController.text),
                practicalExam: _parse(_practicalController.text),
                pt1: _parse(_pt1Controller.text),
                pt2: _parse(_pt2Controller.text),
                pt3: _parse(_pt3Controller.text),
                project: _parse(_projectController.text),
              );
              Navigator.pop(context, request);
            }
          },
          child: Text(isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  String? _scoreValidator(String? val) {
    if (val == null || val.isEmpty) return 'Enter score';
    final n = double.tryParse(val);
    if (n == null) return 'Must be a number';
    if (n < 0 || n > 10) return 'Score must be 0-10';
    return null;
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        validator: validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              return null;
            },
      ),
    );
  }
}
