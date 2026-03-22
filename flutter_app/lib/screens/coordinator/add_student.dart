import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../layouts/coordinator_layout.dart';
import '../../widgets/app_widgets.dart';

class CoordAddStudent extends StatefulWidget {
  const CoordAddStudent({super.key});
  @override
  State<CoordAddStudent> createState() => _CoordAddStudentState();
}

class _CoordAddStudentState extends State<CoordAddStudent> {
  final _nameCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  String _class = 'Class 1';
  String _centre = 'East Park Centre';

  @override
  void dispose() { _nameCtrl.dispose(); _rollCtrl.dispose(); _contactCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _rollCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill required fields.'), backgroundColor: Colors.orange));
      return;
    }
    try {
      final auth = context.read<AppAuthProvider>();
      await context.read<DataProvider>().addStudent({'name': _nameCtrl.text, 'roll': _rollCtrl.text, 'contact': _contactCtrl.text, 'class': _class, 'centre': _centre, 'zone': auth.user?['zone'] ?? ''});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student added!'), backgroundColor: Colors.green));
        context.go('/coordinator/manage');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CoordinatorLayout(
      child: Column(children: [
        const AppHeader(title: 'Add Student', backTo: '/coordinator/manage'),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
          AppFormField(label: 'Full Name', child: TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Enter student name'))),
          const SizedBox(height: 16),
          AppFormField(label: 'Roll Number', child: TextField(controller: _rollCtrl, decoration: const InputDecoration(hintText: 'e.g. STU-009'))),
          const SizedBox(height: 16),
          AppFormField(label: 'Class', child: DropdownButtonFormField<String>(value: _class, items: ['Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => _class = v!), decoration: const InputDecoration())),
          const SizedBox(height: 16),
          AppFormField(label: 'Contact', child: TextField(controller: _contactCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: '+91 98765 43210'))),
          const SizedBox(height: 16),
          AppFormField(label: 'Centre', child: DropdownButtonFormField<String>(value: _centre, items: ['East Park Centre', 'North Valley', 'Urban Hub', 'City Square', 'Green Meadows'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => _centre = v!), decoration: const InputDecoration())),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(onPressed: _submit, icon: const Icon(Icons.person_add), label: const Text('Add Student'))),
          const SizedBox(height: 100),
        ]))),
      ]),
    );
  }
}
