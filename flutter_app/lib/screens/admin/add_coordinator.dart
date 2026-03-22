import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../layouts/admin_layout.dart';
import '../../widgets/app_widgets.dart';

class AddCoordinator extends StatefulWidget {
  const AddCoordinator({super.key});
  @override
  State<AddCoordinator> createState() => _AddCoordinatorState();
}

class _AddCoordinatorState extends State<AddCoordinator> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _zone;

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose(); _passwordCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.'), backgroundColor: Colors.orange));
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters.'), backgroundColor: Colors.orange));
      return;
    }
    try {
      await context.read<DataProvider>().addCoordinator({'name': _nameCtrl.text, 'email': _emailCtrl.text, 'password': _passwordCtrl.text, 'phone': _phoneCtrl.text, 'zone': _zone});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coordinator added!'), backgroundColor: Colors.green));
        context.go('/admin');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(child: Column(children: [
      const AppHeader(title: 'Add Coordinator', backTo: '/admin'),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        AppFormField(label: 'Full Name', child: TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Enter coordinator name'))),
        const SizedBox(height: 16),
        AppFormField(label: 'Email', child: TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'email@example.com'))),
        const SizedBox(height: 16),
        AppFormField(label: 'Password', child: TextField(controller: _passwordCtrl, obscureText: true, decoration: const InputDecoration(hintText: 'Minimum 6 characters'))),
        const SizedBox(height: 16),
        AppFormField(label: 'Phone', child: TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: '+91 98765 43210'))),
        const SizedBox(height: 16),
        AppFormField(label: 'Zone', child: DropdownButtonFormField<String>(
          value: _zone ?? (context.read<DataProvider>().zones.isNotEmpty ? context.read<DataProvider>().zones.first['name'] : null),
          items: context.read<DataProvider>().zones.map((z) => DropdownMenuItem(value: z['name'].toString(), child: Text(z['name']))).toList(),
          onChanged: (v) => setState(() => _zone = v!),
          decoration: const InputDecoration(hintText: 'Select Zone'),
        )),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(onPressed: _submit, icon: const Icon(Icons.person_add), label: const Text('Add Coordinator'))),
        const SizedBox(height: 100),
      ]))),
    ]));
  }
}
