import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../layouts/teacher_layout.dart';
import '../../widgets/app_widgets.dart';


class AddStudent extends StatefulWidget {
  const AddStudent({super.key});

  @override
  State<AddStudent> createState() => _AddStudentState();
}

class _AddStudentState extends State<AddStudent> {
  final _nameCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  String _class = 'Primary';
  String _centre = '';

  @override
  void initState() {
    super.initState();
    final auth = context.read<AppAuthProvider>();
    _centre = auth.user?['centre'] ?? 'Unknown Centre';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rollCtrl.dispose();
    _contactCtrl.dispose();
    _aadhaarCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _rollCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all required fields.'), backgroundColor: Colors.orange));
      return;
    }
    try {
      final auth = context.read<AppAuthProvider>();
      await context.read<DataProvider>().addStudent({
        'name': _nameCtrl.text,
        'roll': _rollCtrl.text,
        'contact': _contactCtrl.text,
        'aadhaar': _aadhaarCtrl.text,
        'class': _class,
        'centre': _centre,
        'zone': auth.user?['zone'] ?? '',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student added successfully!'), backgroundColor: Colors.green));
        context.go('/teacher/students');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {

    return TeacherLayout(
      child: Column(
        children: [
          const AppHeader(title: 'Add Student', backTo: '/teacher/students'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  AppFormField(label: 'Full Name', child: TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Enter student name'))),
                  const SizedBox(height: 16),
                  AppFormField(label: 'Roll Number', child: TextField(controller: _rollCtrl, decoration: const InputDecoration(hintText: 'e.g. STU-009'))),
                  const SizedBox(height: 16),
                  AppFormField(label: 'Class', child: DropdownButtonFormField<String>(
                    value: _class,
                    items: ['Primary', 'Secondary', 'Support Class'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _class = v!),
                    decoration: const InputDecoration(),
                  )),
                  const SizedBox(height: 16),
                  AppFormField(label: 'Contact Number', child: TextField(controller: _contactCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: '+91 98765 43210'))),
                  const SizedBox(height: 16),
                  AppFormField(label: 'Aadhaar Number (Encrypted)', child: TextField(controller: _aadhaarCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '12-digit number'))),
                  const SizedBox(height: 16),
                  if (context.read<AppAuthProvider>().role != 'teacher')
                    AppFormField(label: 'Centre', child: DropdownButtonFormField<String>(
                      value: _centre,
                      items: ['East Park Centre', 'North Valley', 'Urban Hub', 'City Square', 'Green Meadows'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _centre = v!),
                      decoration: const InputDecoration(),
                    ))
                  else
                    AppFormField(label: 'Centre', child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155).withValues(alpha: 0.3) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Text(_centre, style: const TextStyle(fontWeight: FontWeight.w600)),
                    )),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add Student'),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
